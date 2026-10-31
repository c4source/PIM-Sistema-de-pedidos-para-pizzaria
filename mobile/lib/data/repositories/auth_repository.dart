import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:convert';

import '../api/auth_api.dart';

class AuthRepository {
  static DateTime? _ultimaAtividade;
  Future<bool> registrarAtividade() async {
    final token = await obterToken();
    if (token == null) return true;
    final agora = DateTime.now();
    if (_ultimaAtividade != null &&
        agora.difference(_ultimaAtividade!).inSeconds < 30) {
      return true;
    }
    _ultimaAtividade = agora;
    try {
      final valida = await _authApi.registrarAtividade(token);
      if (!valida) await logout();
      return valida;
    } catch (_) {
      return true;
    }
  }

  final AuthApi _authApi = AuthApi();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Future<Map<String, dynamic>> login(String email, String senha) async {
    final resposta = await _authApi.login(email, senha);

    final token = resposta['token'];
    final trocaSenhaObrigatoria = resposta['trocaSenhaObrigatoria'] == true;

    if (trocaSenhaObrigatoria) {
      // Não salvar o token provisório como sessão normal.
      await _storage.delete(key: 'token');
    } else if (token is String && token.isNotEmpty) {
      // Salvar apenas o token da sessão administrativa.
      await _storage.write(key: 'token', value: token);
    }

    return resposta;
  }

  Future<bool> temSessao() async {
    final token = await _storage.read(key: 'token');

    if (token == null || token.isEmpty) {
      return false;
    }

    // 1. Verifica a expiração local do JWT.
    try {
      final partes = token.split('.');

      if (partes.length != 3) {
        throw const FormatException('Token inválido');
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
      );

      final exp = payload['exp'];

      if (exp is! int || DateTime.now().millisecondsSinceEpoch >= exp * 1000) {
        await _storage.delete(key: 'token');
        return false;
      }
    } catch (_) {
      await _storage.delete(key: 'token');
      return false;
    }

    // 2. Consulta o backend para verificar a sessão.
    try {
      final sessaoValida = await _authApi
          .validarSessao(token)
          .timeout(const Duration(seconds: 5));

      if (!sessaoValida) {
        await _storage.delete(key: 'token');
        return false;
      }

      return true;
    } catch (_) {
      // Sem conexão: permite continuar com o JWT não expirado.
      // A validade da sessão será confirmada quando a API voltar.
      return true;
    }
  }

  Future<String?> obterToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }

  Future<void> trocarSenha({
    required String tokenProvisorio,
    required String novaSenha,
  }) async {
    final resposta = await _authApi.trocarSenha(
      token: tokenProvisorio,
      novaSenha: novaSenha,
    );

    final novoToken = resposta['token'];

    if (novoToken is! String ||
        novoToken.isEmpty ||
        resposta['trocaSenhaObrigatoria'] == true) {
      throw Exception('Resposta inválida da API após troca de senha.');
    }

    // Salva o JWT definitivo após a troca de senha.
    await _storage.write(key: 'token', value: novoToken);
  }
}
