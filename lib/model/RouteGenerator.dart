import 'package:flutter/material.dart';
import 'package:uber/telas/Cadastro.dart';
import 'package:uber/telas/Corrida.dart';
import 'package:uber/telas/Home.dart';
import 'package:uber/main.dart';
import 'package:uber/telas/PainelMotorista.dart';
import 'package:uber/telas/PainelPassageiro.dart';

class RouteGenerator{

  static const String ROTA_ROOT = "/";
  static const String ROTA_CADASTRO = "/cadastro";
  static const String ROTA_PAINELMOTORISTA = "/painel-motorista";
  static const String ROTA_PAINELPASSAGEIRO = "/painel-passageiro";
  static const String ROTA_CORRIDA = "/corrida";

  static Route<dynamic>? generateRoute( RouteSettings settings ) {

    dynamic args = settings.arguments;

    switch ( settings.name ){
      case ROTA_ROOT:
        return MaterialPageRoute(
            builder: (_) => Home()
        );
      case ROTA_CADASTRO:
        return MaterialPageRoute(
            builder: (_) => Cadastro()
        );
      case ROTA_PAINELMOTORISTA:
        return MaterialPageRoute(
            builder: (_) => PainelMotorista()
        );
      case ROTA_PAINELPASSAGEIRO:
        return MaterialPageRoute(
            builder: (_) => PainelPassageiro()
        );
      case ROTA_CORRIDA:
        return MaterialPageRoute(
            builder: (_) => Corrida(
                args
            )
        );
      default:
        _erroRota();

    }
  }

  static Route<dynamic> _erroRota(){
    return MaterialPageRoute(
        builder: (_) {
          return Scaffold(

            appBar: AppBar(title: Text("Tela não encontrada"),),

            body: Center(
              child: Text("Tela não encontrada"),
            ) ,
          );
        }
    );
  }
}

