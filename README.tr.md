# Clean Zip — Türkçe

Proje klasörünü sağ tıkla, **Clean Zip** seç: kaynak kod ZIP'i aynı klasörün yanına oluşturulur.

**[Windows kurulum dosyasını indir](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest/download/CleanZip-Setup.exe)** · [English / geliştirici bilgileri](README.md)

### Komutla kurmak isteyenler için

**PowerShell 5.1 veya 7'yi yönetici olarak açmadan** aşağıdaki bloğun tamamını yapıştır. Son sürüm EXE'yi indirir, SHA256 değerini doğrular ve mevcut kullanıcına sessizce kurar veya günceller.

```powershell
& {
    $ErrorActionPreference = 'Stop'
    $cleanZipRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/yusufkorkmaz/clean-zip-for-software-projects/releases/latest'
    $cleanZipUrl = "https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/download/$($cleanZipRelease.tag_name)"
    $cleanZipSetup = Join-Path $env:TEMP ('CleanZip-Setup-' + [Guid]::NewGuid().ToString('N') + '.exe')
    try {
        Invoke-WebRequest -UseBasicParsing -Uri "$cleanZipUrl/CleanZip-Setup.exe" -OutFile $cleanZipSetup
        $cleanZipSums = (Invoke-WebRequest -UseBasicParsing -Uri "$cleanZipUrl/SHA256SUMS.txt").Content
        $cleanZipHash = [regex]::Match($cleanZipSums, '(?m)^([a-fA-F0-9]{64})\s+CleanZip-Setup\.exe\s*

1. Yaklaşık **2,2 MB** olan `CleanZip-Setup.exe` dosyasını indir ve çalıştır.
2. Proje klasörüne veya klasör içindeki boş alana sağ tıkla → **Clean Zip**.
3. ZIP'i klasörün yanında bul. Örneğin `anasayfa` → `anasayfa.zip`.

Kurulum mevcut Windows kullanıcısına yapılır. Yönetici izni, .NET, Node.js, Visual C++ ek kurulumu veya 7-Zip gerekmez. Bu sürüm **imzasızdır**; Windows güvenlik uyarısı gösterebilir.

## Hangi menüde görünür?

| Durum | Clean Zip nerede? |
| --- | --- |
| Windows 7, 8, 8.1 veya 10 — x86/x64 | Klasik sağ tık menüsünde |
| Windows 11 x64 — geliştirici modu kapalı | **Daha fazla seçenek göster → Clean Zip** |
| Windows 11 x64 — geliştirici modu zaten açık | Kayıt başarılıysa yeni menüde; başarısızsa **Daha fazla seçenek göster** altında |
| Windows ARM | x86/x64 emülasyonuyla klasik menüde; yerel ARM64 eklentisi yok |

**2.0.1 çift giriş sorununu düzeltir:** modern kayıt varsa ek klasik giriş gizlenir; modern kayıt yapılamazsa klasik giriş görünür kalır.

Kurulum Windows'un menü görünümünü veya güvenlik ayarlarını değiştirmez, geliştirici modunu açmaz ve sertifika yüklemez. Geliştirici modu olmadan modern menü kurulumu için güvenilir imzalı kimlik paketi gerekir; mevcut sürümde bu paket yoktur.

Windows 7 ve sonrası uyumluluk hedefidir. Her eski sürüm ve ARM ayrı bilgisayarlarda doğrulanmadı; otomatik testler güncel Windows'ta çalışır.

## Karşılaşabileceğin durumlar

| Durum | Açıklama / çözüm |
| --- | --- |
| **Windows kişisel bilgisayarınızı korudu / Bilinmeyen yayıncı** | Dosyanın sağlama değerini kontrol et; Windows sunuyorsa **Ek bilgi → Yine de çalıştır** seç. |
| **Yine de çalıştır** butonu yok | Windows ilkesi geçişi engelliyor olabilir. Aşağıdaki adımlara bak; iş/okul bilgisayarında BT biriminden izin iste. |
| Windows 11 menüsü eski görünüyor | Daha önce uygulanmış bir Windows ayarı bunu zorlayabilir. Clean Zip bu tercihi değiştirmez; aşağıdaki geri alma adımlarına bak. |
| İki **Clean Zip** görünüyor | **2.0.1 veya sonrasını** kur. Eski kayıt önbellekte kaldıysa Dosya Gezgini'ni yeniden başlat. |
| PowerShell / CMD penceresi kendiliğinden kapanıyor | Normal: işlem bittiğinde uyarı çıkmadan kapanır. ZIP'i proje klasörünün yanında kontrol et. |
| Yeni ZIP oluşmadı | Tüm dosyalar dışlanmış olabilir veya hedefe yazılamıyordur. Hata mesajını görmek için aşağıdaki komutu PowerShell'de çalıştır. |

İndirdiğin dosyanın değerini aynı [sürümdeki `SHA256SUMS.txt`](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest) ile karşılaştır:

```powershell
Get-FileHash .\CleanZip-Setup.exe -Algorithm SHA256
```

<details>
<summary>“Yine de çalıştır” yoksa: ilke ayarı</summary>

Kendi yönettiğin bilgisayarda yönetici, Grup İlkesi Düzenleyicisi bulunan Windows sürümlerinde şu ayarı inceleyebilir:

1. **Win + R → `gpedit.msc`**.
2. **Bilgisayar Yapılandırması → Yönetim Şablonları → Windows Bileşenleri → Windows Defender SmartScreen → Gezgin**.
3. **Windows Defender SmartScreen'i yapılandır → Etkin → Uyar**.

**Uyar** onayla devam etmeye izin verir; **Uyar ve geçişleri engelle** bu butonu kaldırır. SmartScreen uyarıları açık kalır; değişiklik tüm indirilen uygulamaları etkiler. Kurum bilgisayarında BT biriminin onayladığı kurulum yolunu kullan; kurum ilkesi yerel değişikliği geri uygulayabilir.

Clean Zip bu ayarı değiştirmez. Dijital imza da SmartScreen uyarısının hemen kalkacağını garanti etmez. [Microsoft ilke açıklaması](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-smartscreen#preventoverrideforfilesinshell).

</details>

<details>
<summary>Önceden yapılmış kayıt defteri ayarıyla zorlanan eski menüyü geri alma</summary>

Aşağıdaki komutu etkilenen masaüstü kullanıcısıyla PowerShell'de çalıştır. Yalnızca eski menüyü zorlayan **boş kullanıcı kaydını** masaüstüne yedekler ve kaldırır. Windows'un sistem kaydına dokunmaz.

```powershell
$key = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
$server = Join-Path $key 'InProcServer32'
if ((Test-Path -LiteralPath $server) -and
    [string]::IsNullOrEmpty((Get-Item -LiteralPath $server).GetValue(''))) {
    $backup = Join-Path ([Environment]::GetFolderPath('Desktop')) ('context-menu-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.reg')
    & reg.exe export 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' $backup /y
    if ($LASTEXITCODE -eq 0) { Remove-Item -LiteralPath $key -Recurse -Force }
}
```

Ardından Dosya Gezgini'ni yeniden başlat veya oturumu kapatıp aç. Bu kayıt yoksa komut değişiklik yapmaz; menüyü değiştiren Windows özelleştirme aracını kontrol et.

</details>

## Neler ZIP'e alınmaz?

| İçerik | Örnekler |
| --- | --- |
| Bağımlılıklar, derleme çıktıları, önbellekler | `node_modules`, `.next`, `bin`, `obj`, `dist`, `.git` |
| Derlenmiş dosyalar | DLL, EXE, PDB, CLASS, PYC |
| Medya, fontlar, arşivler | Resim, video, ses, PDF, ZIP, font |
| Office ve tasarım dosyaları | PPTX, DOCX, XLSX, PSD, AI, XD, Sketch |
| Kurulum, disk, veritabanı verisi, model ağırlıkları | MSI, ISO, DB, MDF, ONNX, PT |
| Üretilmiş ve geçici dosyalar | `.min.js`, `.min.css`, kaynak haritaları, log, döküm, geçici dosyalar |

Normal JS/CSS, kaynak kod, proje tanımları, kilit dosyaları, SQL şemaları ve yapılandırmalar korunur. **`.env` dosyaları da korunur:** paylaşmadan önce gizli bilgileri kontrol et. ZIP kod inceleme içindir; projeyi çalıştırmak için dışlanan görseller veya diğer varlıklar gerekebilir.

[Tüm varsayılan kurallar](CleanZip.rules.txt). Kendi kurallarını `%LOCALAPPDATA%\CleanZip\CleanZip.rules.txt` dosyasından düzenle:

```text
d:node_modules
e:.pdf
s:.min.js
f:Thumbs.db
```

`d:` klasör adı, `e:` uzantı, `s:` dosya adı sonu, `f:` tam dosya adı. Büyük/küçük harf ayrımı yoktur. Dışlanan klasörlerin içine girilmez; bağlantılar atlanır.

## Güncelleme ve kaldırma

Güncellemek için son kurulum dosyasını çalıştır. Kaldırmak için **Yüklü uygulamalar → Clean Zip** veya Başlat menüsündeki kaldırma kısayolunu kullan. Özel dışlama kuralların güncellemede ve kaldırmada korunur.

Kaynak dosyalar değiştirilmez. Eski ZIP ancak yeni ZIP başarıyla tamamlanınca değiştirilir; hata olursa eskisi korunur. Seçilen dosya yoksa ZIP oluşturulmaz.

## Hata mesajını görme

```powershell
& "$env:LOCALAPPDATA\CleanZip\CleanZip.exe" --path "C:\Projeler\Projem" --no-ui
```

[Dosya listesini önizleme, başka yere ZIP oluşturma ve derleme bilgileri](README.md#command-line).
).Groups[1].Value
        if (-not $cleanZipHash -or (Get-FileHash -LiteralPath $cleanZipSetup -Algorithm SHA256).Hash -ne $cleanZipHash) { throw 'Clean Zip checksum verification failed.' }
        $cleanZipProcess = Start-Process -FilePath $cleanZipSetup -ArgumentList '/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART' -WindowStyle Hidden -Wait -PassThru
        if ($cleanZipProcess.ExitCode -ne 0) { throw "Clean Zip installation failed: $($cleanZipProcess.ExitCode)" }
        Write-Output 'Clean Zip installed.'
    } finally {
        if (Test-Path -LiteralPath $cleanZipSetup) { Remove-Item -LiteralPath $cleanZipSetup -Force }
    }
}
```

