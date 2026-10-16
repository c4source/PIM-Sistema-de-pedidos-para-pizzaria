var colaboradores=[];var formColaborador=document.getElementById('colaborador-form');var mensagemColaborador=document.getElementById('colaboradores-mensagem');var sessaoColaborador;
function mensagem(text){mensagemColaborador.textContent=text;}
function limparSenha(){
  var modal=document.getElementById('senha-provisoria-painel');
  if(modal.open) modal.close();
  document.getElementById('senha-provisoria-valor').textContent='';
  document.getElementById('senha-provisoria-email').textContent='';
  document.getElementById('acesso-modal-status').textContent='';
}
document.getElementById('senha-provisoria-painel').addEventListener('close',limparSenha);
function mostrarSenhaProvisoria(data, resetada) {
  document.getElementById('acesso-modal-titulo').textContent = resetada ? 'Senha resetada com sucesso!' : 'Usuário criado com sucesso!';
  document.getElementById('acesso-modal-status').textContent = '';
  document.getElementById('senha-provisoria-valor').textContent = data.senhaProvisoria;
  document.getElementById('senha-provisoria-email').textContent = data.colaborador.email;
  document.getElementById('senha-provisoria-painel').showModal();
}

function cancelarEdicao(){document.getElementById('colaborador-form-modal').close();formColaborador.reset();formColaborador.elements.id.value='';}
function abrirFormulario(usuario){
  formColaborador.reset();
  formColaborador.elements.id.value=usuario?usuario.id:'';
  document.getElementById('colaborador-form-titulo').textContent=usuario?'Editar usuário':'Criar usuário';
  document.getElementById('colaborador-form-ajuda').hidden=Boolean(usuario);
  document.getElementById('colaborador-form-erro').textContent='';
  if(usuario){formColaborador.elements.nome.value=usuario.nome;formColaborador.elements.email.value=usuario.email;formColaborador.elements.perfil.value=usuario.perfil;}
  document.getElementById('colaborador-form-modal').showModal();
  formColaborador.elements.nome.focus();
}
document.getElementById('criar-usuario').addEventListener('click',function(){abrirFormulario();});
function iconeAcao(button,label,paths){
  button.className='colaborador-icone';button.title=label;button.setAttribute('aria-label',label);
  button.innerHTML='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'+paths+'</svg>';
  var dica=document.createElement('span');dica.className='colaborador-dica';dica.textContent=label;button.appendChild(dica);
}
async function carregarColaboradores(){colaboradores=await adminRequest('/Colaboradores');var lista=document.getElementById('colaboradores-lista');lista.replaceChildren();
colaboradores.forEach(function(u){var item=document.createElement('article');item.className='colaborador-item';var info=document.createElement('div');var nome=document.createElement('h3');nome.textContent=u.nome;var perfil=document.createElement('span');perfil.className='colaborador-perfil '+(u.perfil==='Administrador'?'colaborador-perfil-admin':'colaborador-perfil-equipe');perfil.textContent=u.perfil;info.className='colaborador-identidade';info.append(nome,perfil);var acoes=document.createElement('div');acoes.className='colaborador-acoes';var editar=document.createElement('button');editar.type='button';editar.className='secondary-button';editar.textContent='Editar';editar.addEventListener('click',function(){abrirFormulario(u);});var excluir=document.createElement('button');excluir.type='button';excluir.className='secondary-button';excluir.textContent='Excluir';excluir.disabled=u.id===sessaoColaborador.id;excluir.addEventListener('click',async function(){if(!confirm('Excluir o acesso de '+u.nome+'?'))return;excluir.disabled=true;try{await adminRequest('/Colaboradores/'+u.id,{method:'DELETE'});mensagem('Acesso excluído.');await carregarColaboradores();}catch(err){mensagem(err.message);excluir.disabled=false;}});var resetar = document.createElement('button');
resetar.type = 'button';
resetar.className = 'secondary-button';
resetar.textContent = 'Resetar senha';
resetar.disabled = u.id === sessaoColaborador.id;
if (resetar.disabled) resetar.title = 'Peça a outro administrador para resetar sua senha.';
resetar.addEventListener('click', async function () {
  if (!confirm('Resetar a senha de ' + u.nome + '? A senha atual e as sessões anteriores deixarão de funcionar.')) return;
  resetar.disabled = true;
  mensagem('');
  limparSenha();
  try {
    var data = await adminRequest('/Colaboradores/' + u.id + '/resetar-senha', { method: 'POST' });
    mostrarSenhaProvisoria(data, true);
    await carregarColaboradores();
  } catch (err) {
    mensagem(err.message);
  } finally {
    resetar.disabled = false;
  }
});
iconeAcao(editar,'Editar usuário','<path d="m16 3 5 5-12 12-6 1 1-6Z"/><path d="m14 5 5 5"/>');
iconeAcao(resetar,'Resetar senha','<path d="M3 10a9 9 0 1 1 2 9"/><path d="M3 4v6h6"/><rect x="9" y="11" width="6" height="5" rx="1"/><path d="M10 11V9a2 2 0 0 1 4 0v2"/>');
iconeAcao(excluir,'Excluir usuário','<path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7M14 10v7"/>');
editar.classList.add('colaborador-icone-editar');
resetar.classList.add('colaborador-icone-resetar');
excluir.classList.add('colaborador-icone-excluir');
acoes.classList.add('colaborador-acoes-icones');
acoes.append(editar,resetar,excluir);item.append(info,acoes);lista.appendChild(item);});}
formColaborador.addEventListener('submit',async function(event){event.preventDefault();var button=formColaborador.querySelector('[type=submit]');button.disabled=true;mensagem('');limparSenha();var id=formColaborador.elements.id.value;var payload={nome:formColaborador.elements.nome.value.trim(),email:formColaborador.elements.email.value.trim(),perfil:formColaborador.elements.perfil.value};try{var data=await adminRequest('/Colaboradores'+(id?'/'+id:''),{method:id?'PUT':'POST',body:JSON.stringify(payload)});cancelarEdicao();if(!id){mostrarSenhaProvisoria(data, false);}else mensagem('Acesso atualizado. O usuário deverá entrar novamente.');if(Number(id)===sessaoColaborador.id){clearAdminSession();redirectToAdminLogin();return;}await carregarColaboradores();}catch(err){document.getElementById('colaborador-form-erro').textContent=err.message;mensagem(err.message);}finally{button.disabled=false;}});
document.getElementById('cancelar-edicao').addEventListener('click',cancelarEdicao);document.getElementById('fechar-senha').addEventListener('click',limparSenha);document.getElementById('copiar-senha').addEventListener('click',async function(){try{await navigator.clipboard.writeText(document.getElementById('senha-provisoria-valor').textContent);document.getElementById('acesso-modal-status').textContent='Senha copiada!';}catch(_){document.getElementById('acesso-modal-status').textContent='Selecione a senha exibida e copie manualmente.';}});
(async function(){if(!requireAdminSession())return;try{sessaoColaborador=await adminRequest('/Auth/sessao');if(sessaoColaborador.perfil!=='Administrador'){mensagem('Somente administradores podem gerenciar colaboradores.');return;}document.getElementById('colaboradores-conteudo').hidden=false;await carregarColaboradores();}catch(err){mensagem(err.message);}})();
