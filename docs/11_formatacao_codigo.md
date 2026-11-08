# Formatação do código

A configuração .editorconfig define espaços, indentação e quebras de linha. O C# utiliza 4 espaços e blocos em linhas separadas; frontend e Dart utilizam 2 espaços. A configuração .prettierrc.json padroniza HTML, CSS, JavaScript e os testes Node.

Na raiz do projeto:

~~~powershell
# C#: apenas formatação, sem correções automáticas de analisadores.
dotnet format whitespace backend/Pim.csproj --no-restore

# Frontend e testes JavaScript.
npx --yes prettier@3.6.2 --write "frontend/**/*.{html,css,js}" "tests/**/*.cjs"

# Flutter/Dart.
dart format mobile/lib
~~~

Para conferir sem modificar arquivos, use --verify-no-changes no dotnet format, --check no Prettier e --output=none --set-exit-if-changed no dart format.

Os formatadores não substituem compilação e testes. SQL, scripts de banco e diretórios gerados não fazem parte desses comandos. Nenhuma regra de negócio deve ser alterada em uma mudança de formatação.