## Kurulum ve kullanım

1. Yaklaşık **2,2 MB** olan `CleanZip-Setup.exe` dosyasını indir ve çalıştır.
2. Proje klasörüne veya klasör içindeki boş alana sağ tıkla → **Clean Zip**.
3. ZIP'i klasörün yanında bul. Örneğin `anasayfa` → `anasayfa.zip`.

Kurulum mevcut Windows kullanıcısına yapılır. Yönetici izni, .NET, Node.js, Visual C++ ek kurulumu veya 7-Zip gerekmez. Bu sürüm **imzasızdır**; Windows güvenlik uyarısı gösterebilir.

## Hangi menüde görünür?

| Durum | Clean Zip nerede? |
| --- | --- |
| Windows 7, 8, 8.1 veya 10 — x86/x64 | Klasik sağ tık menüsünde |
| Windows 11 x64 — geliştirici modu kapalı | **Daha fazla seçenek göster → Clean Zip** |
| Windows 11 x64 — geliştirici modu zaten açık | Kayıt başarılıysa yeni menüde; başarısızsa **Daha fazla seçenek göster** altında |
| Windows ARM | x86/x64 emülasyonuyla klasik menüde; yerel ARM64 eklentisi yok |

**2.0.1 çift giriş sorununu düzeltir:** modern kayıt varsa ek klasik giriş gizlenir; modern kayıt yapılamazsa klasik giriş görünür kalır.

