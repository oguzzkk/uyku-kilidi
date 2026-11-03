import AppKit

// ═══════════ yardimcilar ═══════════
func kabuk(_ yol: String, _ arg: [String]) -> String {
  let p = Process(); p.executableURL = URL(fileURLWithPath: yol); p.arguments = arg
  let boru = Pipe(); p.standardOutput = boru; p.standardError = Pipe()
  do { try p.run() } catch { return "" }
  let d = boru.fileHandleForReading.readDataToEndOfFile(); p.waitUntilExit()
  return String(data: d, encoding: .utf8) ?? ""
}
func pmsetG() -> String { kabuk("/usr/bin/pmset", ["-g"]) }

@discardableResult
func pmsetYaz(_ arg: [String]) -> Bool {
  for on in [["-n", "/usr/bin/pmset"], ["/usr/bin/pmset"]] {
    let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
    p.arguments = on + arg; p.standardOutput = Pipe(); p.standardError = Pipe()
    if (try? p.run()) != nil { p.waitUntilExit(); if p.terminationStatus == 0 { return true } }
  }
  var hata: NSDictionary?
  NSAppleScript(source: "do shell script \"/usr/bin/pmset \(arg.joined(separator: " "))\" with administrator privileges")?
    .executeAndReturnError(&hata)
  return hata == nil
}

func deger(_ metin: String, _ anahtar: String) -> Int? {
  for satir in metin.split(separator: "\n") where satir.contains(anahtar) {
    let p = satir.split(whereSeparator: { $0.isWhitespace }).filter { !$0.isEmpty }
    if let i = p.firstIndex(where: { $0.contains(anahtar) }), i+1 < p.count { return Int(p[i+1]) }
  }
  return nil
}
func blokDeger(_ blok: String, _ anahtar: String) -> Int? {
  let t = kabuk("/usr/bin/pmset", ["-g", "custom"])
  guard let b = t.range(of: blok) else { return nil }
  var k = String(t[b.upperBound...])
  if blok == "Battery Power:", let ac = k.range(of: "AC Power:") { k = String(k[..<ac.lowerBound]) }
  return deger(k, anahtar)
}
func sureMetni(_ dk: Int) -> String {
  if dk == 0 { return "Asla" }
  if dk < 60 { return "\(dk) dk" }
  return dk % 60 == 0 ? "\(dk/60) sa" : "\(dk/60) sa \(dk%60) dk"
}

// ═══════════ menu cubugu simgesi ═══════════
func hilalSimge(dolu: Bool) -> NSImage {
  let s: CGFloat = 18
  let img = NSImage(size: NSSize(width: s, height: s))
  img.lockFocus()
  NSGraphicsContext.current!.cgContext.setShouldAntialias(true)

  // ── hilal: her iki durumda da DOLU ve net ──
  let R: CGFloat = 6.5, cx: CGFloat = 6.9, cy: CGFloat = 9
  let ic = R * 0.98, kx: CGFloat = 3.0, ky: CGFloat = 1.0
  let disR = NSRect(x: cx-R, y: cy-R, width: 2*R, height: 2*R)
  let icR  = NSRect(x: cx-ic+kx, y: cy-ic+ky, width: 2*ic, height: 2*ic)
  NSGraphicsContext.saveGraphicsState()
  NSBezierPath(ovalIn: disR).addClip()
  let p = NSBezierPath(); p.appendOval(in: disR); p.appendOval(in: icR)
  p.windingRule = .evenOdd
  NSColor.black.setFill(); p.fill()
  NSGraphicsContext.restoreGraphicsState()

  // ── yildiz: SADECE kilit acikken ──
  if dolu {
    let yx: CGFloat = 13.6, yy: CGFloat = 12.6, ry: CGFloat = 3.5, rx: CGFloat = 3.5
    let w: CGFloat = 0.16                      // bel incelmesi
    let y = NSBezierPath()
    let kx2 = rx*w, ky2 = ry*w
    y.move(to: NSPoint(x: yx, y: yy+ry))
    y.curve(to: NSPoint(x: yx+rx, y: yy), controlPoint1: NSPoint(x: yx+kx2, y: yy+ky2), controlPoint2: NSPoint(x: yx+kx2, y: yy+ky2))
    y.curve(to: NSPoint(x: yx, y: yy-ry), controlPoint1: NSPoint(x: yx+kx2, y: yy-ky2), controlPoint2: NSPoint(x: yx+kx2, y: yy-ky2))
    y.curve(to: NSPoint(x: yx-rx, y: yy), controlPoint1: NSPoint(x: yx-kx2, y: yy-ky2), controlPoint2: NSPoint(x: yx-kx2, y: yy-ky2))
    y.curve(to: NSPoint(x: yx, y: yy+ry), controlPoint1: NSPoint(x: yx-kx2, y: yy+ky2), controlPoint2: NSPoint(x: yx-kx2, y: yy+ky2))
    NSColor.black.setFill(); y.fill()
  }

  img.unlockFocus()
  img.isTemplate = true
  return img
}

// ═══════════ denetleyici ═══════════
@MainActor
final class Menu: NSObject, NSApplicationDelegate, NSMenuDelegate {
  var oge: NSStatusItem!
  var menu = NSMenu()
  var bitis: Date?          // sureli kilit bitisi
  var zaman: Timer?

