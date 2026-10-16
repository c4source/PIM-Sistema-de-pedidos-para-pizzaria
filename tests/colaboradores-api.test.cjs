const assert=require('node:assert/strict');
const base=process.env.PIM_TEST_API||'http://localhost:5163/api';
const emailAdmin=process.env.PIM_TEST_ADMIN_EMAIL||'admin@pim.com';
const senhaAdmin=process.env.PIM_TEST_ADMIN_PASSWORD||'123456';
const cleanup=[];let admin;
async function req(path,method='GET',body,token,status=200){const r=await fetch(base+path,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:body?JSON.stringify(body):undefined});const raw=await r.text();assert.equal(r.status,status,`${method} ${path}: ${raw}`);console.log(`${method} ${path}: ${status}`);try{return JSON.parse(raw)}catch{return raw}}
async function run(){
await req('/Colaboradores','GET',null,null,401);
admin=await req('/Auth/login-colaborador','POST',{email:emailAdmin,senha:senhaAdmin});assert.equal(admin.perfil,'Administrador');
const me=await req('/Auth/sessao','GET',null,admin.token);
await req('/Colaboradores/'+me.id,'DELETE',null,admin.token,400);
const original=await req('/Colaboradores/'+me.id,'GET',null,admin.token);
const users=await req('/Colaboradores','GET',null,admin.token);if(users.filter(u=>u.perfil==='Administrador'&&!u.trocarSenha).length===1)await req('/Colaboradores/'+me.id,'PUT',{nome:original.nome,email:original.email,perfil:'Colaborador'},admin.token,400);
const suffix=Date.now();const email=`teste.acesso.${suffix}@example.com`;
const created=await req('/Colaboradores','POST',{nome:'Teste Acesso',email,perfil:'Colaborador',senha:'senha escolhida deve ser ignorada'},admin.token,201);cleanup.push(created.colaborador.id);assert.ok(created.senhaProvisoria.length>=20);assert.equal(created.colaborador.trocarSenha,true);
await req('/Colaboradores','POST',{nome:'Teste Duplicado',email:email.toUpperCase(),perfil:'Colaborador'},admin.token,409);
await req('/Colaboradores','POST',{nome:'Teste Perfil',email:`invalido.${suffix}@example.com`,perfil:'SuperAdmin'},admin.token,400);
const provisoria=await req('/Auth/login-colaborador','POST',{email:email.toUpperCase(),senha:created.senhaProvisoria});assert.equal(provisoria.trocaSenhaObrigatoria,true);
for(const route of ['/Pedido','/Colaboradores','/Auth/sessao'])await req(route,'GET',null,provisoria.token,403);
await req('/Produto','POST',{},provisoria.token,403);
await req('/Auth/trocar-senha','POST',{novaSenha:'curta',confirmacaoSenha:'curta'},provisoria.token,400);
await req('/Auth/trocar-senha','POST',{novaSenha:'NovaSenha!2026',confirmacaoSenha:'outra'},provisoria.token,400);
await req('/Auth/trocar-senha','POST',{novaSenha:created.senhaProvisoria,confirmacaoSenha:created.senhaProvisoria},provisoria.token,400);
const normal=await req('/Auth/trocar-senha','POST',{novaSenha:'NovaSenha!2026',confirmacaoSenha:'NovaSenha!2026'},provisoria.token);assert.equal(normal.trocaSenhaObrigatoria,false);
await req('/Auth/trocar-senha','POST',{novaSenha:'OutraSenha!2026',confirmacaoSenha:'OutraSenha!2026'},provisoria.token,401);
await req('/Auth/login-colaborador','POST',{email,senha:created.senhaProvisoria},null,401);
const login=await req('/Auth/login-colaborador','POST',{email,senha:'NovaSenha!2026'});await req('/Pedido','GET',null,login.token);
for(const [method,path,body] of [['GET','/Colaboradores'],['POST','/Colaboradores',{nome:'Intruso',email:'intruso@example.com'}],['PUT','/Colaboradores/'+me.id,{nome:'Intruso',email:'intruso@example.com',perfil:'Administrador'}],['DELETE','/Colaboradores/'+me.id]])await req(path,method,body,login.token,403);
await req('/Colaboradores/'+created.colaborador.id+'/resetar-senha','POST',null,null,401);
await req('/Colaboradores/'+created.colaborador.id+'/resetar-senha','POST',null,login.token,403);
await req('/Colaboradores/'+me.id+'/resetar-senha','POST',null,admin.token,400);
await req('/Colaboradores/2147483647/resetar-senha','POST',null,admin.token,404);
const reset=await req('/Colaboradores/'+created.colaborador.id+'/resetar-senha','POST',null,admin.token);
assert.equal(reset.colaborador.trocarSenha,true);assert.notEqual(reset.senhaProvisoria,created.senhaProvisoria);
await req('/Pedido','GET',null,login.token,401);
await req('/Auth/login-colaborador','POST',{email,senha:'NovaSenha!2026'},null,401);
const resetLogin=await req('/Auth/login-colaborador','POST',{email,senha:reset.senhaProvisoria});assert.equal(resetLogin.trocaSenhaObrigatoria,true);
await req('/Pedido','GET',null,resetLogin.token,403);
const resetAgain=await req('/Colaboradores/'+created.colaborador.id+'/resetar-senha','POST',null,admin.token);
await req('/Auth/trocar-senha','POST',{novaSenha:'NovaSenha!2026',confirmacaoSenha:'NovaSenha!2026'},resetLogin.token,401);
await req('/Auth/login-colaborador','POST',{email,senha:reset.senhaProvisoria},null,401);
const secondResetLogin=await req('/Auth/login-colaborador','POST',{email,senha:resetAgain.senhaProvisoria});
await req('/Auth/trocar-senha','POST',{novaSenha:'NovaSenha!2026',confirmacaoSenha:'NovaSenha!2026'},secondResetLogin.token);
await req('/Auth/login-colaborador','POST',{email,senha:resetAgain.senhaProvisoria},null,401);
const list=await req('/Colaboradores','GET',null,admin.token);for(const u of list){assert.ok(!('senha' in u));assert.ok(!('senhaProvisoria' in u));}
await req('/Colaboradores/'+created.colaborador.id,'PUT',{nome:'Teste Atualizado',email,perfil:'Administrador'},admin.token,204);
await req('/Pedido','GET',null,login.token,401);
const elevated=await req('/Auth/login-colaborador','POST',{email,senha:'NovaSenha!2026'});await req('/Colaboradores','GET',null,elevated.token);
await req('/Colaboradores/'+created.colaborador.id,'PUT',{nome:'Teste Atualizado',email,perfil:'Colaborador'},admin.token,204);
await req('/Colaboradores','GET',null,elevated.token,401);
const latest=await req('/Auth/login-colaborador','POST',{email,senha:'NovaSenha!2026'});
await req('/Colaboradores/'+created.colaborador.id,'DELETE',null,admin.token,204);cleanup.splice(cleanup.indexOf(created.colaborador.id),1);
await req('/Pedido','GET',null,latest.token,401);
// Administrador pendente não deve obter poderes antes da troca.
const pending=await req('/Colaboradores','POST',{nome:'Teste Admin Pendente',email:`teste.pendente.${suffix}@example.com`,perfil:'Administrador'},admin.token,201);cleanup.push(pending.colaborador.id);
const pendingLogin=await req('/Auth/login-colaborador','POST',{email:pending.colaborador.email,senha:pending.senhaProvisoria});await req('/Colaboradores','GET',null,pendingLogin.token,403);
console.log('Fluxo de acessos validado.');
}
run().catch(e=>{console.error(e.message);process.exitCode=1}).finally(async()=>{for(const id of cleanup){try{await req('/Colaboradores/'+id,'DELETE',null,admin.token,204)}catch(e){console.error('Falha na limpeza do acesso de teste '+id+': '+e.message);process.exitCode=1}}});
