import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber/model/Usuario.dart';

class UsuarioFirebase {

  static Future<dynamic> getUsuarioAtual (  ) async {

    FirebaseAuth auth = FirebaseAuth.instance;
    return await auth.currentUser?.uid;
  }

  static Future<Usuario> getDadosUsuarioLogado ( ) async {

    dynamic firebaseUser = await getUsuarioAtual();
    dynamic idUsuario = firebaseUser;

    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentSnapshot snapshot = await db.collection("usuarios")
        .doc( idUsuario )
        .get();

    dynamic dados = snapshot.data();
    String tipoUsuario = dados["tipoUsuario"];
    String email = dados["email"];
    String nome = dados["nome"];

    Usuario usuario = Usuario();
    usuario.idUsuario = idUsuario;
    usuario.tipoUsuario = tipoUsuario;
    usuario.email = email;
    usuario.nome = nome;

    return usuario;

  }

  static atualizarDadosLocalizacao (dynamic idRequisicao, dynamic lat, dynamic lon, String tipo ) async {

    FirebaseFirestore db = FirebaseFirestore.instance;

    Usuario usuario = await getDadosUsuarioLogado();
    usuario.latitude = lat;
    usuario.longitude = lon;

    db.collection("requisicoes")
        .doc( idRequisicao )
        .update({
      "${tipo}" : usuario.toMap()
    });


  }

}