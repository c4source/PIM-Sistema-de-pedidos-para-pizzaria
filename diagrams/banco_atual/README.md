# Diagramas do banco atual

Referência de 31/10/2026, commit 54773ab. Leia [a documentação completa](../../docs/08_modelagem_database.md). Cada .mmd é uma fonte Mermaid; cada .svg é sua exportação vetorial para visualização e apresentação. O DER descreve as tabelas PostgreSQL, enquanto o fluxo de sincronização mostra a relação lógica com o SQLite, sem sugerir FKs entre os dois motores.

Renderização conferida com Mermaid CLI 12.0.0 e tema mermaid-config.json. Exemplo de regeneração na raiz do repositório (requer Node.js e navegador compatível com Puppeteer):

```powershell
npx --yes --package @mermaid-js/mermaid-cli@12.0.0 mmdc -i diagrams/banco_atual/01_visao_geral.mmd -o diagrams/banco_atual/01_visao_geral.svg -c diagrams/banco_atual/mermaid-config.json -b white --no-font-embed
```

Pode-se configurar PUPPETEER_EXECUTABLE_PATH para utilizar uma instalação local do Chrome. A ferramenta de desenho não é uma dependência de execução do PIM.
