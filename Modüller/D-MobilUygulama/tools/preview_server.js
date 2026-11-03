const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');

const HTTP_PORT = 8080;
const HTTPS_PORT = 8443;

const BASE_DIR = path.resolve(__dirname, '..');
const WEB_APP_HTML = path.join(BASE_DIR, 'web_app', 'index.html');
const WIREFRAME_HTML = path.join(BASE_DIR, 'docs', 'wireframes', 'html', 'index.html');
const MARKERS_HTML = path.join(BASE_DIR, 'vision', 'markers', 'aruco_markers.html');

const CERT_KEY = path.join(__dirname, 'certs', 'key.pem');
const CERT_CRT = path.join(__dirname, 'certs', 'cert.pem');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

function getLocalIps() {
  const interfaces = os.networkInterfaces();
  const list = [];
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        list.push({ name, address: iface.address });
      }
    }
  }
  return list;
}

function handleRequest(req, res) {
  const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
  let pathname = decodeURIComponent(parsedUrl.pathname);

  let filePath;
  if (pathname === '/' || pathname === '/index.html' || pathname === '/app') {
    filePath = WEB_APP_HTML;
  } else if (pathname === '/wireframes' || pathname === '/docs') {
    filePath = WIREFRAME_HTML;
  } else if (pathname === '/markers' || pathname === '/aruco') {
    filePath = MARKERS_HTML;
  } else {
    const candidate1 = path.join(BASE_DIR, 'docs', 'wireframes', 'html', pathname);
    const candidate2 = path.join(BASE_DIR, pathname);

    if (fs.existsSync(candidate1) && fs.statSync(candidate1).isFile()) {
      filePath = candidate1;
    } else if (fs.existsSync(candidate2) && fs.statSync(candidate2).isFile()) {
      filePath = candidate2;
    } else {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('404 - Sayfa Bulunamadı');
      return;
    }
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('500 - Sunucu Hatası: ' + err.message);
      return;
    }
    res.writeHead(200, {
      'Content-Type': contentType,
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'no-cache',
    });
    res.end(data);
  });
}

// HTTP Sunucu
const httpServer = http.createServer(handleRequest);
httpServer.listen(HTTP_PORT, '0.0.0.0');

// HTTPS Sunucu (Kamera izinleri için Secure Context gereklidir)
let httpsServer = null;
if (fs.existsSync(CERT_KEY) && fs.existsSync(CERT_CRT)) {
  const options = {
    key: fs.readFileSync(CERT_KEY),
    cert: fs.readFileSync(CERT_CRT),
  };
  httpsServer = https.createServer(options, handleRequest);
  httpsServer.listen(HTTPS_PORT, '0.0.0.0');
}

const ipList = getLocalIps();
const primaryIp = (ipList.find(i => /wi-fi|wireless/i.test(i.name)) || ipList[0] || { address: 'localhost' }).address;

console.log('\n' + '='.repeat(68));
console.log('  🚀 YTÜ ÇDTP - Mobil Uygulama Canlı Önizleme Sunucusu');
console.log('='.repeat(68));
console.log('');
console.log('  🔒 KAMERA İÇİN HTTPS BAĞLANTISI (ÖNERİLEN - GÜVENLİ BAĞLAM):');
console.log(`     👉 https://${primaryIp}:${HTTPS_PORT}`);
console.log('     (Not: Tarayıcı "Gelişmiş -> Siteye İlerle" uyarısı verirse onaylayın)');
console.log('');
console.log('  📱 NORMAL HTTP BAĞLANTISI:');
console.log(`     👉 http://${primaryIp}:${HTTP_PORT}`);
console.log('');
console.log('  💻 BİLGİSAYARINIZDAN AÇMAK İÇİN:');
console.log(`     👉 http://localhost:${HTTP_PORT}`);
console.log('');
console.log('  Durdurmak için: Ctrl + C tuşlarına basın.');
console.log('='.repeat(68) + '\n');
