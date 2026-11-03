import AppKit

// Çıktı klasörü: ilk argüman verilirse oraya, yoksa çalışılan klasöre yazar.
// (Önceden sabit bir ev dizini yolu yazılıydı; başka makinede çalışmıyordu.)
let cikti = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath
func ciktiYolu(_ ad: String) -> String { (cikti as NSString).appendingPathComponent(ad) }

// ══════════════════════════════════════════════════════════════
//  UYKU KILIDI — "KARANLIK LUKS"
//  Neredeyse siyah gok, tek ince altin hilal, tek kivilcim.
// ══════════════════════════════════════════════════════════════

let S: CGFloat = 1024, pad: CGFloat = 88
let plate = CGRect(x: pad, y: pad, width: S - 2*pad, height: S - 2*pad)
let rad   = plate.width * 0.2265

func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
  NSColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a)
}
func rc(_ p: NSPoint, _ r0: CGFloat, _ r1: CGFloat, _ cols: [NSColor], _ locs: [CGFloat]? = nil) {
  let g = locs == nil ? NSGradient(colors: cols)!
                      : NSGradient(colors: cols, atLocations: locs!, colorSpace: .sRGB)!
  g.draw(fromCenter: p, radius: r0, toCenter: p, radius: r1, options: [])
}

// ── GEOMETRI ────────────────────────────────────────────────
// Hilal plaka merkezinin biraz sol-altinda; kivilcim sag-ustte.
// Aradaki bosluk kompozisyonun asil malzemesi.
let cx: CGFloat = 502, cy: CGFloat = 496
let R:  CGFloat = 294                 // dis yaricap
let dx: CGFloat = 104, dy: CGFloat = 50   // ic dairenin kaymasi
let ir: CGFloat = R                   // ir == R  →  sivri, keskin uclar
// kalinlik = R - (ir - d) = d = 115.4  →  0.39R  (ince ama 16px'te ayakta)
let disR   = NSRect(x: cx-R,     y: cy-R,     width: 2*R,  height: 2*R)
let innerR = NSRect(x: cx-ir+dx, y: cy-ir+dy, width: 2*ir, height: 2*ir)

let starX: CGFloat = 660, starY: CGFloat = 600, starS: CGFloat = 62

let img = NSImage(size: NSSize(width: S, height: S)); img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext
ctx.setShouldAntialias(true); ctx.interpolationQuality = .high

let body = NSBezierPath(roundedRect: plate, xRadius: rad, yRadius: rad)

// ══ 1. GOK — neredeyse siyah, tek parca degrade (dikis yok) ══
NSGraphicsContext.saveGraphicsState()
body.addClip()

NSGradient(colors: [c(24, 26, 33), c(15, 16, 22), c(8, 8, 12), c(4, 4, 6)],
           atLocations: [0, 0.32, 0.74, 1], colorSpace: .sRGB)!
  .draw(in: plate, angle: -90)

// koselere dogru sessiz bir karartma — plaka "derinlesir"
rc(NSPoint(x: plate.midX, y: plate.midY + 40), plate.width*0.30, plate.width*0.80,
   [NSColor(white: 0, alpha: 0), NSColor(white: 0, alpha: 0.30), NSColor(white: 0, alpha: 0.62)],
   [0, 0.55, 1])

// ══ 2. AYIN SICAK NEFESI — cok dusuk alfa, genis ══
rc(NSPoint(x: cx - 34, y: cy + 10), 0, R * 2.30,
   [c(214, 158, 74, 0.20), c(198, 140, 66, 0.075), c(180, 126, 60, 0)],
   [0, 0.40, 1])

// ══ 3. TEK KIVILCIM ══
// genis hale (cok soluk) + sıkı cekirdek hale + dort kollu isik
rc(NSPoint(x: starX, y: starY), 0, starS * 3.0,
   [c(255, 226, 168, 0.10), c(255, 220, 160, 0)])
rc(NSPoint(x: starX, y: starY), 0, starS * 2.0,
   [c(255, 240, 205, 0.16), c(255, 232, 186, 0)])

func kivilcim(_ x: CGFloat, _ y: CGFloat, _ ry: CGFloat, _ rx: CGFloat,
              _ waist: CGFloat, _ col: NSColor) {
  let p = NSBezierPath(); let kx = rx*waist, ky = ry*waist
  p.move(to: NSPoint(x: x, y: y+ry))
  p.curve(to: NSPoint(x: x+rx, y: y), controlPoint1: NSPoint(x: x+kx, y: y+ky), controlPoint2: NSPoint(x: x+kx, y: y+ky))
  p.curve(to: NSPoint(x: x, y: y-ry), controlPoint1: NSPoint(x: x+kx, y: y-ky), controlPoint2: NSPoint(x: x+kx, y: y-ky))
  p.curve(to: NSPoint(x: x-rx, y: y), controlPoint1: NSPoint(x: x-kx, y: y-ky), controlPoint2: NSPoint(x: x-kx, y: y-ky))
  p.curve(to: NSPoint(x: x, y: y+ry), controlPoint1: NSPoint(x: x-kx, y: y+ky), controlPoint2: NSPoint(x: x-kx, y: y+ky))
  col.setFill(); p.fill()
}
// uzun-ince dort kol (altin) + icinde beyaz cekirdek
kivilcim(starX, starY, starS,       starS*0.30, 0.10, c(246, 214, 150, 0.92))
kivilcim(starX, starY, starS*0.30,  starS,      0.10, c(246, 214, 150, 0.92))
kivilcim(starX, starY, starS*0.52,  starS*0.20, 0.14, c(255, 250, 238, 1.0))
kivilcim(starX, starY, starS*0.20,  starS*0.52, 0.14, c(255, 250, 238, 1.0))