Kurulum Windows'un menü görünümünü veya güvenlik ayarlarını değiştirmez, geliştirici modunu açmaz ve sertifika yüklemez. Geliştirici modu olmadan modern menü kurulumu için güvenilir imzalı kimlik paketi gerekir; mevcut sürümde bu paket yoktur.

Windows 7 ve sonrası uyumluluk hedefidir. Her eski sürüm ve ARM ayrı bilgisayarlarda doğrulanmadı; otomatik testler güncel Windows'ta çalışır.

## Karşılaşabileceğin durumlar

| Durum | Açıklama / çözüm |
| --- | --- |
| **Windows kişisel bilgisayarınızı korudu / Bilinmeyen yayıncı** | Dosyanın sağlama değerini kontrol et; Windows sunuyorsa **Ek bilgi → Yine de çalıştır** seç. |
| **Yine de çalıştır** butonu yok | Windows ilkesi geçişi engelliyor olabilir. Aşağıdaki adımlara bak; iş/okul bilgisayarında BT biriminden izin iste. |
| Windows 11 menüsü eski görünüyor | Daha önce uygulanmış bir Windows ayarı bunu zorlayabilir. Clean Zip bu tercihi değiştirmez; aşağıdaki geri alma adımlarına bak. |
| İki **Clean Zip** görünüyor | **2.0.1 veya sonrasını** kur. Eski kayıt önbellekte kaldıysa Dosya Gezgini'ni yeniden başlat. |
| PowerShell / CMD penceresi kendiliğinden kapanıyor | Normal: işlem bittiğinde uyarı çıkmadan kapanır. ZIP'i proje klasörünün yanında kontrol et. |
| Yeni ZIP oluşmadı | Tüm dosyalar dışlanmış olabilir veya hedefe yazılamıyordur. Hata mesajını görmek için aşağıdaki komutu PowerShell'de çalıştır. |

İndirdiğin dosyanın değerini aynı [sürümdeki `SHA256SUMS.txt`](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest) ile karşılaştır:

```powershell
Get-FileHash .\CleanZip-Setup.exe -Algorithm SHA256
```

<details>
<summary>“Yine de çalıştır” yoksa: ilke ayarı</summary>

