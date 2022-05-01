import 'dart:ffi';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:uber/model/RouteGenerator.dart';
import 'package:uber/model/Usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  TextEditingController _controllerEmail = TextEditingController();
  TextEditingController _controllerSenha = TextEditingController();

  String _mensagemErro = "";
  bool _carregando = false;

  _validarCampos(){

    //recuperar dados dos campos
    String email = _controllerEmail.text;
    String senha = _controllerSenha.text;

    //validar campos
    if (email.isNotEmpty && email.contains("@")){

      if( senha.isNotEmpty && senha.length >= 7 ){

        Usuario usuario = Usuario();
        usuario.email = email;
        usuario.senha = senha;

        _logarUsuario ( usuario );

      }else{
        setState(() {
          _mensagemErro = "Senha deve conter no mínimo 7 caracteres";
        });
      }
    }else {
      setState(() {
        _mensagemErro = "Preencha com um E-mail Válido";
      });
    }
  }

  Future<dynamic> _logarUsuario( Usuario usuario ) async {

    setState(() {
      _carregando = true;
    });

    FirebaseAuth auth = FirebaseAuth.instance;

    await auth.signInWithEmailAndPassword(
      email: usuario.email,
      password: usuario.senha,
    ).then((firebaseUser) {

      _redirecionarPainelPorUsuario(firebaseUser.user!.uid);

    }).catchError((error){
      _mensagemErro = "Erro ao autenticar o usuário, \n "
          "verifique E-mail e Senha";
    });
  }

  Future<dynamic> _redirecionarPainelPorUsuario ( dynamic idUsuario) async {

    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentSnapshot snapshot = await db.collection("usuarios")
        .doc( idUsuario )
        .get();

    dynamic dados = snapshot.data();
    String tipoUsuario = dados!["tipoUsuario"];

    setState(() {
      _carregando = false;
    });

    switch ( tipoUsuario ){
      case "motorista":
        Navigator.pushReplacementNamed(
            context,
            RouteGenerator.ROTA_PAINELMOTORISTA);
        break;
      case "passageiro" :
        Navigator.pushReplacementNamed(
            context,
            RouteGenerator.ROTA_PAINELPASSAGEIRO);
        break;
    }
  }

  Future<dynamic> _verificarUsuarioLogado() async {

    FirebaseAuth auth = FirebaseAuth.instance;

    User? usuarioLogado = await auth.currentUser;
    if( usuarioLogado != null ){
      String idUsuario = usuarioLogado.uid;
      _redirecionarPainelPorUsuario( idUsuario );
    }
  }

  @override
  void initState() {
    super.initState();
    _verificarUsuarioLogado();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

        body: Container(

          //background de imagem de fundo do container
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("imagens/fundo.png"),
                    fit: BoxFit.cover
                )
            ),
            padding: EdgeInsets.fromLTRB(16, 35, 16, 16),

            child: Center(

              child: SingleChildScrollView(

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: <Widget> [
                    Padding(
                      padding: EdgeInsets.only(bottom: 32),

                      child: Image.asset(
                        "imagens/logo.png",
                        width: 200,
                        height: 150,
                      ),
                    ),

                    TextField(
                        controller: _controllerEmail,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle( fontSize: 22),
                        decoration: InputDecoration(
                            filled: true, //MOSTRA O FUNDO DO TEXTFILD
                            fillColor: Colors.white70,
                            contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                            hintText: "E-mail",
                            labelText: "E-mail",
                            labelStyle: TextStyle(
                                color: Colors.yellow,
                                fontSize: 22,
                                fontWeight: FontWeight.bold
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10))
                        )),

                    Padding(padding: EdgeInsets.only(top: 12, bottom: 8),),

                    TextField(
                        controller: _controllerSenha,
                        obscureText: true,
                        keyboardType: TextInputType.text,
                        style: TextStyle( fontSize: 22),
                        decoration: InputDecoration(
                            filled: true, //MOSTRA O FUNDO DO TEXTFILD
                            fillColor: Colors.white70,
                            contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                            hintText: "Senha",
                            labelText: "Senha",
                            labelStyle: TextStyle(
                                color: Colors.yellow,
                                fontSize: 22,
                                fontWeight: FontWeight.bold
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10))
                        )),

                    Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 10),

                      child: ElevatedButton(
                        onPressed: (){
                          _validarCampos();

                        },
                        child: const Text(
                          "Entrar",
                          style: TextStyle(
                            fontSize: 22,
                            decorationColor: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                            primary: Color(0xff1ebbd8), //Cor do Botão
                            shadowColor: Colors.black,
                            elevation: 15,
                            padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)
                            )
                        ),),

                    ),

                    Center(
                        child: GestureDetector(

                          child: Text(
                            "Não tem conta? Cadastre-se!",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                            ),),
                          onTap: (){
                            Navigator.pushNamed(
                                context,
                                RouteGenerator.ROTA_CADASTRO);
                          },
                        )),

                    //indicador de carregamento
                    _carregando ? Center(
                      child: CircularProgressIndicator(backgroundColor: Colors.white),)
                        : Container(),

                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          _mensagemErro,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red
                          ),),),

                    )

                  ],
                ),),
            )
        )
    );

  }
}