NSGraphicsContext.restoreGraphicsState()

// ══ 4. HILAL ══
ctx.saveGState()
body.addClip()
ctx.setShadow(offset: CGSize(width: -4, height: -14), blur: 46, color: c(0, 0, 0, 0.75).cgColor)
ctx.beginTransparencyLayer(auxiliaryInfo: nil)

// 4a — tam disk: altin → bakir degrade (isik sol-ust)
NSGraphicsContext.saveGraphicsState()
NSBezierPath(ovalIn: disR).addClip()
NSGradient(colors: [c(255, 247, 226), c(247, 219, 158), c(214, 165, 91), c(150, 100, 46)],
           atLocations: [0, 0.30, 0.68, 1], colorSpace: .sRGB)!
  .draw(in: disR, angle: -56)
NSGraphicsContext.restoreGraphicsState()

// 4b — ic daireyi oy  → hilal dogar
ctx.setBlendMode(.destinationOut)
NSBezierPath(ovalIn: innerR).fill()

// 4c — bundan sonrasi yalnizca hilalin uzerine isler
ctx.setBlendMode(.sourceAtop)

// dis kenarda ince parlak cizgi (sol-ust)
ctx.saveGState()
ctx.addEllipse(in: disR.insetBy(dx: 5, dy: 5))
ctx.setLineWidth(10)
ctx.replacePathWithStrokedPath()
ctx.clip()
NSGradient(colors: [NSColor(white: 1, alpha: 0.88), NSColor(white: 1, alpha: 0.22), NSColor(white: 1, alpha: 0)],
           atLocations: [0, 0.34, 0.62], colorSpace: .sRGB)!
  .draw(in: disR, angle: -52)
ctx.restoreGState()

// ic kesim kenarinda yumusak koyulasma → hacim hissi
ctx.saveGState()
ctx.addEllipse(in: innerR.insetBy(dx: -13, dy: -13))
ctx.setLineWidth(30)
ctx.replacePathWithStrokedPath()
ctx.clip()
NSGradient(colors: [c(78, 46, 16, 0.0), c(78, 46, 16, 0.34)],
           atLocations: [0, 1], colorSpace: .sRGB)!
  .draw(in: disR, angle: -56)
ctx.restoreGState()

// govdenin alt-sag ucunda bakir derinlik
NSGradient(colors: [c(96, 58, 22, 0), c(96, 58, 22, 0), c(96, 58, 22, 0.42)],
           atLocations: [0, 0.52, 1], colorSpace: .sRGB)!
  .draw(in: disR, angle: -64)

ctx.setBlendMode(.normal)
ctx.endTransparencyLayer()
ctx.restoreGState()

// ══ 5. PLAKA KENARI — altin sac teli ══
let rim = NSBezierPath(roundedRect: plate.insetBy(dx: 1.5, dy: 1.5),
                       xRadius: rad-1.5, yRadius: rad-1.5)
rim.lineWidth = 3
c(226, 190, 128, 0.16).setStroke(); rim.stroke()

img.unlockFocus()
try! NSBitmapImageRep(data: img.tiffRepresentation!)!
  .representation(using: .png, properties: [:])!
  .write(to: URL(fileURLWithPath: ciktiYolu("ay-yildiz-v2.png")))

// ══ KUCUK BOYUT SINAVI ══
let tw: CGFloat = 900, th: CGFloat = 430
let test = NSImage(size: NSSize(width: tw, height: th)); test.lockFocus()
let src = NSImage(contentsOfFile: ciktiYolu("ay-yildiz-v2.png"))!
// ust serit: koyu dock
c(28, 28, 31).setFill(); NSRect(x: 0, y: 215, width: tw, height: 215).fill()
// alt serit: acik dock
c(224, 224, 228).setFill(); NSRect(x: 0, y: 0, width: tw, height: 215).fill()
for (i, yb) in [CGFloat(215), CGFloat(0)].enumerated() {
  _ = i
  src.draw(in: NSRect(x: 16,  y: yb+8,   width: 196, height: 196))
  src.draw(in: NSRect(x: 226, y: yb+42,  width: 128, height: 128))
  src.draw(in: NSRect(x: 372, y: yb+74,  width: 64,  height: 64))
  src.draw(in: NSRect(x: 452, y: yb+90,  width: 32,  height: 32))
  src.draw(in: NSRect(x: 500, y: yb+98,  width: 16,  height: 16))
  // 16px'i 6x buyutulmus halde (piksel okunurlugu)
  NSGraphicsContext.current!.imageInterpolation = .none
  let small = NSImage(size: NSSize(width: 16, height: 16)); small.lockFocus()
  src.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16)); small.unlockFocus()
  small.draw(in: NSRect(x: 540, y: yb+11, width: 96, height: 96))
  let s32 = NSImage(size: NSSize(width: 32, height: 32)); s32.lockFocus()
  src.draw(in: NSRect(x: 0, y: 0, width: 32, height: 32)); s32.unlockFocus()
  s32.draw(in: NSRect(x: 650, y: yb+11, width: 192, height: 192))
  NSGraphicsContext.current!.imageInterpolation = .high
}
test.unlockFocus()
try! NSBitmapImageRep(data: test.tiffRepresentation!)!
  .representation(using: .png, properties: [:])!
  .write(to: URL(fileURLWithPath: ciktiYolu("ay-yildiz-v2-test.png")))
print("var-6 + boyut sinavi hazir")
