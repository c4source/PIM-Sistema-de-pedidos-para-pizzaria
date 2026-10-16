# RF33 — Autenticação de Funcionários

O aplicativo mobile realiza a autenticação de funcionários por meio
da API REST existente no backend ASP.NET Core.

## Fluxo

Flutter
→ AuthRepository
→ AuthApi
→ POST /api/Auth/login-colaborador
→ AuthController
→ PostgreSQL

Após a autenticação, a API retorna um token JWT, que é armazenado
localmente no dispositivo utilizando flutter_secure_storage.

Ao iniciar o aplicativo, o sistema verifica a existência de uma sessão
salva. Caso exista, o usuário é direcionado diretamente para a Home.
Caso contrário, é apresentada a tela de login.

## Endpoint utilizado

POST /api/Auth/login-colaborador

Durante o desenvolvimento com Android Emulator, a API local é acessada
pelo endereço http://10.0.2.2:5162.

## Resultado

O funcionário autenticado recebe um token JWT, que é armazenado de forma
segura no dispositivo. Ao reiniciar o aplicativo, a existência da sessão
é verificada e o usuário é direcionado diretamente para a Home.