  func applicationDidFinishLaunching(_ n: Notification) {
    oge = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    menu.delegate = self
    oge.menu = menu
    yenile()
    zaman = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      Task { @MainActor in self.tik() }
    }
  }

  var kilitli: Bool { (deger(pmsetG(), "SleepDisabled") ?? 0) == 1 }

  func tik() {
    if let b = bitis {
      if Date() >= b { bitis = nil; pmsetYaz(["-a", "disablesleep", "0"]) }
    }
    yenile()
  }

  func yenile() {
    let k = kilitli
    if !k { bitis = nil }
    oge.button?.image = hilalSimge(dolu: k)
    if k, let b = bitis {
      let kalan = Int(b.timeIntervalSinceNow)
      oge.button?.title = kalan > 3600
        ? String(format: " %d:%02d", kalan/3600, (kalan%3600)/60)
        : String(format: " %d:%02d", kalan/60, kalan%60)
    } else {
      oge.button?.title = ""
    }
  }

  // menu her acildiginda bastan kurulur
  func menuNeedsUpdate(_ m: NSMenu) {
    m.removeAllItems()
    let k = kilitli

    let bas = NSMenuItem(title: k ? "Uyku kilidi açık" : "Uyku kilidi kapalı", action: nil, keyEquivalent: "")
    bas.isEnabled = false
    m.addItem(bas)
    if k, let b = bitis {
      let kalan = Int(b.timeIntervalSinceNow)
      let alt = NSMenuItem(title: "  \(kalan/3600) sa \((kalan%3600)/60) dk sonra kapanacak", action: nil, keyEquivalent: "")
      alt.isEnabled = false; m.addItem(alt)
    } else if k {
      let alt = NSMenuItem(title: "  Süresiz", action: nil, keyEquivalent: "")
      alt.isEnabled = false; m.addItem(alt)
    }
    m.addItem(.separator())

    if k {
      m.addItem(withTitle: "Kapat", action: #selector(kapat), keyEquivalent: "").target = self
      m.addItem(.separator())
      for (ad, sa) in [("1 saate uzat",1),("3 saate uzat",3),("5 saate uzat",5)] {
        let i = NSMenuItem(title: ad, action: #selector(sureli(_:)), keyEquivalent: "")
        i.target = self; i.tag = sa; m.addItem(i)
      }
    } else {
      let s = NSMenuItem(title: "Aç · süresiz", action: #selector(suresiz), keyEquivalent: "")
      s.target = self; m.addItem(s)
      for (ad, sa) in [("Aç · 1 saat",1),("Aç · 3 saat",3),("Aç · 5 saat",5)] {
        let i = NSMenuItem(title: ad, action: #selector(sureli(_:)), keyEquivalent: "")
        i.target = self; i.tag = sa; m.addItem(i)
      }
    }
    m.addItem(.separator())

    // durum bilgisi
    let pil = blokDeger("Battery Power:", "displaysleep") ?? 0
    let priz = blokDeger("AC Power:", "displaysleep") ?? 0
    let e1 = NSMenuItem(title: "Ekran: pilde \(sureMetni(pil)) · prizde \(sureMetni(priz))", action: nil, keyEquivalent: "")
    e1.isEnabled = false; m.addItem(e1)

    // engelleyenler
    let a = kabuk("/usr/bin/pmset", ["-g", "assertions"])
    var isimler: [String] = []
    var basla = false
    for s in a.split(separator: "\n", omittingEmptySubsequences: false) {
      if s.contains("Listed by owning process") { basla = true; continue }
      guard basla else { continue }
      let t = s.trimmingCharacters(in: .whitespaces)
      guard t.hasPrefix("pid ") else { continue }
      if let r = t.range(of: #"\(([^)]+)\)"#, options: .regularExpression) {
        let ad = String(t[r]).dropFirst().dropLast()
        if ad != "powerd" && !isimler.contains(String(ad)) { isimler.append(String(ad)) }
      }
    }
    let e2 = NSMenuItem(title: isimler.isEmpty ? "Engelleyen yok"
                        : "Engelleyen: " + isimler.prefix(3).joined(separator: ", "),
                        action: nil, keyEquivalent: "")
    e2.isEnabled = false; m.addItem(e2)

    let bat = kabuk("/usr/bin/pmset", ["-g", "batt"])
    if let y = bat.range(of: #"\d+%"#, options: .regularExpression) {
      let e3 = NSMenuItem(title: "Pil \(bat[y]) · \(bat.contains("AC Power") ? "prizde" : "pilde")",
                          action: nil, keyEquivalent: "")
      e3.isEnabled = false; m.addItem(e3)
    }

    m.addItem(.separator())
    m.addItem(withTitle: "Paneli aç…", action: #selector(panelAc), keyEquivalent: "").target = self
    m.addItem(withTitle: "Çıkış", action: #selector(cik), keyEquivalent: "q").target = self
  }

  @objc func suresiz() { bitis = nil; pmsetYaz(["-a","disablesleep","1"]); yenile() }
  @objc func kapat()   { bitis = nil; pmsetYaz(["-a","disablesleep","0"]); yenile() }
  @objc func sureli(_ s: NSMenuItem) {
    bitis = Date().addingTimeInterval(TimeInterval(s.tag * 3600))
    pmsetYaz(["-a","disablesleep","1"]); yenile()
  }
  @objc func panelAc() {
    NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Uyku Paneli.app"))
  }
  @objc func cik() { if kilitli { pmsetYaz(["-a","disablesleep","0"]) }; NSApp.terminate(nil) }
}

let uyg = NSApplication.shared
let t = MainActor.assumeIsolated { () -> Menu in
  let m = Menu(); uyg.delegate = m; uyg.setActivationPolicy(.accessory); return m
}
_ = t
uyg.run()
