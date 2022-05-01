

class Destino {

  String? _rua;
  String? _numero;
  String? _cidade;
  String? _bairro;
  String? _cep;
  dynamic _latitude;
  dynamic _longitude;

  Destino();

  dynamic get longitude => _longitude;

  set longitude(dynamic value) {
    _longitude = value;
  }

  dynamic get latitude => _latitude;

  set latitude(dynamic value) {
    _latitude = value;
  }

  String get cep => _cep!;

  set cep(String value) {
    _cep = value;
  }

  String get bairro => _bairro!;

  set bairro(String value) {
    _bairro = value;
  }

  String get cidade => _cidade!;

  set cidade(String value) {
    _cidade = value;
  }

  String get numero => _numero!;

  set numero(String value) {
    _numero = value;
  }

  String get rua => _rua!;

  set rua(String value) {
    _rua = value;
  }
}