Kendi yönettiğin bilgisayarda yönetici, Grup İlkesi Düzenleyicisi bulunan Windows sürümlerinde şu ayarı inceleyebilir:

1. **Win + R → `gpedit.msc`**.
2. **Bilgisayar Yapılandırması → Yönetim Şablonları → Windows Bileşenleri → Windows Defender SmartScreen → Gezgin**.
3. **Windows Defender SmartScreen'i yapılandır → Etkin → Uyar**.

**Uyar** onayla devam etmeye izin verir; **Uyar ve geçişleri engelle** bu butonu kaldırır. SmartScreen uyarıları açık kalır; değişiklik tüm indirilen uygulamaları etkiler. Kurum bilgisayarında BT biriminin onayladığı kurulum yolunu kullan; kurum ilkesi yerel değişikliği geri uygulayabilir.

Clean Zip bu ayarı değiştirmez. Dijital imza da SmartScreen uyarısının hemen kalkacağını garanti etmez. [Microsoft ilke açıklaması](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-smartscreen#preventoverrideforfilesinshell).

</details>

<details>
<summary>Önceden yapılmış kayıt defteri ayarıyla zorlanan eski menüyü geri alma</summary>

Aşağıdaki komutu etkilenen masaüstü kullanıcısıyla PowerShell'de çalıştır. Yalnızca eski menüyü zorlayan **boş kullanıcı kaydını** masaüstüne yedekler ve kaldırır. Windows'un sistem kaydına dokunmaz.

```powershell
$key = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
$server = Join-Path $key 'InProcServer32'
if ((Test-Path -LiteralPath $server) -and
    [string]::IsNullOrEmpty((Get-Item -LiteralPath $server).GetValue(''))) {
    $backup = Join-Path ([Environment]::GetFolderPath('Desktop')) ('context-menu-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.reg')
    & reg.exe export 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' $backup /y
    if ($LASTEXITCODE -eq 0) { Remove-Item -LiteralPath $key -Recurse -Force }
}
```

Ardından Dosya Gezgini'ni yeniden başlat veya oturumu kapatıp aç. Bu kayıt yoksa komut değişiklik yapmaz; menüyü değiştiren Windows özelleştirme aracını kontrol et.

</details>

## Neler ZIP'e alınmaz?

| İçerik | Örnekler |
| --- | --- |
| Bağımlılıklar, derleme çıktıları, önbellekler | `node_modules`, `.next`, `bin`, `obj`, `dist`, `.git` |
| Derlenmiş dosyalar | DLL, EXE, PDB, CLASS, PYC |
| Medya, fontlar, arşivler | Resim, video, ses, PDF, ZIP, font |
| Office ve tasarım dosyaları | PPTX, DOCX, XLSX, PSD, AI, XD, Sketch |
| Kurulum, disk, veritabanı verisi, model ağırlıkları | MSI, ISO, DB, MDF, ONNX, PT |
| Üretilmiş ve geçici dosyalar | `.min.js`, `.min.css`, kaynak haritaları, log, döküm, geçici dosyalar |

Normal JS/CSS, kaynak kod, proje tanımları, kilit dosyaları, SQL şemaları ve yapılandırmalar korunur. **`.env` dosyaları da korunur:** paylaşmadan önce gizli bilgileri kontrol et. ZIP kod inceleme içindir; projeyi çalıştırmak için dışlanan görseller veya diğer varlıklar gerekebilir.

[Tüm varsayılan kurallar](CleanZip.rules.txt). Kendi kurallarını `%LOCALAPPDATA%\CleanZip\CleanZip.rules.txt` dosyasından düzenle:

```text
d:node_modules
e:.pdf
s:.min.js
f:Thumbs.db
```

`d:` klasör adı, `e:` uzantı, `s:` dosya adı sonu, `f:` tam dosya adı. Büyük/küçük harf ayrımı yoktur. Dışlanan klasörlerin içine girilmez; bağlantılar atlanır.

## Güncelleme ve kaldırma

Güncellemek için son kurulum dosyasını çalıştır. Kaldırmak için **Yüklü uygulamalar → Clean Zip** veya Başlat menüsündeki kaldırma kısayolunu kullan. Özel dışlama kuralların güncellemede ve kaldırmada korunur.

Kaynak dosyalar değiştirilmez. Eski ZIP ancak yeni ZIP başarıyla tamamlanınca değiştirilir; hata olursa eskisi korunur. Seçilen dosya yoksa ZIP oluşturulmaz.

## Hata mesajını görme

```powershell
& "$env:LOCALAPPDATA\CleanZip\CleanZip.exe" --path "C:\Projeler\Projem" --no-ui
```

[Dosya listesini önizleme, başka yere ZIP oluşturma ve derleme bilgileri](README.md#command-line).
