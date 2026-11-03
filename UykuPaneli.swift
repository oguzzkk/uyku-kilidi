import AppKit

// ─────────── yardimcilar ───────────
func kabuk(_ yol: String, _ arg: [String]) -> String {
  let p = Process(); p.executableURL = URL(fileURLWithPath: yol); p.arguments = arg
  let boru = Pipe(); p.standardOutput = boru; p.standardError = Pipe()
  do { try p.run() } catch { return "" }
  let d = boru.fileHandleForReading.readDataToEndOfFile(); p.waitUntilExit()
  return String(data: d, encoding: .utf8) ?? ""
}
func pmsetOku() -> String { kabuk("/usr/bin/pmset", ["-g"]) }
func pmsetOzel() -> String { kabuk("/usr/bin/pmset", ["-g", "custom"]) }

/// Yetkili yazma: once parolasiz sudo, sonra Touch ID, en son parola penceresi
@discardableResult
func pmsetYaz(_ arg: [String]) -> Bool {
  let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
  p.arguments = ["-n", "/usr/bin/pmset"] + arg
  p.standardOutput = Pipe(); p.standardError = Pipe()
  if (try? p.run()) != nil { p.waitUntilExit(); if p.terminationStatus == 0 { return true } }

  let p2 = Process(); p2.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
  p2.arguments = ["/usr/bin/pmset"] + arg
  p2.standardOutput = Pipe(); p2.standardError = Pipe()
  if (try? p2.run()) != nil { p2.waitUntilExit(); if p2.terminationStatus == 0 { return true } }

  let komut = "/usr/bin/pmset " + arg.joined(separator: " ")
  let betik = "do shell script \"\(komut)\" with administrator privileges"
  var hata: NSDictionary?
  NSAppleScript(source: betik)?.executeAndReturnError(&hata)
  return hata == nil
}

func deger(_ metin: String, _ anahtar: String) -> Int? {
  for satir in metin.split(separator: "\n") where satir.contains(anahtar) {
    let parca = satir.split(whereSeparator: { $0.isWhitespace }).filter { !$0.isEmpty }
    if let i = parca.firstIndex(where: { $0.contains(anahtar) }), i+1 < parca.count {
      return Int(parca[i+1])
    }
  }
  return nil
}
/// pmset -g custom ciktisini pil/priz bloklarina ayirip anahtar okur
func blokDeger(_ blok: String, _ anahtar: String) -> Int? {
  let t = pmsetOzel()
  guard let bas = t.range(of: blok) else { return nil }
  var kalan = String(t[bas.upperBound...])
  if blok == "Battery Power:", let ac = kalan.range(of: "AC Power:") {
    kalan = String(kalan[..<ac.lowerBound])
  }
  return deger(kalan, anahtar)
}

// ─────────── gorunum yardimcilari ───────────
func etiket(_ s: String, _ boy: CGFloat, _ agirlik: NSFont.Weight,
            _ renk: NSColor, _ x: CGFloat, _ y: CGFloat, _ g: CGFloat = 400) -> NSTextField {
  let t = NSTextField(labelWithString: s)
  t.font = .systemFont(ofSize: boy, weight: agirlik); t.textColor = renk
  t.frame = NSRect(x: x, y: y, width: g, height: boy + 8)
  return t
}
func baslikCizgi(_ s: String, _ y: CGFloat) -> NSTextField {
  let t = etiket(s.uppercased(), 10.5, .semibold, .tertiaryLabelColor, 26, y, 400)
  return t
}

// ─────────── kart ───────────
final class Kart: NSView {
  var vurgu = false
  override func draw(_ r: NSRect) {
    let yol = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)
    (vurgu ? NSColor.controlAccentColor.withAlphaComponent(0.12)
           : NSColor.unemphasizedSelectedContentBackgroundColor.withAlphaComponent(0.5)).setFill()
    yol.fill()
    (vurgu ? NSColor.controlAccentColor.withAlphaComponent(0.55)
           : NSColor.separatorColor).setStroke()
    yol.lineWidth = 1; yol.stroke()
  }
}

