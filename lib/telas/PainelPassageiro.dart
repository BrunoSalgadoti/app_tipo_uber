import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uber/model/Destino.dart';
import 'package:uber/model/Marcador.dart';
import 'package:uber/model/Requisicao.dart';
import 'package:uber/model/RouteGenerator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uber/util/StatusRequisicao.dart';
import 'package:uber/util/UsuarioFirebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PainelPassageiro extends StatefulWidget {
  const PainelPassageiro({Key? key}) : super(key: key);

  @override
  State<PainelPassageiro> createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro> {

  Completer<GoogleMapController> _controller = Completer();
  TextEditingController _controleDestino = TextEditingController();

  //posição inicial camera PADRÃO
  CameraPosition _posicaoCamera = CameraPosition(
    target: LatLng(-23.563999, -46.653256),
  );

  Set<Marker> _marcadores = {};
  dynamic _idRequisicao;
  Position? _localPassageiro;
  dynamic _dadosRequisicao;
  StreamSubscription<DocumentSnapshot>? _streamSubscriptionRequisicoes;

  //Controles para exibição na tela
  bool _exibirCaixaEnderecoDestino = true;
  String _textoBotao = "Chamar Uber";
  Color _corBotao = Color(0xff1ebbd8);
  late Function? _funcaoBotao;


  List<String> itensMenu = [
    "Configurações", "Deslogar"
  ];

  Future<dynamic> _deslogarUsuario () async {

    FirebaseAuth auth = FirebaseAuth.instance;

    await auth.signOut();
    Navigator.pushReplacementNamed(
        context, RouteGenerator.ROTA_ROOT
    );
  }

  _escolhaMenuItem (String escolha) {

    switch( escolha ) {
      case "Deslogar" :
        _deslogarUsuario();
        break;
      case "Configurações" :
        break;
    }
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

          if( _idRequisicao != null && _idRequisicao != 0 ){

            //Atualizar local passageiro
            UsuarioFirebase.atualizarDadosLocalizacao(
                _idRequisicao,
                position!.latitude,
                position.longitude,
              "passageiro"
            );

          }else{
            setState(() {
              _localPassageiro = position;
            });
            _statusUberNaoChamado();
          }
        });
  }

  Future<dynamic> _recuperarUltimaLocalizacaoConhecida() async {

    Position? position = await Geolocator
        .getLastKnownPosition();

    setState(() {
      if ( position != null){

        _exibirMarcadoresPassageiro ( position );
        _posicaoCamera = CameraPosition(
            target: LatLng( position.latitude, position.longitude), zoom: 19);
        _localPassageiro = position;

      }
    });
  }

  Future<dynamic> _movimentarCamera( CameraPosition cameraPosition) async {

    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
            cameraPosition)
    );
  }

  _exibirMarcadoresPassageiro ( Position local ) async {

    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration( devicePixelRatio: pixelRatio),
        "imagens/passageiro.png"
    ).then((BitmapDescriptor icone) {

      Marker marcadorPassageiro = Marker(
        markerId: MarkerId("marcador-passageiro"),
        position: LatLng( local.latitude, local.longitude),
        infoWindow: InfoWindow(
            title: "Meu Local"
        ),
        icon: icone,);

      setState(() {
        _marcadores.add( marcadorPassageiro);
      });
    });
  }

  Future<dynamic> _chamarUber () async {

    String enderecoDestino = _controleDestino.text;

    if( enderecoDestino.isNotEmpty ){

      List<Location> listaEnderecos = await locationFromAddress( enderecoDestino );

      if ( listaEnderecos != null && listaEnderecos.length > 0 ) {

        Location endereco = listaEnderecos[0];
        List<Placemark> placemarks = await placemarkFromCoordinates(endereco.latitude, endereco.longitude);
        Placemark localizacao = placemarks[0];

        Destino destino = Destino();

        destino.cidade = localizacao.administrativeArea.toString();
        destino.cep = localizacao.postalCode.toString();
        destino.bairro = localizacao.subLocality.toString();
        destino.rua = localizacao.thoroughfare.toString();
        destino.numero = localizacao.subThoroughfare.toString();

        destino.latitude = endereco.latitude.toString();
        destino.longitude = endereco.longitude.toString();

        String enderecoConfirmacao;
        enderecoConfirmacao = "\n Cidade: " + destino.cidade;
        enderecoConfirmacao += "\n Rua: " + destino.rua + ", " + destino.numero;
        enderecoConfirmacao += "\n Bairro: " + destino.bairro;
        enderecoConfirmacao += "\n Cep: " + destino.cep;

        showDialog(
            context: context,
            builder:  (context){
              return AlertDialog(
                title: Text("Confirmação de endereço"),
                content: Text( enderecoConfirmacao),
                contentPadding: EdgeInsets.all(16),
                actions: <Widget> [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[

                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white,
                            shadowColor: Colors.black,
                          ),
                        ),

                        ElevatedButton(
                          onPressed: () {

                            //Salvar requisição
                            _salvarRequisicao( destino );

                            Navigator.pop(context);
                          },
                          child: Text("Confirmar",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white,
                            shadowColor: Colors.black,
                          ),
                        ),
                      ])
                ],
              );
            }
        );
      }
    }else{
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Center(
                child: Text("Necessário Informar um endereço"),
              ),
              actions: <Widget>[
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Voltar e digitar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.redAccent,
                          shadowColor: Colors.black,
                        ),
                      ),
                    ])
              ],);
          });
    }
  }

  Future<dynamic> _salvarRequisicao ( Destino destino ) async {

    dynamic passageiro = await UsuarioFirebase.getDadosUsuarioLogado();
    passageiro.latitude = _localPassageiro!.latitude;
    passageiro.longitude = _localPassageiro!.longitude;

    Requisicao requisicao = Requisicao();
    requisicao.destino = destino;
    requisicao.passageiro = passageiro;
    requisicao.status = StatusRequisicao.AGUARDANDO;

    FirebaseFirestore db = FirebaseFirestore.instance;

    //salvar requisição
    db.collection("requisicoes")
        .doc ( requisicao.id )
        .set( requisicao.toMap() );

    //salvar requisição ativa
    Map<String, dynamic> dadosRequisicaoAtiva = {};
    dadosRequisicaoAtiva ["id_requisicao"] = requisicao.id;
    dadosRequisicaoAtiva ["id_usuario"] = passageiro.idUsuario;
    dadosRequisicaoAtiva ["status"] = StatusRequisicao.AGUARDANDO;

    db.collection("requisicao_ativa")
        .doc( passageiro.idUsuario )
        .set( dadosRequisicaoAtiva );

    //Adicionar listener requisicao
    if( _streamSubscriptionRequisicoes == null ){
      _adicionarListenerRequisicao( requisicao.id );
    }
  }

