# Credenciais e Git

O arquivo backend/appsettings.json é público e não contém senha do banco nem chave JWT. Nesta máquina, as credenciais foram movidas para backend/appsettings.Local.json, ignorado pelo Git. A chave JWT local foi substituída por uma chave aleatória. O programa exige configuração válida, sem chave de fallback compartilhada.

## Outra máquina
Copie backend/appsettings.Local.example.json para backend/appsettings.Local.json. Ajuste a conexão PostgreSQL e substitua o placeholder da chave JWT por uma chave aleatória. Para gerar a chave em PowerShell:

~~~powershell
[Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(48))
~~~

Não compartilhe esse valor nem coloque o arquivo local no Git. Como alternativa, use ConnectionStrings__DefaultConnection e Jwt__Key como variáveis de ambiente. Elas têm precedência sobre o arquivo local. Arquivos locais de configuração não são copiados para publicação ou saída de build. Execute o servidor e o atualizador com a raiz de conteúdo apontando para backend, como ocorre em dotnet run --project backend e nos perfis do Visual Studio.

## Antes de commit e push

~~~powershell
node scripts/instalar-verificacao-git.cjs
node scripts/verificar-segredos.cjs --working-tree
git status
git diff --cached --name-only
~~~

O instalador ativa o hook pre-commit nesta cópia. Cada membro da equipe deve instalá-lo após clonar. O hook confere o conteúdo preparado no índice, não apenas os arquivos de trabalho, e não imprime valores de segredos. É uma proteção adicional por padrões conhecidos, não uma garantia de ausência de todos os tipos de credencial; hooks também podem ser ignorados pelo usuário. Não adicione arquivos com git add -f para contornar o ignore.

## Histórico já existente
A conexão e a chave JWT anteriores estavam no commit atual antes desta correção. A limpeza do arquivo protege novos commits, mas não apaga o histórico. A chave JWT local foi rotacionada; é preciso entrar novamente após reiniciar o backend. A senha do PostgreSQL não foi alterada automaticamente, pois pode ser usada por outras aplicações e máquinas. Troque a senha no PostgreSQL e atualize somente o arquivo local. Revogue outros segredos reais que tenham sido compartilhados. O administrador do repositório deve avaliar proteção contra segredos e eventual limpeza coordenada do histórico; este trabalho não reescreve branches compartilhadas.

Os dados e senhas de demonstração do seed/testes não são credenciais de produção. Não publique um ambiente real com a conta de demonstração ativa sem trocar a senha.
