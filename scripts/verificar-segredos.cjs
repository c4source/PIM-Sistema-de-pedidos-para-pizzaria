#!/usr/bin/env node
const fs = require('node:fs');
const cp = require('node:child_process');
function permitido(valor) { return !valor || /^(SUA_SENHA|SEU_USUARIO|GERE_|CHANGEME|EXAMPLE|PLACEHOLDER|<)/i.test(valor) || /\$\{|%[A-Z_]+%/.test(valor); }
function analisar(nome, texto) {
  const problemas = [];
  const privado = /(^|\/)(appsettings\.Local\.json|appsettings\.Development\.json|secrets\.json|credentials\.json|key\.properties|local\.properties|\.env(?:\..+)?)$/i.test(nome) && !/\.(example|sample)$/i.test(nome);
  if(privado || /\.(pfx|p12|pem|key|jks|keystore|dump|backup|bak)$/i.test(nome)) problemas.push({linha:1,motivo:'Arquivo privado ou backup não deve ser commitado.'});
  texto.split(/\r?\n/).forEach((linha,i)=>{
    const senha = linha.match(/\bPassword\s*=\s*([^;"'\r\n]+)/i);
    if(senha && (/\b(?:Host|Server|Database|Username|Data Source)\s*=/i.test(linha) || /^\s*Password\s*=/i.test(linha)) && !permitido(senha[1].trim())) problemas.push({linha:i+1,motivo:'Possível senha em string de conexão.'});
    if(/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/.test(linha) || /\bgh[pousr]_[A-Za-z0-9]{20,}\b/.test(linha) || /\bAKIA[A-Z0-9]{16}\b/.test(linha)) problemas.push({linha:i+1,motivo:'Possível chave privada ou token de acesso.'});
    if(/\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]{16,}\b/.test(linha)) problemas.push({linha:i+1,motivo:'Possível JWT real.'});
  });
  if(/appsettings.*\.json$/i.test(nome)) {
    try { const json=JSON.parse(texto.replace(/^\uFEFF/,'')); if(json.Jwt?.Key && !permitido(json.Jwt.Key)) problemas.push({linha:1,motivo:'Chave JWT deve ficar em configuração local ou variável de ambiente.'}); } catch(_) {}
  }
  return problemas;
}
function executar() {
  const working=process.argv.includes('--working-tree');
  const args=working?['ls-files','-z','--cached','--others','--exclude-standard']:['diff','--cached','--name-only','--diff-filter=ACMR','-z'];
  const nomes=[...new Set(cp.execFileSync('git',args).toString().split('\0').filter(Boolean))];
  let total=0;
  for(const nome of nomes){let buffer;try{buffer=working?fs.readFileSync(nome):cp.execFileSync('git',['show',':'+nome],{maxBuffer:16*1024*1024});}catch(_){continue;}
    if(buffer.includes(0)&&! /\.(pfx|p12|jks|keystore|dump|backup)$/i.test(nome))continue;
    for(const p of analisar(nome,buffer.toString('utf8'))){console.error(nome+':'+p.linha+' — '+p.motivo);total++;}
  }
  if(total){console.error('Verificação bloqueada: '+total+' ocorrência(s). Nenhum valor de segredo foi exibido.');process.exitCode=1;}
  else console.log('Verificação local de segredos: nenhuma ocorrência nos '+nomes.length+' arquivos '+(working?'do projeto.':'preparados para commit.'));
}
module.exports={analisar};
if(require.main===module)executar();
