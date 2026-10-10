# Clean Zip — For Windows

[English](README.md) · [Başka platform seç](../README.tr.md)

Proje klasörüne sağ tıkla; kaynak kod ZIP'i klasörün yanında oluşsun.

## Kurulum ve kullanım

1. [CleanZip-Setup.exe dosyasını indir](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest/download/CleanZip-Setup.exe) (yaklaşık 2,2 MB) ve çalıştır.
2. Proje klasörüne veya içindeki boş alana sağ tıkla → **Clean Zip**. Windows 11'de **Daha fazla seçenek göster** altında ara.
3. ZIP'i klasörün yanında bul: `Projem` → `Projem.zip`.

İşlem penceresi tamamlanınca kapanır. Kurulum kullanıcı hesabına yapılır; yönetici izni veya ek çalışma ortamı gerekmez. Sürüm imzasızdır; Windows güvenlik uyarısı gösterebilir.

[Taşınabilir x64 ZIP](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest/download/CleanZip-Portable-x64.zip) · [Sürümler ve sağlama değerleri](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest)

## PowerShell ile kurulum ve kullanım

### Kurulum veya güncelleme

**PowerShell 5.1 veya 7'yi yönetici olmadan** aç ve bloğun tamamını yapıştır. Son Windows kurulum dosyasını indirir, SHA-256 değerini kontrol eder ve kullanıcı hesabına sessizce kurar veya günceller.

```powershell
& {
    $ErrorActionPreference = 'Stop'
    $cleanZipRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/yusufkorkmaz/clean-zip-for-software-projects/releases/latest'
    $cleanZipUrl = "https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/download/$($cleanZipRelease.tag_name)"
    $cleanZipSetup = Join-Path $env:TEMP ('CleanZip-Setup-' + [Guid]::NewGuid().ToString('N') + '.exe')
    try {
        Invoke-WebRequest -UseBasicParsing -Uri "$cleanZipUrl/CleanZip-Setup.exe" -OutFile $cleanZipSetup
        $cleanZipSums = (Invoke-WebRequest -UseBasicParsing -Uri "$cleanZipUrl/SHA256SUMS.txt").Content
        $cleanZipHash = [regex]::Match($cleanZipSums, '(?m)^([a-fA-F0-9]{64})\s+CleanZip-Setup\.exe\s*$').Groups[1].Value
        if (-not $cleanZipHash -or (Get-FileHash -LiteralPath $cleanZipSetup -Algorithm SHA256).Hash -ne $cleanZipHash) { throw 'Clean Zip checksum verification failed.' }
        $cleanZipProcess = Start-Process -FilePath $cleanZipSetup -ArgumentList '/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART' -WindowStyle Hidden -Wait -PassThru
        if ($cleanZipProcess.ExitCode -ne 0) { throw "Clean Zip installation failed: $($cleanZipProcess.ExitCode)" }
        Write-Output 'Clean Zip installed.'
    } finally {
        if (Test-Path -LiteralPath $cleanZipSetup) { Remove-Item -LiteralPath $cleanZipSetup -Force }
    }
}
```

### ZIP oluşturma ve diğer komutlar

`$cleanZipProject` değerini kendi proje klasörünle değiştir. Komutlar kurulu uygulamayı tam yoluyla çağırır; herhangi bir klasörden çalıştırabilirsin.

```powershell
$cleanZipEngine = "$env:LOCALAPPDATA\CleanZip\CleanZip.exe"
$cleanZipProject = 'C:\Projeler\Projem'
$cleanZipArchives = "$env:USERPROFILE\CleanZip-Archives"
New-Item -ItemType Directory -Path $cleanZipArchives -Force | Out-Null

# Kurulu sürümü göster.
& $cleanZipEngine --version

# Proje klasörünün yanında ZIP oluştur; hata mesajları açık kalır.
& $cleanZipEngine --path $cleanZipProject --no-ui

# ZIP oluşturmadan seçilen dosyaları listele.
& $cleanZipEngine --path $cleanZipProject --scan-only --manifest "$cleanZipArchives\selected.txt"

# ZIP'i başka bir klasöre yaz.
& $cleanZipEngine --path $cleanZipProject --output "$cleanZipArchives\project.zip" --no-ui
```

ZIP ve dosya listesi proje dışında ve farklı hedeflerde olmalı. Hedef klasör yukarıdaki komutla oluşturulur.

## ZIP'e neler alınır?

