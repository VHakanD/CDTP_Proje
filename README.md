# CDTP_Proje — İki Tekerlekli Ev İçi Hasta Destek Robotu

YTÜ Elektrik-Elektronik Fakültesi · Çok Disiplinli Tasarım Projesi (ÇDTP) · 2026-2027 Güz

## Proje ne için yapılıyor?

Evde bakım gören veya hareket kabiliyeti kısıtlı bireylere, önceden hazırlanmış küçük ve güvenli ilaç paketlerini ev içinde ulaştıran bir destek robotu.

Kendi dengesini aktif olarak sağlayan **iki tekerlekli robot**, bir ilaç (aspirin vb.) kutusunu **giyilebilir eldiven** komutlarıyla hedef noktaya taşır; görev sonunda **otomatik şarj istasyonuna** gider ve insan müdahalesi olmadan şarjı başlatır. **Akıllı telefon uygulaması** görevi telefonun kamerasıyla izler ve sonuç raporu üretir.

- **Robot ne yapar?** Kapalı bir ilaç kutusunu evin bir noktasından diğerine güvenle taşır, görev bitince kendi kendine şarja gider.
### Dört adımda bir görev
1. **Dengede kal** — iki teker üzerinde aktif denge
2. **Kutuyu taşı** — eldiven komutlarıyla hedefe
3. **Şarja yerleş** — istasyonu IR ile bulur, şarj kendiliğinden başlar
4. **Ölç ve raporla** — telefon kamerasıyla geçti / kaldı

### Değişmez kurallar (özet)
- Yalnız iki teker; üçüncü teker / ayak / zemine değen destek yok
- Aktif denge: motorlar enerjisizken ±10°'den bırakılınca 5 s içinde kendiliğinden dik durmamalı
- Ana besleme en fazla **24 V DC**; şarjda elle kablo takılmaz
- Zorunlu güvenlik: acil durdurma / ana güç kesme, BMS'li lityum paket, motor hattında sigorta
- Hazır denge robotu kiti yasak; genel amaçlı parçalar serbest
- Final değerlendirmesi başladıktan sonra firmware, parametre, mekanik ve kablolama değiştirilemez

Ayrıntılar: [`ProjeTanımSunum/`](ProjeTanımSunum/) (TR/EN teknik şartname v14 + tanıtım sunumu)

## Modüller

| Kod | Modül | Açıklama | Sorumlu bölüm | Puan | Klasör |
| --- | --- | --- | --- | --- | --- |
| A | Denge robotu | İki teker üzerinde aktif denge, ileri/geri/dönüş, ±10°'den toparlanma | Kontrol ve Otomasyon | Ö1 · 20 | [A-DengeRobotu](Modüller/A-DengeRobotu/) |
| B | Giyilebilir komut arayüzü | Eldivenle 5 kablosuz komut: ileri, geri, sol, sağ, dur | Elektronik ve Haberleşme | Ö2 · 20 | [B-GiyilebilirEldiven](Modüller/B-GiyilebilirEldiven/) |
| C | Otomatik şarj istasyonu | IR ile otonom yerleşme, 5 s içinde otomatik şarj, donanımsal gösterge | Elektrik | Ö3 · 20 | [C-SarjIstasyonu](Modüller/C-SarjIstasyonu/) |
| D | Mobil izleme ve değerlendirme | 1 Hz şarj+eğim telemetri, kamerayla hareket/yön takibi, değiştirilemez rapor | Bilgisayar | Ö4 · 20 | [D-MobilUygulama](Modüller/D-MobilUygulama/) |
| E | İlaç kutusu taşıma | Kutuyu düşürmeden hedefe ulaştırma, bütünleşik görev ×4 | Ortak | Ö5 · 20 | [E-IlacKutusuTasima](Modüller/E-IlacKutusuTasima/) |

Her alt test **geçti = 5 / kaldı = 0**, toplam 100 puan.

### Sistem bağlantıları
```
Kullanıcı ──(el/kol hareketi)──► Eldiven [B] ──(kablosuz komut)──► Denge Robotu [A+E] ◄──(IR)──► Şarj İstasyonu [C]
                                                                     ▲      │
                                                     kamera takibi   │      │ 1 Hz telemetri (şarj + eğim)
                                                                     │      ▼
                                                              Akıllı Telefon [D] ──► Sonuç raporu (geçti/kaldı)
```

