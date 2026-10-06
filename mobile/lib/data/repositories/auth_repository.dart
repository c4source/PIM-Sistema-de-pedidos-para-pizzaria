import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/auth_api.dart';

class AuthRepository {
  final AuthApi _authApi = AuthApi();

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(
    String email,
    String senha,
  ) async {
    final resposta = await _authApi.login(email, senha);

    final token = resposta['token'];

    if (token != null) {
      await _storage.write(
        key: 'token',
        value: token,
      );
    }

    return resposta;
  }

  Future<bool> temSessao() async {
    final token = await _storage.read(key: 'token');

    return token != null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }
}