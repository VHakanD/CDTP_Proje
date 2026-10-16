/// Simülatör kontrol sayfası. Sayfa kendisi `/glove` kanalına bağlanır ve
/// eldiven ESP32-S3'ü gibi davranır.
///
/// Klavye / düğme: kısa bas = 0,5 m adım (ya da 90° dönüş); basılı tut =
/// sürekli sür; bırakınca yumuşak fren. Boşluk = dur.
const controlPageHtml = r'''<!DOCTYPE html>
<html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>ESP32-S3 Simülatörü</title>
<style>
:root{--bg:#151617;--sf:#1f2022;--ink:#e6e6e6;--mid:#a3a3a3;--line:#4a4a4a;--acc:#e040fb;--ok:#7bd88f;--warn:#ffb74d}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:13px/1.45 ui-monospace,Consolas,monospace}
main{max-width:1040px;margin:0 auto;padding:16px;display:grid;grid-template-columns:1fr 1fr;gap:16px}
@media(max-width:780px){main{grid-template-columns:1fr}}
h1{font-size:16px;margin:0} h2{font-size:12px;margin:0 0 8px;color:var(--mid);font-weight:400;text-transform:uppercase;letter-spacing:.06em}
section{background:var(--sf);border:1px solid var(--line);border-radius:6px;padding:12px;margin-bottom:12px}
a{color:var(--acc)}
.banner{grid-column:1/-1;display:flex;flex-wrap:wrap;gap:8px 20px;align-items:baseline;border:1px solid var(--line);border-radius:6px;padding:10px 12px}
.banner .muted{color:var(--mid)}
button{font:inherit;color:var(--ink);background:var(--bg);border:1px solid var(--line);border-radius:4px;padding:8px 10px;cursor:pointer;user-select:none;touch-action:none}
button:hover{border-color:var(--ink)} button:focus-visible{outline:2px solid #7ea2ff}
button.on{background:var(--acc);border-color:var(--acc);color:#000}
.pad{display:grid;grid-template-columns:repeat(3,76px);gap:6px}
.pad .stop{background:#5a1f1f}
.pad kbd{display:block;font-size:10px;color:var(--mid)} .pad button.on kbd{color:#000}
.row{display:flex;flex-wrap:wrap;gap:6px}
.pilot{display:grid;grid-template-columns:1fr 1fr;gap:6px} .pilot button{text-align:left}
.pilot button.run{border-color:var(--acc);color:var(--acc)}
.status{margin-top:8px;padding:6px 8px;border-radius:4px;background:var(--bg);min-height:2.2em}
.dot{display:inline-block;width:8px;height:8px;border-radius:50%;background:#c62828;margin-right:6px}
.dot.ok{background:var(--ok)}
dl{display:grid;grid-template-columns:auto 1fr;gap:2px 12px;margin:0} dt{color:var(--mid)} dd{margin:0}
.bar{height:6px;background:var(--bg);border-radius:3px;overflow:hidden;margin-top:3px}.bar i{display:block;height:100%;background:var(--ok)}
pre{margin:0;white-space:pre-wrap;color:var(--mid);font-size:12px;max-height:200px;overflow:auto}
canvas{width:100%;aspect-ratio:1;background:#0e0f10;border-radius:6px;display:block}
.hint{color:var(--mid);margin:8px 0 0}
</style></head><body><main>
<div class="banner">
  <h1>ESP32-S3 simülatörü · robot + eldiven</h1>
  <span class="muted">Bu sayfa <b>eldivendir</b>: robotu buradan sürersin.</span>
  <span>Uygulama (izleme): <a id="applink" target="_blank">localhost:8080</a></span>
  <span class="muted">uygulama adresi <b id="addr"></b></span>
</div>
<div>
<section><h2>Eldiven</h2>
<div class="pad">
<span></span><button data-c="forward">▲ ileri<kbd>W</kbd></button><span></span>
<button data-c="left">◀ sol<kbd>A</kbd></button><button class="stop" data-c="stop">■ dur<kbd>boşluk</kbd></button><button data-c="right">sağ ▶<kbd>D</kbd></button>
<span></span><button data-c="backward">▼ geri<kbd>S</kbd></button><span></span>
</div>
<p class="hint">Kısa bas = 0,5 m / 90°. Basılı tut = sürekli sür, bırak = fren.</p>
<div class="status"><span class="dot" id="gdot"></span>Eldiven: <b id="glove">bağlanıyor…</b></div>
</section>
<section><h2>Otomatik pilot</h2>
<div class="pilot" id="pilot"></div>
<div class="status" id="pstat">Pilot kapalı. Eldiven komutu pilotu durdurur.</div>
</section>
<section><h2>Arıza ve durum</h2><div class="row">
<button data-s="reset">Sıfırla</button><button data-s="drop_box">Kutuyu düşür</button>
<button data-s="push">İt (toparlanma)</button><button data-s="fall">Devir</button>
<button data-s="blackout_3s">3 s telemetri kesintisi</button><button data-s="flaky_wifi" id="wifi">Kötü Wi-Fi: kapalı</button>
<button data-s="toggle_visible">Robotu gizle/göster</button>
<button data-s="battery_low">Pil %19</button><button data-s="battery_full">Pil %100</button></div></section>
</div>
<div>
<section><h2>Sahne (sanal kamera)</h2><canvas id="cv" width="480" height="480"></canvas></section>
<section><h2>Robot durumu</h2><dl id="st"></dl></section>
<section><h2>Günlük</h2><pre id="log"></pre></section>
</div>
</main>
<script>
const host = location.host;
document.getElementById('addr').textContent = 'ws://' + host + '/ws';
const app = location.protocol + '//' + location.hostname + ':8080/';
const al = document.getElementById('applink'); al.href = app; al.textContent = app;

// ---- eldiven kanalı ----
let ws, seq = 0;
function connectGlove(){
  ws = new WebSocket('ws://' + host + '/glove');
  ws.onopen = () => { glove.textContent = 'bağlı'; gdot.className = 'dot ok'; };
  ws.onclose = () => { glove.textContent = 'koptu, yeniden deneniyor'; gdot.className = 'dot'; setTimeout(connectGlove, 1000); };
}
const glove = document.getElementById('glove'), gdot = document.getElementById('gdot');
connectGlove();
function cmd(c){ if (ws && ws.readyState === 1) ws.send(JSON.stringify({type:'glove_cmd', cmd:c, seq:++seq})); }

// ---- basılı tutma: kısa = adım, uzun = sürekli ----
const HOLD_MS = 300, REPEAT_MS = 200;
let held = null;
function mark(c, on){ const b = document.querySelector('[data-c="' + c + '"]'); if (b) b.classList.toggle('on', on); }
function press(c){
  if (held && held.cmd === c) return;
  release();
  cmd(c);
  const h = {cmd: c, t0: Date.now()};
  h.timer = setInterval(() => { if (Date.now() - h.t0 > HOLD_MS) cmd(c); }, REPEAT_MS);
  held = h; mark(c, true);
}
function release(){
  if (!held) return;
  clearInterval(held.timer);
  if (Date.now() - held.t0 > HOLD_MS && held.cmd !== 'stop') cmd('stop');
  mark(held.cmd, false); held = null;
}
document.querySelectorAll('[data-c]').forEach(b => {
  b.addEventListener('pointerdown', e => { e.preventDefault(); b.setPointerCapture(e.pointerId); press(b.dataset.c); });
  b.addEventListener('pointerup', release);
  b.addEventListener('pointercancel', release);
});
const keys = {KeyW:'forward', KeyS:'backward', KeyA:'left', KeyD:'right', Space:'stop',
              ArrowUp:'forward', ArrowDown:'backward', ArrowLeft:'left', ArrowRight:'right'};
addEventListener('keydown', e => { const c = keys[e.code]; if (!c) return; e.preventDefault(); if (!e.repeat) press(c); });
addEventListener('keyup', e => { const c = keys[e.code]; if (!c) return; e.preventDefault(); if (held && held.cmd === c) release(); });
addEventListener('blur', release);

// ---- senaryolar ----
const pilots = [['auto_A','A: 30 s denge'],['auto_B_forward','B: 1 m İLERİ'],['auto_B_backward','B: 1 m GERİ'],
  ['auto_B_left','B: SOL + 1 m'],['auto_B_right','B: SAĞ + 1 m'],['auto_C','C: istasyon + şarj'],
  ['auto_E','E: bütünleşik'],['auto_tour','Tur: A→B→C→E'],['wander','Serbest gezinti'],['auto_stop','■ Pilotu durdur']];
const pbox = document.getElementById('pilot');
pbox.innerHTML = pilots.map(p => '<button data-s="' + p[0] + '">' + p[1] + '</button>').join('');
document.querySelectorAll('[data-s]').forEach(b => b.onclick = () => fetch('/api/scenario?name=' + b.dataset.s));

// ---- sahne ----
const cv = document.getElementById('cv'), g = cv.getContext('2d'), W = 480;
const trail = [];
function toPx(x, y){ return [(0.5 + x * 0.25) * W, (0.8 - y * 0.25) * W]; }
function draw(s){
  g.clearRect(0,0,W,W); g.strokeStyle='rgba(255,255,255,.06)';
  for (let i=1;i<16;i++){ const p=i*W/16; g.beginPath(); g.moveTo(p,0); g.lineTo(p,W); g.moveTo(0,p); g.lineTo(W,p); g.stroke(); }
  // 1 m zemin işareti
  g.strokeStyle='#bbb'; g.lineWidth=3; g.beginPath(); g.moveTo(0.25*W,0.12*W); g.lineTo(0.5*W,0.12*W); g.stroke(); g.lineWidth=1;
  g.fillStyle='#888'; g.fillText('1 m', 0.36*W, 0.12*W - 6);
  // hedef / şarj bölgesi + istasyon
  const [zx, zy] = toPx(0, 1.2); g.setLineDash([5,4]); g.strokeStyle='#7bd88f'; g.strokeRect(zx-0.08*W, zy-0.06*W, 0.16*W, 0.12*W); g.setLineDash([]);
  const [sx, sy] = toPx(0, 1.32); g.fillStyle='#9e9e9e'; g.fillRect(sx-20, sy-7, 40, 14);
  // başlangıç
  const [ox, oy] = toPx(0, 0); g.strokeStyle='#555'; g.beginPath(); g.arc(ox, oy, 6, 0, 7); g.stroke();
  // iz
  g.strokeStyle='rgba(224,64,251,.35)'; g.beginPath();
  trail.forEach((p, i) => { const [x, y] = toPx(p[0], p[1]); i ? g.lineTo(x, y) : g.moveTo(x, y); }); g.stroke();
  if (!s.visible) { g.fillStyle='#ffb74d'; g.fillText('robot gizli (kamerada görünmüyor)', 10, W-10); return; }
  const [x, y] = toPx(s.x_m, s.y_m);
  g.save(); g.translate(x, y); g.rotate(s.heading_deg * Math.PI / 180);
  g.fillStyle = s.state === 'fallen' ? '#c62828' : '#bdbdbd'; g.fillRect(-14,-10,28,20);
  g.fillStyle='#333'; g.fillRect(-17,-8,3,16); g.fillRect(14,-8,3,16);
  g.fillStyle='#e040fb'; g.beginPath(); g.arc(0,-2,5,0,7); g.fill();
  if (s.box_present) { g.fillStyle='#4fc3f7'; g.fillRect(-6,3,12,6); }
  g.strokeStyle='#fff'; g.beginPath(); g.moveTo(0,-10); g.lineTo(0,-18); g.stroke(); g.restore();
}
function row(k, v){ return '<dt>' + k + '</dt><dd>' + v + '</dd>'; }
async function poll(){
  try {
    const s = await (await fetch('/api/state')).json();
    const last = trail[trail.length - 1];
    if (!last || Math.hypot(last[0]-s.x_m, last[1]-s.y_m) > 0.01) trail.push([s.x_m, s.y_m]);
    if (trail.length > 400 || (last && Math.hypot(last[0]-s.x_m, last[1]-s.y_m) > 0.3)) trail.splice(0, trail.length - 1);
    draw(s);
    const bc = s.battery_pct < 20 ? '#ef5350' : s.battery_pct < 40 ? '#ffb74d' : '#7bd88f';
    document.getElementById('st').innerHTML =
      row('Durum', '<b>' + s.state + '</b>') +
      row('Konum', s.x_m.toFixed(2) + ', ' + s.y_m.toFixed(2) + ' m · ' + s.heading_deg + '°') +
      row('Hız', (s.speed_mps || 0).toFixed(2) + ' m/s') +
      row('Eğim', s.tilt_deg.toFixed(1) + '°') +
      row('Pil', s.battery_pct.toFixed(1) + ' %' + (s.charging ? ' · şarj oluyor' : '') +
          '<div class="bar"><i style="width:' + s.battery_pct + '%;background:' + bc + '"></i></div>') +
      row('Dock', s.docked ? 'evet' : 'hayır') +
      row('Kutu', s.box_present ? 'yerinde' : '<b style="color:#ef5350">DÜŞTÜ</b>') +
      row('Uygulama', s.app_clients + ' bağlantı' + (s.blackout ? ' · <b>KESİNTİ</b>' : ''));
    document.getElementById('wifi').textContent = 'Kötü Wi-Fi: ' + (s.flaky_wifi ? 'AÇIK' : 'kapalı');
    document.getElementById('wifi').classList.toggle('on', !!s.flaky_wifi);
    document.getElementById('pstat').innerHTML = s.pilot
      ? '▶ <b>' + s.pilot + '</b> · ' + (s.pilot_step || '')
      : 'Pilot kapalı. Eldiven komutu pilotu durdurur.';
    pbox.querySelectorAll('button').forEach(b => b.classList.toggle('run', b.dataset.s === s.pilot));
    document.getElementById('log').textContent = s.log.join('\n');
  } catch (e) {}
  setTimeout(poll, 100);
}
poll();
</script></body></html>''';
