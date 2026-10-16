if(!sessionStorage.getItem('trocaSenhaToken'))window.location.replace('./admin-login.html');
document.getElementById('cancelar-troca').addEventListener('click',function(){sessionStorage.removeItem('trocaSenhaToken');});
document.getElementById('troca-form').addEventListener('submit',async function(event){
  event.preventDefault();var form=event.currentTarget;var error=document.getElementById('troca-erro');error.textContent='';
  if(form.elements.senha.value!==form.elements.confirmacao.value){error.textContent='As senhas não conferem.';return;}
  var button=form.querySelector('button');button.disabled=true;
  try{var response=await fetch(ADMIN_API_BASE_URL+'/Auth/trocar-senha',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+sessionStorage.getItem('trocaSenhaToken')},body:JSON.stringify({novaSenha:form.elements.senha.value,confirmacaoSenha:form.elements.confirmacao.value})});
    if(response.status===401||response.status===403){sessionStorage.removeItem('trocaSenhaToken');window.location.replace('./admin-login.html');return;}
    if(!response.ok){var text=await response.text();try{var problem=JSON.parse(text);text=problem.errors?Object.values(problem.errors).flat().join(' '):problem.title||text;}catch(_){}throw new Error(text);}
    salvarSessaoAdmin(await response.json());form.reset();window.location.href='./admin-dashboard.html';
  }catch(err){error.textContent=err.message;}finally{button.disabled=false;}
});
