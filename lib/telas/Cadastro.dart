import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uber/model/RouteGenerator.dart';
import 'package:uber/model/Usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber/telas/PainelMotorista.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({Key? key}) : super(key: key);

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {

  TextEditingController _controllerNome = TextEditingController();
  TextEditingController _controllerEmail = TextEditingController();
  TextEditingController _controllerSenha = TextEditingController();

  bool _tipoUsuario = false;
  String _mensagemErro = "";

  _validarCampos(){

    //recuperar dados dos campos
    String nome = _controllerNome.text;
    String email = _controllerEmail.text;
    String senha = _controllerSenha.text;

    //validar campos
    if ( nome.isNotEmpty ){

      if (email.isNotEmpty && email.contains("@")){

        if( senha.isNotEmpty && senha.length >= 7 ){

          Usuario usuario = Usuario();
          usuario.nome = nome;
          usuario.email = email;
          usuario.senha = senha;
          usuario.tipoUsuario = usuario.verificaTipoUsuario(_tipoUsuario);

          _cadastrarUsuario( usuario );

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
    }else{
      setState(() {
        _mensagemErro = "Preencha o Nome";
      });
    }
  }

 Future<dynamic> _cadastrarUsuario(Usuario usuario) async {

    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = await FirebaseFirestore.instance;

    await auth.createUserWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha
    ).then(( dynamic firebaseUser) {

      dynamic uid = auth.currentUser?.uid;

      db.collection("usuarios")
          .doc( uid.toString())
          .set( usuario.toMap());

      //redirecionar para o painel de acordo com o tipoUsuario
      switch( usuario.tipoUsuario){

        case "motorista" :
          Navigator.pushNamedAndRemoveUntil(
              context,
              RouteGenerator.ROTA_PAINELMOTORISTA,
                  (_) => false
          );
          break;
        case "passageiro" :
          Navigator.pushNamedAndRemoveUntil(
              context,
              RouteGenerator.ROTA_PAINELPASSAGEIRO,
                  (_) => false
          );
          break;
      }
    }).catchError((error){
      _mensagemErro = "Erro ao autenticar o usuário, \n "
          "verifique os campos e tente novamente";
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        backgroundColor: Color(0xff535384),
        title: Text("Cadastro",
          style: TextStyle(
            fontSize: 20,
          ),),
      ),

      body: Container(
        padding: EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,


            children: <Widget> [

              Padding(padding: EdgeInsets.only(top: 15, bottom: 10),

                child: TextField(
                  controller: _controllerNome,
                  keyboardType: TextInputType.text,
                  autofocus: true,
                  style: TextStyle(fontSize: 20),

                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Nome",
                      labelText: "Nome",
                      labelStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                      )),
                ),
              ),

              Padding(padding: EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _controllerEmail,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 20),

                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "Email",
                      filled: true,
                      fillColor: Colors.white,
                      labelText: "Email",
                      labelStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                      )),
                ),
              ),

              Padding(padding: EdgeInsets.only(bottom: 10),
                child:  TextField(
                  controller: _controllerSenha,
                  keyboardType: TextInputType.text,
                  obscureText: true,
                  style: TextStyle(fontSize: 20),

                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Senha",
                      labelText: "Senha",
                      labelStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                      )),
                ),
              ),

              // opção Passageiro Motorista
              Padding(padding: EdgeInsets.only(bottom: 10),

                child: Row(
                  children: <Widget> [

                    Text("Passageiros"),

                    Switch(// botão de escolhas
                        value: _tipoUsuario,
                        onChanged: (bool valor){
                          setState(() {
                            _tipoUsuario = valor;
                          });
                        }
                    ),

                    Text("Motorista")

                  ],),
              ),

              ElevatedButton(
                onPressed: (){
                  _validarCampos();

                },
                child: Text("Cadastrar",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                  ),),
                style: ElevatedButton.styleFrom(
                    primary: Color(0xff1ebbd8),
                    shadowColor: Colors.black54,
                    elevation: 15,
                    padding:  EdgeInsets.fromLTRB(18, 16, 18, 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    )),
              ),

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

            ],),

        ),

      ),
    );
  }
}
