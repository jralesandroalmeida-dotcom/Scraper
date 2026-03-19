<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>ML Scraper</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>
<style>
@import url('https://fonts.googleapis.com/css2?family=Sora:wght@400;600;700&family=JetBrains+Mono:wght@400;500&display=swap');
*{box-sizing:border-box;margin:0;padding:0}
:root{
  --y:#FFE600;--dark:#0D0E1A;--surf:#14152A;--card:#1A1C35;--card2:#1E2040;
  --text:#EEF0FF;--muted:#6B7499;--ok:#00C27A;--err:#FF4757;--warn:#FFB74D;
  --blue:#3483FA;--brd:rgba(255,255,255,0.06);--brd2:rgba(255,255,255,0.10);
}
html,body{height:100%;font-family:'Sora',sans-serif;background:var(--dark);color:var(--text);overflow:hidden}
body{display:flex;flex-direction:column}

/* HEADER */
header{padding:14px 24px 12px;border-bottom:1px solid var(--brd);flex-shrink:0;
  background:linear-gradient(135deg,#0D0E1A 0%,#14152A 60%,#1A1C35 100%);position:relative}
header::before{content:'';position:absolute;right:-40px;top:-40px;width:180px;height:180px;
  border-radius:50%;background:rgba(255,230,0,0.035);pointer-events:none}
.hrow{display:flex;align-items:center;gap:10px;margin-bottom:6px}
.badge{background:var(--y);color:#0D0E1A;font-size:9px;font-weight:700;padding:3px 9px;border-radius:5px;letter-spacing:.8px}
header h1{font-size:17px;font-weight:700}header h1 em{color:var(--y);font-style:normal}
header p{font-size:10.5px;color:var(--muted)}

/* LAYOUT */
.app{display:flex;flex:1;overflow:hidden}
.side{width:290px;flex-shrink:0;background:var(--surf);border-right:1px solid var(--brd);
  overflow-y:auto;padding:12px;display:flex;flex-direction:column;gap:9px}
.main{flex:1;overflow:auto;padding:14px 18px;display:flex;flex-direction:column;gap:12px}

/* CARDS */
.card{background:var(--card);border:1px solid var(--brd);border-radius:10px;padding:12px}
.sec{font-size:9px;font-weight:600;color:var(--muted);letter-spacing:1.4px;text-transform:uppercase;
  margin-bottom:8px;display:flex;align-items:center;justify-content:space-between}
.sec-line{flex:1;height:1px;background:var(--brd);margin-left:8px}

/* FORM */
.f{margin-bottom:8px}.f label{font-size:10px;color:var(--muted);display:block;margin-bottom:3px}
.f input,.f select{width:100%;background:rgba(255,255,255,0.04);border:1px solid var(--brd);
  border-radius:6px;padding:7px 10px;color:var(--text);font-family:'Sora',sans-serif;
  font-size:11.5px;outline:none;transition:border .15s}
.f input:focus,.f select:focus{border-color:rgba(255,230,0,.45)}
.f select option{background:#14152A}
.c2{display:grid;grid-template-columns:1fr 1fr;gap:7px}

/* TAGS */
.tags{display:flex;flex-wrap:wrap;gap:4px;margin:3px 0 6px}
.tag{background:rgba(52,131,250,.1);border:1px solid rgba(52,131,250,.22);color:#82B4FF;
  font-size:10px;padding:2px 7px;border-radius:20px;display:flex;align-items:center;gap:3px;
  font-family:'JetBrains Mono',monospace}
.tag .x{color:var(--err);cursor:pointer;font-size:12px;line-height:1}
.add-row{display:flex;gap:5px}.add-row input{flex:1}
.btn-plus{background:rgba(52,131,250,.1);border:1px solid rgba(52,131,250,.28);color:#82B4FF;
  padding:0 10px;border-radius:6px;cursor:pointer;font-size:18px;font-weight:300;flex-shrink:0;transition:.15s}
.btn-plus:hover{background:rgba(52,131,250,.22)}

/* BUTTONS */
.btn-row{display:flex;gap:7px}
#btn-run{flex:1;background:var(--y);color:#0D0E1A;border:none;border-radius:8px;padding:11px;
  font-family:'Sora',sans-serif;font-size:13px;font-weight:700;cursor:pointer;transition:.15s;
  display:flex;align-items:center;justify-content:center;gap:7px}
#btn-run:hover:not(:disabled){transform:translateY(-1px);box-shadow:0 6px 20px rgba(255,230,0,.2)}
#btn-run:disabled{opacity:.4;cursor:not-allowed;transform:none;box-shadow:none}
#btn-stop{background:rgba(255,71,87,.12);border:1px solid rgba(255,71,87,.3);color:var(--err);
  border-radius:8px;padding:11px 14px;font-family:'Sora',sans-serif;font-size:12px;font-weight:600;
  cursor:pointer;transition:.15s;display:none;align-items:center;gap:5px}
#btn-stop:hover{background:rgba(255,71,87,.22)}
#btn-stop.on{display:flex}

/* PROGRESS */
.scard{display:none}.scard.on{display:block}
.prog-label{font-size:11px;color:var(--muted);margin-bottom:5px;display:flex;align-items:center;justify-content:space-between}
.prog-label span{font-family:'JetBrains Mono',monospace;font-size:10px;color:var(--ok)}
.ptrack{background:rgba(255,255,255,.05);border-radius:100px;height:5px;overflow:hidden;margin-bottom:7px}
.pfill{height:100%;background:var(--y);border-radius:100px;transition:width .4s ease;width:0}

/* PRODUTO ATUAL */
.current-product{background:rgba(255,230,0,.05);border:1px solid rgba(255,230,0,.12);
  border-radius:8px;padding:8px 10px;margin-bottom:7px;display:none}
.current-product.on{display:block}
.cp-label{font-size:9px;color:var(--muted);letter-spacing:.8px;text-transform:uppercase;margin-bottom:3px}
.cp-name{font-size:12px;font-weight:600;color:var(--y);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.cp-meta{font-size:10px;color:var(--muted);margin-top:2px}

.log{background:rgba(0,0,0,.25);border-radius:6px;padding:7px 9px;
  font-family:'JetBrains Mono',monospace;font-size:9.5px;color:var(--muted);
  max-height:130px;overflow-y:auto;line-height:1.85}
.lok{color:var(--ok)}.lerr{color:var(--err)}.linfo{color:#82B4FF}.lwarn{color:var(--warn)}

/* SESSÕES */
.session-item{display:flex;align-items:center;justify-content:space-between;
  padding:7px 9px;background:rgba(255,255,255,.03);border-radius:6px;margin-bottom:4px;
  cursor:pointer;border:1px solid transparent;transition:.15s}
.session-item:hover{background:rgba(255,255,255,.06);border-color:var(--brd2)}
.sess-info{flex:1;min-width:0}
.sess-queries{font-size:11px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sess-meta{font-size:9.5px;color:var(--muted);margin-top:1px}
.sess-count{font-family:'JetBrains Mono',monospace;font-size:10px;color:var(--ok);flex-shrink:0;margin-left:8px}

#errmsg{display:none;border-radius:7px;padding:8px 11px;font-size:11px}
#errmsg.on{display:block;background:rgba(255,71,87,.09);border:1px solid rgba(255,71,87,.22);color:#ff8a9a}

/* MÉTRICAS */
.metrics{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;flex-shrink:0}
.metric{background:var(--card2);border-radius:8px;padding:10px 12px;border:1px solid var(--brd)}
.metric-label{font-size:9.5px;color:var(--muted);margin-bottom:4px;letter-spacing:.3px}
.metric-value{font-size:20px;font-weight:700;font-family:'JetBrains Mono',monospace}
.metric-value.yellow{color:var(--y)}
.metric-value.green{color:var(--ok)}
.metric-value.blue{color:#82B4FF}
.metric-value.orange{color:var(--warn)}

/* FILTROS */
.filters{display:flex;align-items:center;gap:8px;flex-wrap:wrap;flex-shrink:0}
.filter-input{background:rgba(255,255,255,.04);border:1px solid var(--brd);border-radius:6px;
  padding:6px 10px;color:var(--text);font-family:'Sora',sans-serif;font-size:11.5px;outline:none;
  transition:border .15s;width:180px}
.filter-input:focus{border-color:rgba(255,230,0,.4)}
.filter-select{background:rgba(255,255,255,.04);border:1px solid var(--brd);border-radius:6px;
  padding:6px 10px;color:var(--text);font-family:'Sora',sans-serif;font-size:11.5px;outline:none}
.filter-select option{background:#14152A}
.filter-check{display:flex;align-items:center;gap:5px;font-size:11.5px;color:var(--muted);cursor:pointer}
.filter-check input{accent-color:var(--ok);width:13px;height:13px}
.filter-sep{width:1px;height:20px;background:var(--brd2)}
.results-hdr{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px}
.results-hdr h2{font-size:14px;font-weight:600}
.ctag{background:rgba(0,194,122,.1);border:1px solid rgba(0,194,122,.2);color:var(--ok);
  font-size:10px;padding:2px 8px;border-radius:20px;font-family:'JetBrains Mono',monospace}
.export-btns{display:flex;gap:6px}
.btn-exp{border:none;border-radius:6px;padding:6px 13px;font-family:'Sora',sans-serif;
  font-size:11.5px;font-weight:600;cursor:pointer;transition:.15s;display:flex;align-items:center;gap:5px}
.btn-exp.xl{background:var(--ok);color:#051A0E}.btn-exp.xl:hover{opacity:.85}
.btn-exp.csv{background:rgba(52,131,250,.15);border:1px solid rgba(52,131,250,.3);color:#82B4FF}
.btn-exp.csv:hover{background:rgba(52,131,250,.25)}
.btn-exp.js{background:rgba(255,183,77,.12);border:1px solid rgba(255,183,77,.3);color:var(--warn)}
.btn-exp.js:hover{background:rgba(255,183,77,.22)}

/* TABELA */
.tw{overflow-x:auto;border:1px solid var(--brd);border-radius:9px;flex:1}
table{width:100%;border-collapse:collapse;font-size:11px;min-width:740px}
thead{position:sticky;top:0;z-index:2}
th{background:#14152A;color:var(--muted);font-size:9px;font-weight:600;letter-spacing:.7px;
  text-transform:uppercase;padding:8px 11px;text-align:left;white-space:nowrap;
  border-bottom:1px solid var(--brd);cursor:pointer;user-select:none}
th:hover{color:var(--text)}
th .sort-arrow{margin-left:3px;opacity:.4}
th.sorted .sort-arrow{opacity:1;color:var(--y)}
td{padding:7px 11px;border-bottom:1px solid rgba(255,255,255,.02);vertical-align:top}
tr:last-child td{border-bottom:none}
tr:hover td{background:rgba(255,255,255,.02);cursor:pointer}
.cn{font-weight:500;max-width:170px;line-height:1.35}
.cp2{color:var(--y);font-weight:600;white-space:nowrap;font-family:'JetBrains Mono',monospace}
.cs{color:#82B4FF;font-size:10.5px}.cf{color:var(--ok);font-size:10.5px}
.cl a{color:var(--blue);text-decoration:none;font-size:10px}.cl a:hover{text-decoration:underline}
.pill{display:inline-flex;align-items:center;gap:2px;font-size:8.5px;padding:1px 6px;border-radius:20px;margin-bottom:2px}
.pok{background:rgba(0,194,122,.1);color:var(--ok);border:1px solid rgba(0,194,122,.18)}
.pno{background:rgba(255,71,87,.07);color:var(--err);border:1px solid rgba(255,71,87,.16)}

/* EMPTY */
.empty{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;
  text-align:center;padding:60px;color:var(--muted)}
.empty .ico{font-size:42px;margin-bottom:12px;opacity:.25}
.empty p{font-size:12px;line-height:1.7;max-width:240px}

/* MODAL */
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.7);z-index:100;
  display:none;align-items:center;justify-content:center;padding:20px}
.modal-overlay.on{display:flex}
.modal{background:var(--card);border:1px solid var(--brd2);border-radius:12px;
  width:min(700px,100%);max-height:85vh;overflow:hidden;display:flex;flex-direction:column}
.modal-header{padding:14px 16px;border-bottom:1px solid var(--brd);display:flex;align-items:flex-start;justify-content:space-between;gap:12px}
.modal-title{font-size:14px;font-weight:600;line-height:1.4;flex:1}
.modal-close{background:none;border:none;color:var(--muted);font-size:20px;cursor:pointer;
  padding:0;line-height:1;flex-shrink:0}
.modal-close:hover{color:var(--text)}
.modal-body{overflow-y:auto;padding:14px 16px;display:flex;flex-direction:column;gap:14px}
.modal-section{font-size:10px;font-weight:600;color:var(--muted);letter-spacing:1px;
  text-transform:uppercase;margin-bottom:6px}
.modal-price{font-size:22px;font-weight:700;color:var(--y);font-family:'JetBrains Mono',monospace}
.modal-meta{display:flex;gap:16px;flex-wrap:wrap}
.modal-meta-item{font-size:11.5px;color:var(--muted)}
.modal-meta-item strong{color:var(--text)}
.modal-specs{display:grid;grid-template-columns:1fr 1fr;gap:4px}
.spec-row{background:rgba(255,255,255,.03);border-radius:4px;padding:5px 8px;font-size:11px}
.spec-key{color:var(--muted);font-size:10px;margin-bottom:1px}
.spec-val{color:var(--text);font-weight:500}
.modal-desc{font-size:12px;color:var(--muted);line-height:1.7;white-space:pre-wrap}
.modal-imgs{display:flex;gap:8px;flex-wrap:wrap}
.modal-img{width:72px;height:72px;object-fit:cover;border-radius:6px;border:1px solid var(--brd);cursor:pointer;transition:.15s}
.modal-img:hover{border-color:var(--y);transform:scale(1.05)}
.modal-img-big{position:fixed;inset:0;background:rgba(0,0,0,.9);z-index:200;display:none;
  align-items:center;justify-content:center;cursor:pointer}
.modal-img-big.on{display:flex}
.modal-img-big img{max-width:90vw;max-height:90vh;border-radius:8px}

.spin{width:13px;height:13px;border:2px solid rgba(13,14,26,.4);border-top-color:#0D0E1A;
  border-radius:50%;display:inline-block;animation:sp .6s linear infinite}
@keyframes sp{to{transform:rotate(360deg)}}
</style>
</head>
<body>

<header>
  <div class="hrow"><span class="badge">ML SCRAPER</span></div>
  <h1>Mercado Livre <em>em 1 clique</em></h1>
  <p>Configure os termos e aperte o botão.</p>
</header>

<div class="app">
<aside class="side">

  <div class="card">
    <div class="sec">Configuração <span class="sec-line"></span></div>
    <div class="c2">
      <div class="f">
        <label>País</label>
        <select id="country">
          <option value="BR" selected>🇧🇷 Brasil</option>
          <option value="MX">🇲🇽 México</option>
          <option value="AR">🇦🇷 Argentina</option>
          <option value="CO">🇨🇴 Colômbia</option>
          <option value="CL">🇨🇱 Chile</option>
        </select>
      </div>
      <div class="f">
        <label>Máx. produtos</label>
        <input type="number" id="max" value="15" min="1" max="50" />
      </div>
    </div>
  </div>

  <div class="card">
    <div class="sec">Termos de busca <span class="sec-line"></span></div>
    <div class="tags" id="tags"></div>
    <div class="add-row">
      <input type="text" id="nq" placeholder='"retentor 40x60x10"' />
      <button class="btn-plus" onclick="addQ()">+</button>
    </div>
  </div>

  <div class="btn-row">
    <button id="btn-run" onclick="start()">⚡ RASPAR AGORA</button>
    <button id="btn-stop" onclick="stop()">⏹ Parar</button>
  </div>
  <div id="errmsg"></div>

  <div class="card scard" id="scard">
    <div class="sec">Progresso <span class="sec-line"></span><span id="prog-count" style="font-size:10px;color:var(--ok);font-family:'JetBrains Mono',monospace"></span></div>
    <div class="current-product" id="cur-prod">
      <div class="cp-label">Raspando agora</div>
      <div class="cp-name" id="cur-name">—</div>
      <div class="cp-meta" id="cur-meta"></div>
    </div>
    <div class="prog-label"><span id="slabel">Iniciando...</span></div>
    <div class="ptrack"><div class="pfill" id="pbar"></div></div>
    <div class="log" id="log"></div>
  </div>

  <div class="card" id="sessions-card" style="display:none">
    <div class="sec">Sessões salvas <span class="sec-line"></span></div>
    <div id="sessions-list"></div>
  </div>


  <div class="card" id="cache-card">
    <div class="sec">Cache de IDs <span class="sec-line"></span>
      <button onclick="clearCache()" style="background:none;border:none;color:var(--err);font-size:10px;cursor:pointer;font-family:Sora,sans-serif;padding:0;margin-left:6px">Limpar</button>
    </div>
    <div id="cache-info" style="font-size:11px;color:var(--muted);line-height:1.7">
      Carregando...
    </div>
  </div>

</aside>

<main class="main" id="main-area">
  <div class="empty" id="empty-state">
    <div class="ico">🛒</div>
    <p>Configure os termos de busca ao lado e clique em <strong>Raspar Agora</strong>.<br><br>Uma janela vai abrir e navegar no ML automaticamente.</p>
  </div>
</main>
</div>

<!-- MODAL PRODUTO -->
<div class="modal-overlay" id="modal-overlay" onclick="closeModal(event)">
  <div class="modal" onclick="event.stopPropagation()">
    <div class="modal-header">
      <div class="modal-title" id="m-title"></div>
      <button class="modal-close" onclick="closeModal()">×</button>
    </div>
    <div class="modal-body">
      <div>
        <div class="modal-price" id="m-price"></div>
        <div class="modal-meta" id="m-meta"></div>
      </div>
      <div id="m-imgs-section" style="display:none">
        <div class="modal-section">Imagens</div>
        <div class="modal-imgs" id="m-imgs"></div>
      </div>
      <div id="m-specs-section" style="display:none">
        <div class="modal-section">Especificações técnicas</div>
        <div class="modal-specs" id="m-specs"></div>
      </div>
      <div id="m-desc-section" style="display:none">
        <div class="modal-section">Descrição completa</div>
        <div class="modal-desc" id="m-desc"></div>
      </div>
      <div>
        <a id="m-link" href="#" target="_blank" style="font-size:12px;color:var(--blue)">Ver no Mercado Livre ↗</a>
      </div>
    </div>
  </div>
</div>
<div class="modal-img-big" id="img-big" onclick="this.classList.remove('on')">
  <img id="img-big-src" src="" />
</div>

<script>
let queries=['retentor'], allProducts=[], filtered=[], running=false, currentJobId=null;
let sortCol=null, sortDir=1;

// ── Init ─────────────────────────────────────────────
window.onload = () => { renderTags(); loadSessions(); };

// ── Tags ─────────────────────────────────────────────
function renderTags(){
  document.getElementById('tags').innerHTML=queries.map((q,i)=>
    `<div class="tag">${q}<span class="x" onclick="rmQ(${i})">×</span></div>`).join('');
}
function addQ(){const el=document.getElementById('nq'),v=el.value.trim();
  if(v&&!queries.includes(v)){queries.push(v);renderTags();}el.value='';el.focus();}
function rmQ(i){queries.splice(i,1);renderTags();}
document.getElementById('nq').addEventListener('keydown',e=>{if(e.key==='Enter')addQ();});

// ── Log / Progress ────────────────────────────────────
function log(msg,cls=''){
  const b=document.getElementById('log');
  const s=document.createElement('span');s.className='l'+cls;s.textContent='› '+msg+'\n';
  b.appendChild(s);b.scrollTop=b.scrollHeight;
}
function setProg(pct,label,current,total_links){
  document.getElementById('pbar').style.width=Math.min(pct,100)+'%';
  document.getElementById('slabel').textContent=label;
  if(current&&total_links){
    document.getElementById('prog-count').textContent=`${current}/${total_links}`;
  }
}
function showErr(m){const e=document.getElementById('errmsg');e.textContent='❌ '+m;e.classList.add('on');}
function hideErr(){document.getElementById('errmsg').classList.remove('on');}

// ── Scrape ────────────────────────────────────────────
async function start(){
  if(running)return;
  const max=parseInt(document.getElementById('max').value)||15;
  const country=document.getElementById('country').value;
  if(!queries.length){showErr('Adicione ao menos um termo.');return;}
  running=true;allProducts=[];filtered=[];hideErr();
  document.getElementById('scard').classList.add('on');
  document.getElementById('log').innerHTML='';
  document.getElementById('cur-prod').classList.add('on');
  setProg(0,'Abrindo browser...');
  renderMain(null);
  const btn=document.getElementById('btn-run');
  btn.disabled=true;btn.innerHTML='<span class="spin"></span> RASPANDO...';
  document.getElementById('btn-stop').classList.add('on');

  try{
    const resp=await fetch('/api/scrape',{method:'POST',headers:{'Content-Type':'application/json'},
      body:JSON.stringify({queries,maxItems:max,country})});
    const body=await resp.json();
    if(body.error)throw new Error(body.error);
    currentJobId=body.jobId;

    await new Promise((resolve,reject)=>{
      const es=new EventSource(`/api/stream/${currentJobId}`);
      es.onmessage=e=>{
        try{
          const d=JSON.parse(e.data);
          if(d.type==='progress'){
            const p=JSON.parse(d.msg);
            setProg(p.pct,p.label,p.current,p.total_links);
            if(p.query) document.getElementById('cur-meta').textContent=`Busca: "${p.query}"`;
          } else if(d.type==='product'){
            const p=JSON.parse(d.msg);
            document.getElementById('cur-name').textContent=p.name;
            document.getElementById('cur-meta').textContent=`${p.price||''}  Specs:${p.specs?'✓':'✗'}  Desc:${p.desc?'✓':'✗'}`;
          } else if(d.type==='done'){
            const p=JSON.parse(d.msg);
            setProg(100,p.label);
            log(`Concluído: ${p.total} produtos`,'ok');
            es.close();resolve();
          } else {
            log(d.msg,d.type==='ok'?'ok':d.type==='err'?'err':d.type==='info'?'info':d.type==='warn'?'warn':'');
          }
        }catch{log(e.data);}
      };
      es.onerror=()=>{es.close();reject(new Error('Conexão perdida.'));};
    });

    const res=await fetch(`/api/results/${currentJobId}`);
    allProducts=await res.json();
    filtered=[...allProducts];
    renderMain(filtered);
    loadSessions();
    loadCacheStats();
  }catch(e){showErr(e.message);log('Falha: '+e.message,'err');setProg(0,'Erro');}
  finally{
    running=false;
    btn.disabled=false;btn.innerHTML='⚡ RASPAR NOVAMENTE';
    document.getElementById('btn-stop').classList.remove('on');
    document.getElementById('cur-prod').classList.remove('on');
  }
}

async function stop(){
  if(!currentJobId)return;
  await fetch(`/api/cancel/${currentJobId}`,{method:'POST'});
  log('Cancelamento solicitado...','warn');
}

// ── Sessions ──────────────────────────────────────────
async function loadSessions(){
  const r=await fetch('/api/sessions');
  const sessions=await r.json();
  const card=document.getElementById('sessions-card');
  const list=document.getElementById('sessions-list');
  if(!sessions.length){card.style.display='none';return;}
  card.style.display='block';
  list.innerHTML=sessions.map(s=>`
    <div class="session-item" onclick="loadSession('${s.id}')">
      <div class="sess-info">
        <div class="sess-queries">${s.queries.join(', ')}</div>
        <div class="sess-meta">${s.timestamp} · ${s.country}</div>
      </div>
      <div class="sess-count">${s.total}</div>
    </div>`).join('');
}

async function loadSession(id){
  const r=await fetch(`/api/results/${id}`);
  allProducts=await r.json();
  filtered=[...allProducts];
  currentJobId=id;
  renderMain(filtered);
}

// ── Filtros & Ordenação ────────────────────────────────
function applyFilters(){
  const search=(document.getElementById('f-search')||{value:''}).value.toLowerCase();
  const order=(document.getElementById('f-order')||{value:''}).value;
  const freeOnly=(document.getElementById('f-free')||{checked:false}).checked;
  const specsOnly=(document.getElementById('f-specs')||{checked:false}).checked;

  filtered=allProducts.filter(p=>{
    if(search && !(p['Nome do Produto']||'').toLowerCase().includes(search)) return false;
    if(freeOnly && !(p['Frete']||'').toLowerCase().includes('grátis')) return false;
    if(specsOnly && !p['Especificações Técnicas']) return false;
    return true;
  });

  if(order==='asc'||order==='desc'){
    filtered.sort((a,b)=>{
      const pa=parseFloat((a['Preço Atual']||'0').replace(/[^\d,]/g,'').replace(',','.')) || 0;
      const pb=parseFloat((b['Preço Atual']||'0').replace(/[^\d,]/g,'').replace(',','.')) || 0;
      return order==='asc'?pa-pb:pb-pa;
    });
  }

  if(sortCol!==null) applySort(filtered);
  renderTable(filtered);
  updateMetrics(filtered);
  document.getElementById('res-count').textContent=`${filtered.length} produto${filtered.length!==1?'s':''}`;
}

function sortBy(col){
  if(sortCol===col) sortDir*=-1; else {sortCol=col;sortDir=1;}
  applySort(filtered);
  renderTable(filtered);
  // Atualiza arrows
  document.querySelectorAll('th').forEach(th=>{
    th.classList.remove('sorted');
    th.querySelector('.sort-arrow').textContent=' ↕';
  });
  const th=document.querySelector(`th[data-col="${col}"]`);
  if(th){th.classList.add('sorted');th.querySelector('.sort-arrow').textContent=sortDir===1?' ↑':' ↓';}
}

function applySort(arr){
  const keys=['Nome do Produto','Preço Atual','Vendedor','Frete','Avaliações'];
  const key=keys[sortCol]||'Nome do Produto';
  arr.sort((a,b)=>{
    let va=a[key]||'', vb=b[key]||'';
    if(key==='Preço Atual'){
      va=parseFloat(va.replace(/[^\d,]/g,'').replace(',','.')) || 0;
      vb=parseFloat(vb.replace(/[^\d,]/g,'').replace(',','.')) || 0;
      return (va-vb)*sortDir;
    }
    return va.localeCompare(vb)*sortDir;
  });
}

// ── Métricas ──────────────────────────────────────────
function updateMetrics(prods){
  const prices=prods.map(p=>parseFloat((p['Preço Atual']||'').replace(/[^\d,]/g,'').replace(',','.')) || 0).filter(p=>p>0);
  const avgPrice=prices.length?prices.reduce((a,b)=>a+b,0)/prices.length:0;
  const pctSpecs=prods.length?Math.round(prods.filter(p=>p['Especificações Técnicas']).length/prods.length*100):0;
  const pctDesc=prods.length?Math.round(prods.filter(p=>p['Descrição Completa']).length/prods.length*100):0;

  document.getElementById('m-total').textContent=prods.length;
  document.getElementById('m-price').textContent=avgPrice?'R$ '+avgPrice.toLocaleString('pt-BR',{maximumFractionDigits:0}):'—';
  document.getElementById('m-specs').textContent=pctSpecs+'%';
  document.getElementById('m-desc').textContent=pctDesc+'%';
}

// ── Render ────────────────────────────────────────────
function renderMain(products){
  const area=document.getElementById('main-area');
  if(!products||!products.length){
    area.innerHTML=`<div class="empty" id="empty-state"><div class="ico">🛒</div><p>Configure os termos de busca ao lado e clique em <strong>Raspar Agora</strong>.</p></div>`;
    return;
  }

  area.innerHTML=`
    <div class="metrics">
      <div class="metric"><div class="metric-label">Produtos</div><div class="metric-value yellow" id="m-total">${products.length}</div></div>
      <div class="metric"><div class="metric-label">Preço médio</div><div class="metric-value blue" id="m-price">—</div></div>
      <div class="metric"><div class="metric-label">Com specs</div><div class="metric-value green" id="m-specs">0%</div></div>
      <div class="metric"><div class="metric-label">Com descrição</div><div class="metric-value orange" id="m-desc">0%</div></div>
    </div>
    <div class="filters">
      <input class="filter-input" id="f-search" placeholder="🔍 Buscar por nome..." oninput="applyFilters()" />
      <select class="filter-select" id="f-order" onchange="applyFilters()">
        <option value="">Ordenar por...</option>
        <option value="asc">Preço: menor → maior</option>
        <option value="desc">Preço: maior → menor</option>
      </select>
      <label class="filter-check"><input type="checkbox" id="f-free" onchange="applyFilters()" /> Frete grátis</label>
      <label class="filter-check"><input type="checkbox" id="f-specs" onchange="applyFilters()" /> Com specs</label>
      <div class="filter-sep"></div>
      <span style="font-size:11px;color:var(--muted)" id="res-count"></span>
    </div>
    <div class="results-hdr">
      <h2>Resultados</h2>
      <div class="export-btns">
        <button class="btn-exp xl" onclick="dlExcel()">⬇ Excel</button>
        <button class="btn-exp csv" onclick="dlCSV()">⬇ CSV</button>
        <button class="btn-exp js" onclick="dlJSON()">⬇ JSON</button>
      </div>
    </div>
    <div class="tw" id="table-wrap"></div>`;

  updateMetrics(products);
  renderTable(products);
  document.getElementById('res-count').textContent=`${products.length} produtos`;
}

function renderTable(products){
  const wrap=document.getElementById('table-wrap');
  if(!wrap)return;
  const COLS=['Nome do Produto','Preço Atual','Vendedor','Frete','Avaliações'];
  const rows=products.map((p,idx)=>{
    const hs=!!p['Especificações Técnicas'],hd=!!p['Descrição Completa'];
    const nome=(p['Nome do Produto']||'').slice(0,55);
    const link=p['URL do Produto'];
    return `<tr onclick="openModal(${allProducts.indexOf(p)})">
      <td class="cn">${nome}${(p['Nome do Produto']||'').length>55?'…':''}</td>
      <td class="cp2">${p['Preço Atual']||'—'}</td>
      <td class="cs">${(p['Vendedor']||'').slice(0,20)||'—'}</td>
      <td class="cf">${p['Frete']||'—'}</td>
      <td class="cs">${p['Avaliações']||'—'}</td>
      <td>
        <div><span class="pill ${hs?'pok':'pno'}">${hs?'✓':'✗'} Specs</span></div>
        <div><span class="pill ${hd?'pok':'pno'}">${hd?'✓':'✗'} Desc</span></div>
      </td>
      <td class="cl" onclick="event.stopPropagation()">${link?`<a href="${link}" target="_blank">↗</a>`:'—'}</td>
    </tr>`;
  }).join('');

  wrap.innerHTML=`<table>
    <thead><tr>
      ${COLS.map((c,i)=>`<th data-col="${i}" onclick="sortBy(${i})">${c}<span class="sort-arrow"> ↕</span></th>`).join('')}
      <th>Dados</th><th>Link</th>
    </tr></thead>
    <tbody>${rows}</tbody>
  </table>`;
}

// ── Modal ─────────────────────────────────────────────
function openModal(idx){
  const p=allProducts[idx];
  if(!p)return;
  document.getElementById('m-title').textContent=p['Nome do Produto']||'';
  document.getElementById('m-price').textContent=p['Preço Atual']||'—';
  document.getElementById('m-link').href=p['URL do Produto']||'#';

  // Meta
  const meta=[];
  if(p['Vendedor']) meta.push(`<div class="modal-meta-item"><strong>${p['Vendedor']}</strong></div>`);
  if(p['Avaliações']) meta.push(`<div class="modal-meta-item">${p['Avaliações']}</div>`);
  if(p['Frete']) meta.push(`<div class="modal-meta-item" style="color:var(--ok)">${p['Frete']}</div>`);
  if(p['Quantidade de Vendas']) meta.push(`<div class="modal-meta-item">${p['Quantidade de Vendas']}</div>`);
  document.getElementById('m-meta').innerHTML=meta.join('');

  // Imagens
  const imgs=(p['URLs das Imagens']||'').split(' | ').filter(Boolean);
  if(imgs.length){
    document.getElementById('m-imgs-section').style.display='block';
    document.getElementById('m-imgs').innerHTML=imgs.slice(0,12).map(u=>
      `<img class="modal-img" src="${u}" onclick="bigImg('${u}')" loading="lazy" />`).join('');
  } else {
    document.getElementById('m-imgs-section').style.display='none';
  }

  // Specs
  const specs=(p['Especificações Técnicas']||'').split('\n').filter(Boolean);
  if(specs.length){
    document.getElementById('m-specs-section').style.display='block';
    document.getElementById('m-specs').innerHTML=specs.map(s=>{
      const [k,...v]=s.split(':');
      return `<div class="spec-row"><div class="spec-key">${k.trim()}</div><div class="spec-val">${v.join(':').trim()||'—'}</div></div>`;
    }).join('');
  } else {
    document.getElementById('m-specs-section').style.display='none';
  }

  // Descrição
  const desc=p['Descrição Completa']||'';
  if(desc){
    document.getElementById('m-desc-section').style.display='block';
    document.getElementById('m-desc').textContent=desc.slice(0,2000)+(desc.length>2000?'\n…':'');
  } else {
    document.getElementById('m-desc-section').style.display='none';
  }

  document.getElementById('modal-overlay').classList.add('on');
}

function closeModal(e){
  if(!e||e.target===document.getElementById('modal-overlay'))
    document.getElementById('modal-overlay').classList.remove('on');
}

function bigImg(src){
  document.getElementById('img-big-src').src=src;
  document.getElementById('img-big').classList.add('on');
}

document.addEventListener('keydown',e=>{if(e.key==='Escape'){
  document.getElementById('modal-overlay').classList.remove('on');
  document.getElementById('img-big').classList.remove('on');
}});

// ── Exports ───────────────────────────────────────────
async function dlExcel(){
  if(!currentJobId)return;
  const r=await fetch(`/api/excel/${currentJobId}`);
  if(!r.ok){alert('Sem dados.');return;}
  const blob=await r.blob();dl(blob,'mercadolivre_'+today()+'.xlsx');
}

async function dlCSV(){
  if(!currentJobId)return;
  const r=await fetch(`/api/csv/${currentJobId}`);
  if(!r.ok){alert('Sem dados.');return;}
  const blob=await r.blob();dl(blob,'mercadolivre_'+today()+'.csv');
}

function dlJSON(){
  if(!filtered.length)return;
  const blob=new Blob([JSON.stringify(filtered,null,2)],{type:'application/json'});
  dl(blob,'mercadolivre_'+today()+'.json');
}

function dl(blob,name){
  const url=URL.createObjectURL(blob);const a=document.createElement('a');
  a.href=url;a.download=name;a.click();URL.revokeObjectURL(url);
}

function today(){return new Date().toISOString().slice(0,10);}


async function loadCacheStats(){
  try{
    const r=await fetch('/api/cache/stats');
    const d=await r.json();
    const el=document.getElementById('cache-info');
    if(d.total===0){
      el.innerHTML='Nenhum produto no cache ainda.';
    } else {
      el.innerHTML=`<span style="color:var(--ok);font-weight:600">${d.total}</span> produto(s) já raspados.<br><span style="font-size:10px">Eles serão pulados automaticamente nas próximas buscas.</span>`;
    }
  }catch{}
}

async function clearCache(){
  if(!confirm('Limpar o cache? Todos os produtos serão raspados novamente nas próximas buscas.'))return;
  await fetch('/api/cache/clear',{method:'POST'});
  loadCacheStats();
  log('Cache limpo.','warn');
}

renderTags();
loadCacheStats();
</script>
</body>
</html>
