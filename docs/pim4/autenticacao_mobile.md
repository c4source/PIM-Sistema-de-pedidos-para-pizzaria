# RF33 — Autenticação de Funcionários

## Descrição

O aplicativo Flutter permite que funcionários cadastrados
realizem login utilizando a API ASP.NET Core e o PostgreSQL.

A autenticação utiliza JWT para proteger o acesso às
funcionalidades administrativas.

## Arquitetura

LoginScreen
→ AuthRepository
→ AuthApi
→ POST /api/Auth/login-colaborador
→ AuthController
→ PostgreSQL

O JWT é armazenado no dispositivo utilizando
flutter_secure_storage.

## Login

O funcionário informa seu e-mail e senha.

Se as credenciais forem válidas, o backend retorna
um token JWT e as informações do usuário.

O aplicativo armazena o token definitivo e direciona
o funcionário para a Home administrativa.

Credenciais inválidas são rejeitadas.

## Troca obrigatória de senha

Funcionários cadastrados com senha provisória devem
definir uma senha pessoal no primeiro acesso.

O backend informa essa exigência pelo campo
`trocaSenhaObrigatoria`.

Quando esse campo é verdadeiro, o Flutter abre a
tela `TrocarSenhaScreen`.

A nova senha é enviada para:

POST /api/Auth/trocar-senha

O token provisório não é armazenado como sessão
administrativa definitiva.

Após a troca, o backend retorna um novo JWT,
que permite acessar a Home.

## Validação da sessão JWT

Ao iniciar o aplicativo, o AuthRepository verifica:

- Se existe um token armazenado.
- Se o token possui estrutura válida.
- Se o prazo de expiração foi ultrapassado.
- Se a API confirma que a sessão continua autorizada.

A validação remota utiliza:

GET /api/Auth/sessao

Tokens expirados ou rejeitados pela API são removidos.

Quando a API está indisponível, o aplicativo permite
restaurar uma sessão com JWT ainda não expirado.
Essa verificação local não substitui a validação
de segurança realizada pelo backend.

O funcionamento offline completo será desenvolvido
no RF40, utilizando SQLite e sincronização de dados.

## Testes realizados

- Login do administrador pelo Flutter.
- Login de colaborador com senha definitiva.
- Login de colaborador com senha provisória.
- Redirecionamento para troca obrigatória de senha.
- Definição de nova senha.
- Invalidação da senha provisória.
- Login utilizando a senha definitiva.
- Persistência da sessão após fechar e reabrir o aplicativo.
- Análise estática com flutter analyze sem erros.

## Resultado

O RF33 está implementado e teve seus principais fluxos
de autenticação validados com Flutter, API e PostgreSQL.

A expiração e a revogação da sessão são tratadas pelo
aplicativo e pelo backend, conforme suas responsabilidades.

---

# RF41 — Encerramento de Sessão

## Descrição

Foi implementada a funcionalidade de encerramento de sessão
no aplicativo Flutter.

O funcionário autenticado pode sair do sistema por meio
do botão de logout disponível na Home administrativa.

## Implementação no Flutter

O arquivo `home_screen.dart` possui um botão de saída
identificado pelo ícone `Icons.logout`.

Ao selecionar essa opção, o aplicativo executa
o método `logout()` do `AuthRepository`.

Esse método remove o token JWT armazenado no
`FlutterSecureStorage`.

Após a remoção, o aplicativo redireciona o funcionário
para a tela de Login e limpa o histórico de navegação.

## Fluxo

HomeScreen
→ AuthRepository.logout()
→ Exclusão do JWT local
→ Limpeza do histórico de navegação
→ LoginScreen

## Segurança

Após o logout, o aplicativo não mantém o token JWT
no armazenamento seguro.

O funcionário precisa realizar uma nova autenticação
para acessar novamente as funcionalidades administrativas.

O logout implementado é local: não revoga automaticamente
o JWT no servidor.

## Testes realizados

- Login administrativo realizado com sucesso.
- Botão de logout exibido na Home.
- Encerramento de sessão pelo Flutter.
- Redirecionamento automático para o Login.
- Bloqueio do retorno à Home pelo botão Voltar.
- Novo login realizado após o logout.
- Análise estática com `flutter analyze` sem erros.

## Resultado

O RF41 foi implementado e testado com sucesso.

O funcionário consegue encerrar sua sessão no aplicativo,
removendo o token JWT armazenado e retornando ao Login.