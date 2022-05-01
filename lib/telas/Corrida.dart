import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber/model/Marcador.dart';
import 'package:uber/model/RouteGenerator.dart';
import 'package:uber/util/StatusRequisicao.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uber/util/UsuarioFirebase.dart';
import 'dart:core';
import 'package:intl/intl.dart';

class Corrida extends StatefulWidget {

  dynamic idRequisicao;
  Corrida( this.idRequisicao);

  @override
  State<Corrida> createState() => _CorridaState();
}

class _CorridaState extends State<Corrida> {

  Completer<GoogleMapController> _controller = Completer();

  //posição inicial camera PADRÃO
  CameraPosition _posicaoCamera = CameraPosition(
    target: LatLng(-23.563999, -46.653256),);

  Set<Marker> _marcadores = {};
  dynamic _dadosRequisicao;
  dynamic _idRequisicao;
  Position? _localMotorista;
  dynamic _statusRequisicao = StatusRequisicao.AGUARDANDO;

  //Controles para exibição na tela
  String _textoBotao = "Aceitar Corrida";
  Color _corBotao = Color(0xff1ebbd8);
  late Function? _funcaoBotao;
  String _mensagemStatus = "";

//--Metodos de auterações de visualização painel Motorista (ao clicar no botão)--
  _alterarBotaoPrincipal (String texto, Color cor, Function funcao) {
    setState(() {
      _textoBotao = texto;
      _corBotao = cor;
      _funcaoBotao = funcao;
    });
  }

  _onMapCreated( GoogleMapController controller ){
    _controller.complete( controller );
  }

