# Uyku — menü çubuğu uygulaması

[![lisans: PolyForm Noncommercial 1.0.0](https://img.shields.io/badge/lisans-PolyForm%20Noncommercial%201.0.0-4c6ef5)](LICENSE)

> **Kişisel ve ticari olmayan her kullanım serbest.** Ticari bir şeyin içinde ya da
> yanında kullanmak için hak sahibinden izin gerekir — bkz. [LICENSE](LICENSE).

macOS'un uykuya geçmesini engelleyen menü çubuğu aracı. Ekran kapansa da,
kapak kapansa da uyumaz. Süre verilirse zamanı dolunca kendiliğinden normale döner.

Tek bir makine için yazıldı — App Store veya Homebrew paketi değil.
Ağ erişimi yok. Tek dokunduğu sistem ayarı: `pmset -a disablesleep 0|1`

## Simge
- `☾`   hilal tek başına  → kilit kapalı
- `☾✦`  hilal + yıldız    → kilit açık
- Süreli kilitte yanında geri sayım: `☾ 2:14`

## Dosyalar
- `UykuMenu.swift`   — menü çubuğu uygulaması (ana program)
- `UykuPaneli.swift` — detaylı ayar penceresi
- `ikon.swift`       — ay-yıldız ikonunu çizen kaynak
- `ikon.icns`        — hazır ikon (561 KB, kayıpsız optimize)
- `onizleme.png`

## Yeni hesapta kurmak
```bash
swiftc -O UykuMenu.swift   -o uyku-menu
swiftc -O UykuPaneli.swift -o uyku-paneli
```
Sonra her biri için .app paketi: Contents/MacOS/<ikili>, Contents/Resources/icon.icns,
Contents/Info.plist (CFBundleExecutable, CFBundleIconFile=icon, menü için LSUIElement=true).

Girişte başlatmak için `~/Library/LaunchAgents/local.uyku.menu.plist`.

## Parola sormaması için
```bash
sudo tee /etc/sudoers.d/uyku-kilidi >/dev/null <<EOF
$(whoami) ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep *, /usr/bin/pmset -b displaysleep *, /usr/bin/pmset -c displaysleep *, /usr/bin/pmset -b lessbright *
EOF
sudo chmod 440 /etc/sudoers.d/uyku-kilidi && sudo visudo -c
```

## Uyarı
Kilit açıkken makineyi kapalı çantaya koyma — kapak kapalı + çalışan işlemci = ısı çıkamaz.
Bu yüzden süresiz yerine süreli seçenekleri tercih et.

## Lisans

[PolyForm Noncommercial 1.0.0](LICENSE) — kişisel kullanım, hobi projeleri, çalışma,
araştırma ve kâr amacı gütmeyen kurumlar için serbest.

Ticari kullanım hak sahibinden ayrı izin ister. Para kazandığın bir şeyin içinde ya da
yanında kullanmak istersen bir issue açıp sor.

(Bu kaynağı açık bir lisans; OSI onaylı bir açık kaynak lisansı değil.)
