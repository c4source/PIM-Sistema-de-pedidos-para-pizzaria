const cp=require('node:child_process');const fs=require('node:fs');
let atual='';try{atual=cp.execFileSync('git',['config','--get','core.hooksPath'],{encoding:'utf8'}).trim();}catch(_){}
if(atual&&atual!=='.githooks'){console.error('Já existe uma pasta de hooks configurada. Integre scripts/verificar-segredos.cjs ao hook atual; nenhuma configuração foi sobrescrita.');process.exitCode=1;}
else{fs.chmodSync('.githooks/pre-commit',0o755);cp.execFileSync('git',['config','core.hooksPath','.githooks']);console.log('Verificação de segredos ativada antes dos commits nesta cópia do projeto.');}