//--Metodos de auterações de visualização painel passageiro (ao clicar no botão)--

  _alterarBotaoPrincipal (String texto, Color cor, Function funcao) {
    setState(() {
      _textoBotao = texto;
      _corBotao = cor;
      _funcaoBotao = funcao;
    });
  }

  _statusUberNaoChamado () {

    setState(() {
      _exibirCaixaEnderecoDestino = true;
    });

    _alterarBotaoPrincipal(
        "Chamar Uber",
        Color(0xff1ebbd8),
            (){
          _chamarUber();
        });

    if( _localPassageiro != null ){

      Position? position = Position(
        latitude: _localPassageiro!.latitude,
        longitude: _localPassageiro!.longitude,
        timestamp: DateTime.fromMillisecondsSinceEpoch(Duration.secondsPerMinute),
        accuracy: 18,
        altitude: 18,
        heading: 00,
        speed: 05,
        speedAccuracy: 10,
      );

      setState(() {
        _exibirMarcadoresPassageiro ( position );
        CameraPosition cameraPosition = CameraPosition(
            target: LatLng( position.latitude, position.longitude),zoom: 19);
        _movimentarCamera( cameraPosition );
      });
    }
  }

  _statusAguardando () {
    setState(() {
      _exibirCaixaEnderecoDestino = false;
    });

    _alterarBotaoPrincipal(
        "Cancelar",
        Colors.red,
            (){
          _cancelarUber();
        });

    dynamic passageiroLat = _dadosRequisicao["passageiro"]["latitude"];
    dynamic passageiroLon = _dadosRequisicao["passageiro"]["longitude"];

    Position? position = Position(
      latitude: passageiroLat,
      longitude: passageiroLon,
      timestamp: DateTime.fromMillisecondsSinceEpoch(Duration.secondsPerMinute),
      accuracy: 18,
      altitude: 18,
      heading: 00,
      speed: 05,
      speedAccuracy: 10,
    );

    setState(() {
      _exibirMarcadoresPassageiro ( position );
      CameraPosition cameraPosition = CameraPosition(
          target: LatLng( position.latitude, position.longitude),zoom: 19);
      _movimentarCamera( cameraPosition );
    });
  }

  _statusACaminho () {
    setState(() {
      _exibirCaixaEnderecoDestino = false;
    });

    _alterarBotaoPrincipal(
        "Motorista a caminho",
        Colors.grey,
            (){}
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

  _statusEmViagem () {
    setState(() {
      _exibirCaixaEnderecoDestino = false;
    });

    _alterarBotaoPrincipal(
        "Em viagem",
        Colors.grey,
            (){}
    );

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
    var v = new NumberFormat("#,##0.00", "pt_BR");
    var valorViagemFormatado = v.format( valorViagem );

    _alterarBotaoPrincipal(
        "Total - R\$ ${valorViagemFormatado}",
        Colors.green,
            (){}
    );

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

  _statusConfirmada() {

    if( _streamSubscriptionRequisicoes != null){
      _streamSubscriptionRequisicoes!.cancel();
      _streamSubscriptionRequisicoes = null;
    }

    _exibirCaixaEnderecoDestino = true;
    _alterarBotaoPrincipal(
        "Chamar Uber",
        Color(0xff1ebbd8), (){
      _chamarUber();
    });

    //Exibe o local do passageiro
    dynamic passageiroLat = _dadosRequisicao["passageiro"]["latitude"];
    dynamic passageiroLon = _dadosRequisicao["passageiro"]["longitude"];

    Position? position = Position(
      latitude: passageiroLat,
      longitude: passageiroLon,
      timestamp: DateTime.fromMillisecondsSinceEpoch(Duration.secondsPerMinute),
      accuracy: 18,
      altitude: 18,
      heading: 00,
      speed: 05,
      speedAccuracy: 10,
    );

    setState(() {
      _exibirMarcadoresPassageiro ( position );
      CameraPosition cameraPosition = CameraPosition(
          target: LatLng( position.latitude, position.longitude),zoom: 19);
      _movimentarCamera( cameraPosition );
    });

    _dadosRequisicao = {};
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

  Future<dynamic> _cancelarUber() async {

    dynamic firebaseUser = await UsuarioFirebase.getUsuarioAtual();

    FirebaseFirestore db = FirebaseFirestore.instance;

    //_idRequisicao = _dadosRequisicao["id"];

    db.collection("requisicoes")
        .doc( _idRequisicao ).update({
      "status" : StatusRequisicao.CANCELADA
    }).then((_) {
      db.collection("requisicao_ativa")
          .doc( firebaseUser )
          .delete();
    });
    _statusUberNaoChamado();

    if( _streamSubscriptionRequisicoes != null){
      _streamSubscriptionRequisicoes!.cancel();
      _streamSubscriptionRequisicoes = null;
    }
  }

  Future<dynamic> _recuperarRequisicaoAtiva() async {

    dynamic firebaseUser = await UsuarioFirebase.getUsuarioAtual();

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot documentSnapshot = await db.collection("requisicao_ativa")
        .doc( firebaseUser )
        .get();

    if( documentSnapshot.data() != null ){

      dynamic dados = documentSnapshot.data();
      _idRequisicao = dados["id_requisicao"];
      _adicionarListenerRequisicao( _idRequisicao );

    }else{
      _statusUberNaoChamado();
    }
  }

  Future<dynamic> _adicionarListenerRequisicao( dynamic idRequisicao ) async {

    FirebaseFirestore db = FirebaseFirestore.instance;

    _streamSubscriptionRequisicoes = await db.collection("requisicoes")
        .doc( idRequisicao).snapshots().listen((snapshot) {

      if( snapshot.data() != null ){

        dynamic dados = snapshot.data();
        _dadosRequisicao = dados;
        dynamic status = dados["status"];
        _idRequisicao = dados["id"];

        switch( status ){
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
            _statusConfirmada();
            break;
        }
      }
    });

  }

  @override
  void initState() {
    super.initState();

    //adicionar listener para requisicao ativa
    _recuperarRequisicaoAtiva();

    //_recuperarUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

        appBar: AppBar(
          title: const Text("Painel Passageiro"),

          actions: <Widget> [

            PopupMenuButton(
                onSelected: _escolhaMenuItem,
                itemBuilder: (context){

                  return itensMenu.map((String item ){
                    return PopupMenuItem<String>(
                        value: item,
                        child: Text( item )
                    );
                  }).toList();

                })
          ],
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
                  Visibility(
                      visible: _exibirCaixaEnderecoDestino,
                      child: Stack(
                        children: <Widget> [

                          Positioned(
                              top: 0,
                              right: 0,
                              left: 0,
                              child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Container(
                                      height: 50,
                                      width: double.infinity,

                                      decoration: BoxDecoration(
                                          border: Border.all(color:  Colors.grey),
                                          borderRadius: BorderRadius.circular(3),
                                          color: Colors.white
                                      ),

                                      child: TextField(
                                        readOnly: true,
                                        decoration: InputDecoration(

                                            icon: Container(
                                              margin: EdgeInsets.only(left: 20),
                                              width: 10,
                                              height: 10,
                                              child: Icon(Icons.location_on, color: Colors.green),
                                            ),

                                            hintText: "Meu Local",
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.only(left: 15, top: 16)
                                        ),)
                                  )
                              )),

                          Positioned(
                              top: 55,
                              right: 0,
                              left: 0,
                              child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Container(
                                      height: 50,
                                      width: double.infinity,

                                      decoration: BoxDecoration(
                                          border: Border.all(color:  Colors.grey),
                                          borderRadius: BorderRadius.circular(3),
                                          color: Colors.white
                                      ),

                                      child: TextField(
                                        controller: _controleDestino,
                                        //readOnly: true,
                                        decoration: InputDecoration(

                                            icon: Container(
                                              margin: EdgeInsets.only(left: 20),
                                              width: 10,
                                              height: 10,
                                              child: Icon(Icons.local_taxi, color: Colors.black),
                                            ),

                                            hintText: "Digite o Destino",
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.only(left: 15, top: 16)
                                        ),)
                                  )
                              ))
                        ],
                      )),

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

  @override
  void dispose() {
    super.dispose();
    _streamSubscriptionRequisicoes!.cancel();
    _streamSubscriptionRequisicoes = null;
  }
}