Kaynak kod, normal JS/CSS, proje tanımları, kilit dosyaları, SQL şemaları ve yapılandırmalar korunur. Bağımlılıklar, derleme çıktıları, önbellekler, derlenmiş dosyalar, medya, fontlar, arşivler, Office/tasarım dosyaları, kurulum/disk/veritabanı dosyaları, model ağırlıkları ve üretilmiş/geçici dosyalar dışlanır. [Tüm kurallar](../CleanZip.rules.txt).

**`.env` dosyaları dahil edilir; paylaşmadan önce gizli bilgileri kontrol et.** ZIP kod inceleme içindir; projeyi çalıştırmak için dışlanan dosyalar gerekebilir. Bağlantılar atlanır. Kaynak dosyalar değişmez; eski ZIP yeni arşiv tamamlanınca değiştirilir. Seçim boşsa ZIP oluşturulmaz. UTF-8 dosya adları ve ZIP64 desteklenir.

## Güncelleme ve kaldırma

Güncellemek için son kurulum dosyasını çalıştır. Kaldırmak için **Yüklü uygulamalar → Clean Zip** veya Başlat menüsündeki kaldırma kısayolunu kullan. Özel kurallar güncellemede ve kaldırmada korunur.

<details>
<summary>Menü konumu ve uyumluluk</summary>

| Bilgisayar | Clean Zip nerede? |
| --- | --- |
| Windows 7–10, x86/x64 | Klasik sağ tık menüsünde |
| Windows 11 x64 | Varsayılan olarak **Daha fazla seçenek göster** altında |
| Windows 11 x64, geliştirici modu zaten açık | Kayıt başarılıysa yeni menüde; aksi durumda klasik menüde |
| Windows ARM | x86/x64 emülasyonuyla klasik menüde; yerel ARM64 eklentisi yok |

2.0.1 çift girişleri önler; modern kayıt yapılamadığında klasik menüyü görünür tutar. Kurulum Windows menü ve güvenlik ayarlarını değiştirmez, geliştirici modunu açmaz ve sertifika yüklemez. Geliştirici modu olmadan modern menü için güvenilir imzalı kimlik paketi gerekir; bu sürümde yoktur. [Microsoft açıklaması](https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/grant-identity-to-nonpackaged-apps).

Windows 7 ve sonrası uyumluluk hedefidir. Otomatik testler güncel Windows'ta çalışır; eski sürümler ve ARM ayrı cihazlarda tek tek doğrulanmadı.

</details>

<details>
<summary>Güvenlik uyarısı, çift giriş veya ZIP oluşmaması</summary>

- **Bilinmeyen yayıncı / Windows kişisel bilgisayarınızı korudu:** dosya sağlama değerini aynı sürümdeki `SHA256SUMS.txt` ile karşılaştır. Windows sunuyorsa **Ek bilgi → Yine de çalıştır** seç.
- **Yine de çalıştır yok:** Windows ilkesi engelliyor olabilir. Aşağıdaki ilke açıklamasına bak; kurum bilgisayarında BT biriminden onaylı kurulum yolunu iste.
- **İki Clean Zip var:** 2.0.1 veya sonrasını kur; gerekirse Dosya Gezgini'ni yeniden başlat.
- **İşlem penceresi kapanıyor:** normal; klasörün yanındaki ZIP'i kontrol et.
- **ZIP oluşmadı:** tüm dosyalar dışlanmış veya hedef yazılamaz/kullanımda olabilir. Hata mesajını görmek için:

```powershell
& "$env:LOCALAPPDATA\CleanZip\CleanZip.exe" --path "C:\Projeler\Projem" --no-ui
```

Kurulum dosyasının sağlama değeri:

```powershell
Get-FileHash .\CleanZip-Setup.exe -Algorithm SHA256
```

</details>

<details>
<summary>Özel dışlama kuralları</summary>

`%LOCALAPPDATA%\CleanZip\CleanZip.rules.txt` dosyasını düzenle:

```text
d:node_modules
e:.pdf
s:.min.js
f:Thumbs.db
```

`d:` her derinlikte klasör adı, `e:` uzantı, `s:` dosya adı sonu, `f:` tam dosya adı. Büyük/küçük harf ayrımı yapılmaz. Dışlanan klasörlerin içine girilmez.

</details>

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

[Derleme ve test bilgileri (English)](README.md#build-and-test). MIT lisansı; kurulum miniz'in MIT lisansını içerir.