## Ekip

| Bölüm | Kişi sayısı | Ana modül | İsimler |
| --- | --- | --- | --- |
| Bilgisayar Müh. | 2 | D | _isim ekle_ |
| Elektronik ve Haberleşme Müh. | 2 | B | _isim ekle_ |
| Kontrol ve Otomasyon Müh. | 2 | A (+E) | _isim ekle_ |
| Elektrik Müh. | 1 | C | _isim ekle_ |

> ⚠️ Ekipte **Biyomedikal Müh. yok.** Şartnamede ona önerilen işler (IMU/EMG seçimi, kalibrasyon, sinyal işleme, beş komuta dönüştürme, ergonomi) birine atanmalı. İş bölümü öneri niteliğindedir; her öğrencinin somut katkısı raporda görünmelidir.

## Arayüzler (modüller arası sözleşme)

Modüller arası veri formatı burada **tek yerde** tanımlanır; değişiklik önce burada konuşulur, sonra koda geçer.

| Bağlantı | Veri | Sıklık | Format / protokol |
| --- | --- | --- | --- |
| B → A | Komut: ileri / geri / sol / sağ / dur | Olay bazlı, tepki ≤ 2 s | _belirlenecek_ |
| A → D | Eğim açısı (°), hareket durumu | 1 Hz | _belirlenecek_ |
| C → D | Şarj durumu, pil seviyesi (%) | 1 Hz | _belirlenecek_ |
| C ↔ A | İstasyon IR sinyali, yaklaşma modu | Sürekli | _belirlenecek_ |

## Takvim

| Hafta | Beklenen çalışma |
| --- | --- |
| 1-2 | Ekip, senaryo, rol paylaşımı, sistem mimarisi |
| 2-4 | Parça seçimi, mekanik/güç tasarımı, eldiven ve mobil uygulama iskeleti |
| 4-7 | Robot alt sistemleri ve ilk aktif denge; şarj istasyonu ve eldiven prototipleri |
| 7-10 | Hareket kontrolü, giyilebilir komutlar, mobil görsel takip ve ölçüm |
| 10-12 | İlaç kutusu taşıma, şarj istasyonu yerleşimi, bütünleşik görev |
| 12-13 | Ortak test protokolüyle prova, hata giderme, sonuç kaydı |
| Final | Proje Pazarı: canlı 5×20 değerlendirme, demonstrasyon, sunum |

Bütçe: hedef ≈ **9.500 TL** (aralık 6.150 – 13.400 TL). Pahalı donanım puan getirmez.

## Çalışma kuralları (iletişim ve merge conflict önleme)

**Klasör sahipliği**
- Herkes yalnız kendi modül klasöründe (`Modüller/<X>/`) çalışır.
- Başka bir modülün klasöründe değişiklik gerekiyorsa önce o modülün sorumlusuna haber verilir.
- Ana `README.md` ve `ProjeTanımSunum/` proje yöneticisinin sorumluluğundadır; değişiklik önerisi issue veya mesajla iletilir.

**Branch düzeni**
- `main` her zaman çalışan / gözden geçirilmiş halidir; doğrudan `main`'e push yapılmaz.
- Branch adı: `<modül>/<kısa-açıklama>` — örn. `D/telemetri-ekrani`, `A/pid-ayar`.
- İş bitince Pull Request açılır, merge'ü proje yöneticisi yapar.

**Commit**
- Küçük ve sık commit; mesaj başında modül kodu: `[D] 1 Hz telemetri okuma eklendi`.
- Çalışmaya başlamadan önce `git pull` ile `main` güncellenir, kendi branch'e alınır.
- Büyük ikili dosyalar (video, 3B model çıktıları) commit'lenmez; bağlantı olarak `docs/` içine yazılır.

**İletişim**
- Arayüz (veri formatı) değişikliği → önce yukarıdaki **Arayüzler** tablosu güncellenir, ilgili modüllere haber verilir.
- Her modül kendi `README.md`'sindeki isterler listesini (checkbox) güncel tutar; ilerleme oradan takip edilir.
