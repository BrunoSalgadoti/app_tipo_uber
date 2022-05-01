import 'package:flutter/material.dart';
import 'package:uber/model/RouteGenerator.dart';
import 'package:uber/telas/Home.dart';
import 'package:firebase_core/firebase_core.dart';

final  ThemeData temaPadrao = ThemeData(
  primaryColor: Color(0xff37474f),
    appBarTheme:AppBarTheme (
      backgroundColor: Color(0xff546e7a),
    ));

void main() async {

  //Inicializar banco de dados firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(  MaterialApp(

    title: "Uber APP",

    home: Home(),

    theme: temaPadrao,

//-----------------------------Rotas Nomeadas ----------------------------------
    initialRoute: "/",

    onGenerateRoute: RouteGenerator.generateRoute,
//------------------------------------------------------------------------------
      debugShowCheckedModeBanner: false,
  )
  );
}
