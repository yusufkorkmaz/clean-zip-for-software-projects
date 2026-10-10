# Clean Zip — For Mac

[English](README.md)

Apple Silicon Mac için kaynak kod ZIP'i oluşturur. Python, Node.js, .NET veya 7-Zip kurulumu gerekmez.

## Kurulum ve kullanım

1. [Mac paketini indir](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/download/v2.0.1-macos.1/CleanZip-macOS-AppleSilicon.zip), ZIP'i aç ve içindeki `Install.command` dosyasını çalıştır.
2. Finder'da proje klasörüne sağ tıkla → **Quick Actions (Hızlı Eylemler)**.
3. Clean Zip görünmüyorsa **Customize… (Özelleştir…)** seç ve **Clean Zip** anahtarını aç.
4. Menüye geri dön → **Quick Actions → Clean Zip**.
5. ZIP'i klasörün yanında bul: `Projem` → `Projem.zip`.

Clean Zip, **Quick Actions** alt menüsündedir. Birden fazla klasör seçersen her biri için ayrı ZIP oluşur. Tamamlanınca bildirim gösterilmez; ZIP'i klasörün yanında kontrol et. Hata olursa Automator mesaj gösterir.

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
<summary>Komut satırı ve arşiv ayrıntıları</summary>

```bash
"$HOME/Library/Application Support/CleanZip/CleanZip" --path "/proje/klasörü"
"$HOME/Library/Application Support/CleanZip/CleanZip" --path "/proje/klasörü" --scan-only --manifest "/tmp/secilenler.txt"
"$HOME/Library/Application Support/CleanZip/CleanZip" --path "/proje/klasörü" --output "/arsiv/proje.zip"
```

Hedef klasör önceden mevcut olmalı. ZIP ve dosya listesi proje dışında ve birbirinden farklı olmalı. UTF-8 dosya adları ve ZIP64 desteklenir. Yeni ZIP diske yazıldıktan sonra hedef atomik olarak değiştirilir. Dosya izinleri ve extended attribute metadatası arşive aktarılmaz; bu bir tam proje yedeği değildir.

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
