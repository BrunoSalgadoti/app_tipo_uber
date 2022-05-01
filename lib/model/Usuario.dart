

class Usuario {

  String? _idUsuario;
  String? _nome;
  String? _email;
  String? _senha;
  String? _tipoUsuario;

  dynamic _latitude;
  dynamic _longitude;


  Usuario();

  toMap() {

    Map<String, dynamic>  map ={
      "idUsuario"   : this.idUsuario,
      "nome"        : this.nome,
      "email"       : this.email,
      "tipoUsuario" : this._tipoUsuario,
      "latitude"    : this._latitude,
      "longitude"   : this._longitude,
    };
    return map;
  }

  String verificaTipoUsuario (bool tipopUsuario) {
    return tipopUsuario ? "motorista" : "passageiro";
  }

  dynamic get longitude => _longitude;

  set longitude(dynamic value) {
    _longitude = value;
  }

  dynamic get latitude => _latitude;

  set latitude(dynamic value) {
    _latitude = value;
  }

  String get tipoUsuario => _tipoUsuario!;

  set tipoUsuario(String value) {
    _tipoUsuario = value;
  }

  String get senha => _senha!;

  set senha(String value) {
    _senha = value;
  }

  String get email => _email!;

  set email(String value) {
    _email = value;
  }

  String get nome => _nome!;

  set nome(String value) {
    _nome = value;
  }

  String get idUsuario => _idUsuario!;

  set idUsuario(String value) {
    _idUsuario = value;
  }
}