// ─────────── pencere ───────────
@MainActor
final class Panel: NSObject, NSApplicationDelegate {
  var pencere: NSWindow!
  var kart = Kart()
  var kilitAnahtar = NSSwitch()
  var kilitBaslik = NSTextField(labelWithString: "")
  var kilitAlt = NSTextField(labelWithString: "")
  var pilAcilir = NSPopUpButton()
  var prizAcilir = NSPopUpButton()
  var kisKutu = NSButton()
  var liste = NSTextView()
  var pilDurum = NSTextField(labelWithString: "")
  let secenekler: [(String, Int)] = [("1 dakika",1),("2 dakika",2),("5 dakika",5),
    ("10 dakika",10),("15 dakika",15),("30 dakika",30),("1 saat",60),("Asla",0)]

  func applicationDidFinishLaunching(_ n: Notification) {
    let g: CGFloat = 460, y: CGFloat = 600
    pencere = NSWindow(contentRect: NSRect(x: 0, y: 0, width: g, height: y),
                       styleMask: [.titled, .closable, .miniaturizable],
                       backing: .buffered, defer: false)
    pencere.title = "Uyku Paneli"
    pencere.center()
    let iç = pencere.contentView!

    // ── kilit karti ──
    kart.frame = NSRect(x: 22, y: y-136, width: g-44, height: 96)
    iç.addSubview(kart)
    kilitBaslik = etiket("", 16, .semibold, .labelColor, 42, y-78, 300)
    kilitAlt    = etiket("", 12, .regular, .secondaryLabelColor, 42, y-104, 300)
    iç.addSubview(kilitBaslik); iç.addSubview(kilitAlt)
    kilitAnahtar.frame = NSRect(x: g-96, y: y-100, width: 52, height: 32)
    kilitAnahtar.target = self; kilitAnahtar.action = #selector(kilitDegisti)
    iç.addSubview(kilitAnahtar)

    // ── ekran bolumu ──
    iç.addSubview(baslikCizgi("Ekran", y-176))
    iç.addSubview(etiket("Pilde kapan", 13, .regular, .labelColor, 26, y-208, 200))
    pilAcilir.frame = NSRect(x: g-186, y: y-214, width: 160, height: 26)
    secenekler.forEach { pilAcilir.addItem(withTitle: $0.0) }
    pilAcilir.target = self; pilAcilir.action = #selector(pilDegisti)
    iç.addSubview(pilAcilir)

    iç.addSubview(etiket("Prizde kapan", 13, .regular, .labelColor, 26, y-246, 200))
    prizAcilir.frame = NSRect(x: g-186, y: y-252, width: 160, height: 26)
    secenekler.forEach { prizAcilir.addItem(withTitle: $0.0) }
    prizAcilir.target = self; prizAcilir.action = #selector(prizDegisti)
    iç.addSubview(prizAcilir)

    kisKutu = NSButton(checkboxWithTitle: "Pilde ekranı otomatik kıs", target: self,
                       action: #selector(kisDegisti))
    kisKutu.frame = NSRect(x: 24, y: y-288, width: 300, height: 22)
    iç.addSubview(kisKutu)

    // ── engelleyenler ──
    iç.addSubview(baslikCizgi("Şu an uykuyu engelleyenler", y-334))
    let kaydir = NSScrollView(frame: NSRect(x: 22, y: 56, width: g-44, height: 200))
    kaydir.hasVerticalScroller = true; kaydir.borderType = .noBorder
    kaydir.drawsBackground = true
    kaydir.backgroundColor = .unemphasizedSelectedContentBackgroundColor.withAlphaComponent(0.4)
    liste.isEditable = false; liste.drawsBackground = false
    liste.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    liste.textContainerInset = NSSize(width: 10, height: 8)
    kaydir.documentView = liste
    kaydir.wantsLayer = true; kaydir.layer?.cornerRadius = 10
    iç.addSubview(kaydir)

    pilDurum = etiket("", 11.5, .regular, .secondaryLabelColor, 26, 24, 400)
    iç.addSubview(pilDurum)

    yenile()
    Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
      Task { @MainActor in self.yenile() }
    }
    pencere.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  func yenile() {
    let g = pmsetOku()
    let kilitli = (deger(g, "SleepDisabled") ?? 0) == 1
    kilitAnahtar.state = kilitli ? .on : .off
    kart.vurgu = kilitli; kart.needsDisplay = true
    kilitBaslik.stringValue = kilitli ? "Uyku kilidi açık" : "Uyku kilidi kapalı"
    kilitAlt.stringValue = kilitli
      ? "Kapak kapansa da uyumaz. Ekran yine kapanır."
      : "Normal davranış — kapak kapanınca uyur."

    if let p = blokDeger("Battery Power:", "displaysleep"),
       let i = secenekler.firstIndex(where: { $0.1 == p }) { pilAcilir.selectItem(at: i) }
    if let a = blokDeger("AC Power:", "displaysleep"),
       let i = secenekler.firstIndex(where: { $0.1 == a }) { prizAcilir.selectItem(at: i) }
    kisKutu.state = (blokDeger("Battery Power:", "lessbright") ?? 0) == 1 ? .on : .off

    // engelleyenler
    let a = kabuk("/usr/bin/pmset", ["-g", "assertions"])
    var satirlar: [String] = []
    var basladi = false
    for s in a.split(separator: "\n", omittingEmptySubsequences: false) {
      if s.contains("Listed by owning process") { basladi = true; continue }
      guard basladi else { continue }
      let t = s.trimmingCharacters(in: .whitespaces)
      guard t.hasPrefix("pid ") else { continue }
      let isim = t.range(of: #"\(([^)]+)\)"#, options: .regularExpression)
        .map { String(t[$0]).dropFirst().dropLast() } ?? "?"
      let tur = t.contains("PreventUserIdleSystemSleep") ? "sistem uykusu"
              : t.contains("NoIdleSleep") ? "boşta uyku"
              : t.contains("PreventDisplaySleep") ? "ekran uykusu"
              : t.contains("UserIsActive") ? "kullanıcı etkin" : "diğer"
      let sure = t.range(of: #"\d{2}:\d{2}:\d{2}"#, options: .regularExpression)
        .map { String(t[$0]) } ?? ""
      satirlar.append("• \(isim)  —  \(tur)  \(sure)")
    }
    liste.string = satirlar.isEmpty
      ? "Hiçbir işlem uykuyu engellemiyor."
      : satirlar.joined(separator: "\n")

    let pil = kabuk("/usr/bin/pmset", ["-g", "batt"])
    if let yuzde = pil.range(of: #"\d+%"#, options: .regularExpression) {
      let kaynak = pil.contains("AC Power") ? "prizde" : "pilde"
      var kalan = ""
      if let r = pil.range(of: #"\d+:\d+ remaining"#, options: .regularExpression) {
        kalan = " · " + String(pil[r]).replacingOccurrences(of: " remaining", with: " kaldı")
      }
      pilDurum.stringValue = "Pil \(pil[yuzde]) · \(kaynak)\(kalan)"
    }
  }

  @objc func kilitDegisti() {
    pmsetYaz(["-a", "disablesleep", kilitAnahtar.state == .on ? "1" : "0"]); yenile()
  }
  @objc func pilDegisti() {
    pmsetYaz(["-b", "displaysleep", "\(secenekler[pilAcilir.indexOfSelectedItem].1)"]); yenile()
  }
  @objc func prizDegisti() {
    pmsetYaz(["-c", "displaysleep", "\(secenekler[prizAcilir.indexOfSelectedItem].1)"]); yenile()
  }
  @objc func kisDegisti() {
    pmsetYaz(["-b", "lessbright", kisKutu.state == .on ? "1" : "0"]); yenile()
  }
  func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }
}

let uygulama = NSApplication.shared
let temsilci = MainActor.assumeIsolated { () -> Panel in
  let p = Panel()
  uygulama.delegate = p
  uygulama.setActivationPolicy(.regular)
  return p
}
_ = temsilci
uygulama.run()
