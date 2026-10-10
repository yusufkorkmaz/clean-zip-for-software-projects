# Clean Zip — For Mac

[English](README.md)

Apple Silicon Mac için kaynak kod ZIP'i oluşturur. Python, Node.js, .NET veya 7-Zip kurulumu gerekmez.

## Kurulum ve kullanım

1. [Mac paketini indir](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/download/v2.0.1-macos.1/CleanZip-macOS-AppleSilicon.zip), ZIP'i aç ve içindeki `Install.command` dosyasını çalıştır.
2. Finder'da proje klasörüne sağ tıkla → **Quick Actions (Hızlı Eylemler)**.
3. Clean Zip görünmüyorsa **Customize… (Özelleştir…)** seç ve **Clean Zip** anahtarını aç.
4. Ayarları kapatıp proje klasörüne yeniden sağ tıkla → **Quick Actions → Clean Zip**.
5. ZIP'i klasörün yanında bul: `Projem` → `Projem.zip`.

Clean Zip, **Quick Actions** alt menüsündedir. Birden fazla klasör seçersen her biri için ayrı ZIP oluşur. Tamamlanınca bildirim gösterilmez; ZIP'i klasörün yanında kontrol et. Hata olursa Automator mesaj gösterir.

## Terminal ile kurulum ve kullanım

Terminal'i aç ve kurulum bloğunun tamamını yapıştır. Mac paketini indirir, SHA-256 değerini doğrular, açar ve kullanıcı hesabına kurar veya günceller. Yönetici yetkisi gerekmez.

### Kurulum veya güncelleme

```bash
/bin/bash <<'CLEANZIP'
set -euo pipefail
cleanzip_release="https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/download/v2.0.1-macos.1"
cleanzip_dir=$(mktemp -d "${TMPDIR:-/tmp}/cleanzip.XXXXXX")
trap 'rm -rf "$cleanzip_dir"' EXIT
cd "$cleanzip_dir"
/usr/bin/curl -fL --retry 2 "$cleanzip_release/CleanZip-macOS-AppleSilicon.zip" -o CleanZip-macOS-AppleSilicon.zip
/usr/bin/curl -fL --retry 2 "$cleanzip_release/SHA256SUMS.txt" -o SHA256SUMS.txt
/usr/bin/awk '$2 == "CleanZip-macOS-AppleSilicon.zip" { print }' SHA256SUMS.txt > package.sha256
test -s package.sha256
/usr/bin/shasum -a 256 -c package.sha256
/usr/bin/ditto -x -k CleanZip-macOS-AppleSilicon.zip extracted
/bin/bash "extracted/CleanZip-macOS/Install.command"
CLEANZIP
```

Kurulumdan sonra Finder'da **proje klasörüne sağ tık → Quick Actions → Clean Zip** yolunu kullan. Görünmüyorsa **Quick Actions → Customize…** üzerinden **Clean Zip** anahtarını aç.

### ZIP oluşturma ve diğer komutlar

Aşağıdaki `cleanzip_project` değerini kendi proje klasörünle değiştir. Örnekler sürüm, yardım, ZIP oluşturma, dosya listesi, farklı hedef ve özel kurallar kullanımını gösterir.

```bash
cleanzip_engine="$HOME/Library/Application Support/CleanZip/CleanZip"
cleanzip_project="$HOME/Projeler/Projem"
cleanzip_archives="$HOME/CleanZip-Archives"
mkdir -p "$cleanzip_archives"

# Kurulu sürümü ve seçenekleri göster.
"$cleanzip_engine" --version
"$cleanzip_engine" --help

# Proje klasörünün yanında ZIP oluştur.
"$cleanzip_engine" --path "$cleanzip_project" --no-ui

# ZIP oluşturmadan seçilen dosyaları listele.
"$cleanzip_engine" --path "$cleanzip_project" --scan-only --manifest "$cleanzip_archives/selected.txt"

# ZIP'i başka bir klasöre yaz.
"$cleanzip_engine" --path "$cleanzip_project" --output "$cleanzip_archives/project.zip" --no-ui

# Başka bir kural dosyası kullan (önce kopyayı düzenle).
cp "$HOME/Library/Application Support/CleanZip/CleanZip.rules.txt" "$cleanzip_archives/custom.rules.txt"
"$cleanzip_engine" --path "$cleanzip_project" --rules "$cleanzip_archives/custom.rules.txt" --output "$cleanzip_archives/custom.zip"
```

Hedef klasör önceden mevcut olmalı. ZIP ve dosya listesi proje dışında ve birbirinden farklı olmalı. UTF-8 dosya adları ve ZIP64 desteklenir. Yeni ZIP diske yazıldıktan sonra hedef atomik olarak değiştirilir. Dosya izinleri ve extended attribute metadatası arşive aktarılmaz; bu bir tam proje yedeği değildir.

## ZIP'e neler alınır?

Kaynak kod ve yapılandırmalar korunur; bağımlılıklar, derleme çıktıları, önbellekler, medya ve yaygın ikili dosyalar dışlanır. [Tüm kurallar](../CleanZip.rules.txt).

**`.env` dosyaları dahil edilir; paylaşmadan önce gizli bilgileri kontrol et.** `.gitignore` otomatik uygulanmaz. ZIP kod inceleme içindir; projeyi çalıştırmak için dışlanan dosyalar gerekebilir.

Kaynak dosyalar değişmez. Bağlantılar ve özel dosyalar atlanır. Eski ZIP yeni arşiv tamamlanınca değiştirilir; hata veya boş seçim durumunda korunur.

<details>
<summary>Güncelleme, kaldırma ve özel kurallar</summary>

Kurulum kullanıcı hesabına yapılır; yönetici yetkisi gerekmez. Uygulama ve kurallar `~/Library/Application Support/CleanZip`, Hızlı Eylem `~/Library/Services/Clean Zip.workflow` konumundadır.

Güncellemek için yeni paketin `Install.command` dosyasını çalıştır. Özel kurallar korunur; eski uygulama ve eylem `Backups` klasörüne yedeklenir.

Özel kurallar için kurulum klasöründeki `CleanZip.rules.txt` dosyasını düzenle: `d:` klasör, `e:` uzantı, `s:` ad sonu, `f:` tam dosya adı. Büyük/küçük harf ayrımı yapılmaz.

Kaldırmak için Finder'da **Git → Klasöre Git** ile `~/Library/Services` klasörünü aç ve `Clean Zip.workflow` dosyasını sil. Ardından `~/Library/Application Support/CleanZip` klasörünü kaldır; özel kuralları saklamak istiyorsan önce yedekle.

</details>

<details>
<summary>Geliştirici ve uyumluluk</summary>

Xcode Command Line Tools ve Git ile repo kökünden çalıştır:

```bash
bash macos/Build.sh
python3 tests/Test-Mac.py build/macos/CleanZip
python3 macos/Package.py /hedef/paket
```

miniz bağımlılığı belirli bir commit'e sabitlenmiştir. CMake ile derleme de desteklenir.

macOS 12+ hedeflenir; Apple Silicon sürümü bu MacBook'ta doğrulandı. Intel ve eski macOS sürümleri ayrı cihazlarda test edilmedi. Paket yerel ad hoc imzalıdır; Developer ID imzalı veya Apple noter onaylı değildir.

</details>

MIT lisansı; paket miniz'in MIT lisansını içerir.