  Future<dynamic> _adicionarListenerLocalizacao() async {

    final LocationSettings locationOptions = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );
    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
        locationSettings: locationOptions).listen(
            (Position? position) {

          if ( position != null ){

            if( _idRequisicao != null && _idRequisicao != 0){

              if( _statusRequisicao != StatusRequisicao.AGUARDANDO ) {

                //Atualizar local motorista
                UsuarioFirebase.atualizarDadosLocalizacao(
                    _idRequisicao,
                    position.latitude,
                    position.longitude,
                    "motorista"
                );
              }else {//Aguardando
                setState(() {
                  _localMotorista = position;
                });
                _statusAguardando();
              }
            }
          }
        });
  }

  Future<dynamic> _recuperarUltimaLocalizacaoConhecida() async {

    Position? position = await Geolocator
        .getLastKnownPosition();

    if ( position != null){

      //Atualizar localização em tempo real Motorista



    }
  }

  Future<dynamic> _movimentarCamera( CameraPosition cameraPosition) async {

    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
            cameraPosition));
  }

  _exibirMarcador ( Position local, String icone, String infoWindow ) async {

    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration( devicePixelRatio: pixelRatio),
        icone)
        .then((BitmapDescriptor bitmapDescriptor) {

      Marker marcador = Marker(
        markerId: MarkerId(icone),
        position: LatLng( local.latitude, local.longitude),
        infoWindow: InfoWindow(
            title: infoWindow),
        icon: bitmapDescriptor,);

      setState(() {
        _marcadores.add( marcador);
      });
    });
  }

  Future<dynamic>_recuperarRequisicao () async {

    dynamic idRequisicao = widget.idRequisicao;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot documentSnapshot = await db
        .collection("requisicoes")
        .doc( idRequisicao )
        .get();
  }

  Future<dynamic> _adicinarListenerRequisicao() async {

    FirebaseFirestore db = FirebaseFirestore.instance;

    await db.collection("requisicoes")
        .doc( _idRequisicao ).snapshots().listen(( snapshot ) {

      if (snapshot.data() != null) {

        _dadosRequisicao = snapshot.data();

        dynamic dados = snapshot.data();
        _statusRequisicao = dados["status"];

        switch (_statusRequisicao) {
          case StatusRequisicao.AGUARDANDO :
            _statusAguardando();
            break;
          case StatusRequisicao.A_CAMINHO :
            _statusACaminho();
            break;
          case StatusRequisicao.VIAGEM :
            _statusEmViagem();
            break;
          case StatusRequisicao.FINALIZADA :
            _statusFinalizada();
            break;
          case StatusRequisicao.CONFIRMADA :
            _confirmarConfirmada();
            break;
        }
      }
    });
  }

  _statusAguardando () {
    _alterarBotaoPrincipal(
        "Aceitar corrida",
        Color(0xff1ebbd8),
            (){
          _aceitarCorrida();
        });

    if( _localMotorista != null){

      dynamic motoristaLat = _localMotorista!.latitude;
      dynamic motoristaLon = _localMotorista!.longitude;

      Position? position = Position(
        latitude: motoristaLat, longitude: motoristaLon,
        timestamp: DateTime.fromMillisecondsSinceEpoch(Duration.secondsPerMinute),
        accuracy: 18,
        altitude: 18,
        heading: 00,
        speed: 05,
        speedAccuracy: 10,
      );

      _exibirMarcador (
          position,
          "imagens/motorista.png",
          "Motorista");

      CameraPosition cameraPosition = CameraPosition(
          target: LatLng( position.latitude, position.longitude),
          zoom: 19);
      _movimentarCamera( cameraPosition );
    }
  }

  _statusACaminho () {

    _mensagemStatus = "A caminho do passageiro";
    _alterarBotaoPrincipal(
        "Iniciar corrida",
        Color(0xff1ebbd8),
            (){
          _iniciarCorrida();
        }
    );

    dynamic latitudeDestino = _dadosRequisicao["passageiro"]["latitude"];
    dynamic longitudeDestino = _dadosRequisicao["passageiro"]["longitude"];

    dynamic latitudeOrigem = _dadosRequisicao["motorista"]["latitude"];
    dynamic longitudeOrigem = _dadosRequisicao["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
        LatLng (latitudeOrigem , longitudeOrigem),
        "imagens/motorista.png",
        "Local Motorista"
    );

    Marcador marcadorDestino = Marcador(
        LatLng (latitudeDestino , longitudeDestino),
        "imagens/passageiro.png",
        "Local Passageiro"
    );

    _exibirCentralizarDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  _finalizarCorrida(){

    FirebaseFirestore db = FirebaseFirestore.instance;

    db.collection("requisicoes")
        .doc( _idRequisicao )
        .update({
      "status" : StatusRequisicao.FINALIZADA
    });

    dynamic idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
    db.collection("requisicao_ativa")
        .doc( idPassageiro )
        .update({ "status" : StatusRequisicao.FINALIZADA});

    dynamic idMotorista = _dadosRequisicao["motorista"]["idUsuario"];
    db.collection("requisicao_ativa_motorista")
        .doc( idMotorista )
        .update({ "status" : StatusRequisicao.FINALIZADA});
  }

  Future<dynamic>  _statusFinalizada() async {

    //Calcular valor da corrida "OBS: de preferencia usar a API direction do Google"

    dynamic latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    dynamic longitudeDestino = _dadosRequisicao["destino"]["longitude"];

    dynamic latitudeOrigem = _dadosRequisicao["origem"]["latitude"];
    dynamic longitudeOrigem = _dadosRequisicao["origem"]["longitude"];

    dynamic distanciaEmMetros = await Geolocator.distanceBetween(
        latitudeOrigem,
        longitudeOrigem,
        latitudeDestino,
        longitudeDestino
    );

    //Converter para KM
    double distanciaKm = distanciaEmMetros / 1000;

    //R$8,00 é o valor cobrado por KM
    double valorViagem = distanciaKm * 8;

    //Formatar valor viagem
    var v = NumberFormat("#,##0.00", "pt_BR");
    var valorViagemFormatado = v.format( valorViagem );

    _mensagemStatus = "Finalizada";
    _alterarBotaoPrincipal(
        "Confirmar - R\$ ${valorViagemFormatado}",
        Color(0xff1ebbd8),
            (){
          _confirmarCorrida();
        });

    _marcadores = {};

    Position? position = Position(
      latitude: latitudeDestino, longitude: longitudeDestino,
      timestamp: DateTime.fromMillisecondsSinceEpoch(Duration.secondsPerMinute),
      accuracy: 18,
      altitude: 18,
      heading: 00,
      speed: 05,
      speedAccuracy: 10,
    );

    _exibirMarcador (
        position,
        "imagens/destino.png",
        "Destino");

    setState(() {
      CameraPosition cameraPosition = CameraPosition(
          target: LatLng( position.latitude, position.longitude),
          zoom: 19);
      _movimentarCamera( cameraPosition );
    });
  }

  _confirmarConfirmada(){

    Navigator.pushReplacementNamed(context, RouteGenerator.ROTA_PAINELMOTORISTA);

  }

  _confirmarCorrida(){

    FirebaseFirestore db = FirebaseFirestore.instance;

    db.collection("requisicoes")
        .doc(_idRequisicao)
        .update({
      "status" : StatusRequisicao.CONFIRMADA
    });

    dynamic idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
    db.collection("requisicao_ativa")
        .doc( idPassageiro )
        .delete();

    dynamic idMotorista = _dadosRequisicao["motorista"]["idUsuario"];
    db.collection("requisicao_ativa_motorista")
        .doc( idMotorista )
        .delete();
  }

  _statusEmViagem () {

    _mensagemStatus = "Em viagem";
    _alterarBotaoPrincipal(
        "Finalizar corrida",
        Color(0xff1ebbd8),
            (){
          _finalizarCorrida();
        });

    dynamic latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    dynamic longitudeDestino = _dadosRequisicao["destino"]["longitude"];

    dynamic latitudeOrigem = _dadosRequisicao["motorista"]["latitude"];
    dynamic longitudeOrigem = _dadosRequisicao["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
        LatLng (latitudeOrigem , longitudeOrigem),
        "imagens/motorista.png",
        "Local Motorista"
    );

    Marcador marcadorDestino = Marcador(
        LatLng (latitudeDestino , longitudeDestino),
        "imagens/destino.png",
        "Local de Destino"
    );

    _exibirCentralizarDoisMarcadores(marcadorOrigem, marcadorDestino);

    /* método para código único que não se replica
    //Exibir dois marcadores
    _exibirDoisMarcadores(
        LatLng(latitudeOrigem, longitudeOrigem),
        LatLng(latitudeDestino, longitudeDestino));

    //Posição Nordeste tem que sempre ser menor a a posição sudoeste (para isso o if)
    dynamic nLat, nlon, sLat, sLon;

    if( latitudeOrigem <= latitudeDestino ){
      sLat = latitudeOrigem;
      nLat = latitudeDestino;
    }else{
      sLat = latitudeDestino;
      nLat = latitudeOrigem;
    }
    if( longitudeOrigem <= longitudeDestino ){
      sLon = longitudeOrigem;
      nlon = longitudeDestino;
    }else{
      sLon = longitudeDestino;
      nlon = longitudeOrigem;
    }
    _movimentarCameraBounds(
        LatLngBounds(
            northeast: LatLng( nLat, nlon),  //Nordeste
            southwest: LatLng( sLat, sLon)  //Sudoeste
        ));

     */
  }

  _exibirCentralizarDoisMarcadores( Marcador marcadorOrigem, Marcador marcadorDestino ){

    dynamic latitudeOrigem = marcadorOrigem.local.latitude;
    dynamic longitudeOrigem = marcadorOrigem.local.longitude;

    dynamic latitudeDestino = marcadorDestino.local.latitude;
    dynamic longitudeDestino = marcadorDestino.local.longitude;

    //Exibir dois marcadores
    _exibirDoisMarcadores(
        marcadorOrigem,
        marcadorDestino
    );

    //Posição Nordeste tem que sempre ser menor a a posição sudoeste (para isso o if)
    dynamic nLat, nlon, sLat, sLon; //var

    if( latitudeOrigem <= latitudeDestino ){
      sLat = latitudeOrigem;
      nLat = latitudeDestino;
    }else{
      sLat = latitudeDestino;
      nLat = latitudeOrigem;
    }
    if( longitudeOrigem <= longitudeDestino ){
      sLon = longitudeOrigem;
      nlon = longitudeDestino;
    }else{
      sLon = longitudeDestino;
      nlon = longitudeOrigem;
    }
    _movimentarCameraBounds(
        LatLngBounds(
            northeast: LatLng( nLat, nlon),  //Nordeste
            southwest: LatLng( sLat, sLon)  //Sudoeste
        ));
  }


  _iniciarCorrida(){

    FirebaseFirestore db = FirebaseFirestore.instance;

    db.collection("requisicoes")
        .doc(_idRequisicao)
        .update({
      "origem" : {
        "latitude" : _dadosRequisicao["motorista"]["latitude"],
        "longitude" : _dadosRequisicao["motorista"]["longitude"]
      },
      "status" : StatusRequisicao.VIAGEM
    });

    dynamic idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
    db.collection("requisicao_ativa")
        .doc( idPassageiro )
        .update({ "status" : StatusRequisicao.VIAGEM});

    dynamic idMotorista = _dadosRequisicao["motorista"]["idUsuario"];
    db.collection("requisicao_ativa_motorista")
        .doc( idMotorista )
        .update({ "status" : StatusRequisicao.VIAGEM});
  }

  Future<dynamic> _movimentarCameraBounds ( LatLngBounds latLngBounds) async {

    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
        CameraUpdate.newLatLngBounds(
            latLngBounds,
            100)
    );
  }
  _exibirDoisMarcadores ( Marcador marcadorOrigem, Marcador marcadorDestino ){

    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    LatLng latLngOrigem = marcadorOrigem.local;
    LatLng latLngDestino = marcadorDestino.local;

    Set<Marker> _listaMarcadores = {};
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration( devicePixelRatio: pixelRatio),
        marcadorOrigem.caminhoImagem
    ).then((BitmapDescriptor icone) {

      Marker mOrigem = Marker(
        markerId: MarkerId(marcadorOrigem.caminhoImagem),
        position: LatLng( latLngOrigem.latitude, latLngOrigem.longitude),
        infoWindow: InfoWindow(title: marcadorOrigem.titulo),
        icon: icone,);
      _listaMarcadores.add( mOrigem );
    });

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration( devicePixelRatio: pixelRatio),
        marcadorDestino.caminhoImagem
    ).then((BitmapDescriptor icone) {

      Marker mDestino = Marker(
        markerId: MarkerId(marcadorDestino.caminhoImagem),
        position: LatLng( latLngDestino.latitude, latLngDestino.longitude),
        infoWindow: InfoWindow(title: marcadorDestino.titulo),
        icon: icone,);
      _listaMarcadores.add( mDestino );
    });

    setState(() {
      _marcadores = _listaMarcadores;
    });

  }

  Future<dynamic> _aceitarCorrida () async {

    //Recuperar dados do motorista
    dynamic motorista  = await UsuarioFirebase.getDadosUsuarioLogado();
    motorista.latitude = _localMotorista!.latitude;
    motorista.longitude = _localMotorista!.longitude;

    FirebaseFirestore db = FirebaseFirestore.instance;

    dynamic idRequisicao = _dadosRequisicao["id"];
    db.collection("requisicoes")
        .doc( idRequisicao )
        .update({
      "motorista" : motorista.toMap(),
      "status" : StatusRequisicao.A_CAMINHO,
    }).then((_) {

      //Atualizar requisição ativa
      dynamic idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
      db.collection("requisicao_ativa")
          .doc( idPassageiro )
          .update({
        "status" : StatusRequisicao.A_CAMINHO,
      });

      //Salvar requisição ativa para Motorista
      dynamic idMotorista = motorista.idUsuario;
      db.collection("requisicao_ativa_motorista")
          .doc( idMotorista )
          .set({
        "id_requisicao" : idRequisicao,
        "id_usuario" : idMotorista,
        "status" : StatusRequisicao.A_CAMINHO,
      });
    });
  }

  @override
  void initState() {
    super.initState();

    _idRequisicao = widget.idRequisicao;

    //Adicionar listener para mudanças na requisição
    _adicinarListenerRequisicao();

    //_recuperarUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

        appBar: AppBar(
          title: Text("Painel Corrida - " + _mensagemStatus ),
        ),

        body: Stack(
                children: <Widget> [

                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _posicaoCamera,
                    onMapCreated: _onMapCreated,
                    //myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    markers: _marcadores,
                  ),

                  Positioned(
                      right: 0,
                      left: 0,
                      bottom: 0,
                      child: Padding(

                        //import 'dart:io'; para configurações diferentes em Ios e Android
                        padding: Platform.isIOS
                            ? EdgeInsets.fromLTRB(20, 10, 20, 25)
                            : EdgeInsets.all(10),

                        child: ElevatedButton(
                          child: Text(
                            _textoBotao,
                            style: TextStyle(
                              fontSize: 22,
                              decorationColor: Colors.white,
                            ),
                          ),
                          onPressed: (){ _funcaoBotao!(); }  ,
                          style: ElevatedButton.styleFrom(
                              primary: _corBotao, //Cor do Botão
                              shadowColor: Colors.black,
                              elevation: 15,
                              padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)
                              )
                          ),),
                      ))

                ])


    );
  }
}
