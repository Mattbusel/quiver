import SwiftUI

// MARK: Arrow

struct ArrowView: View {
    @Environment(Store.self) private var store
    var body: some View {
        @Bindable var store = store
        let a = store.arrow
        let guide: (Double, String) = a.use == "target" ? (0, "target") : a.use == "small" ? (25, "small game") : a.use == "deer" ? (25, "deer and antelope") : a.use == "elk" ? (42, "elk, bear, boar") : (65, "moose and buffalo")
        Page {
            PageHeader(eyebrow: "Field notes", title: "The arrow.")
            ArrowDrawing(arrow: a)
            HStack(spacing: 12) {
                InkStat(value: f1(a.total, 0), unit: "gr", label: "total")
                InkStat(value: f1(a.foc), unit: "%", label: "FOC", color: a.foc >= 10 && a.foc <= 15 ? Kraft.fletchDeep : Kraft.amber)
                InkStat(value: f1(store.ke), unit: "ft·lb", label: store.estimated ? "KE (est.)" : "KE", color: guide.0 > 0 && store.ke < guide.0 ? Kraft.red : Kraft.ink)
            }.sheet()
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("Front of centre")
                FOCScale(foc: a.foc)
                Text(focNote(a.foc) + (guide.0 > 0 ? (store.ke < guide.0 ? " KE \(f1(store.ke, 0)) ft·lb is under the \(Int(guide.0)) suggested for \(guide.1)." : " KE clears the \(Int(guide.0)) ft·lb guideline for \(guide.1).") : "")).font(.note(13)).foregroundStyle(Kraft.ink2)
            }.sheet(tilt: 0.4)
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow("Spine starting point")
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text("\(store.spine)").font(.fig(40)).foregroundStyle(Kraft.ink)
                    Text("from an effective \(f1(store.effectiveWeight, 0)) lb").font(.note(13)).foregroundStyle(Kraft.ink2)
                }
                Text("Every 25 grains over 125 up front adds about 3 lb; every inch over 28\" adds 5 lb. Confirm with the maker's chart and a bare-shaft test.").font(.note(12)).foregroundStyle(Kraft.ink3)
            }.sheet(tilt: -0.3)
            VStack(spacing: 0) {
                Eyebrow("Components, grains").frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 4)
                Field(label: "Shaft length", hint: "inches, nock throat to end", value: $store.arrow.length)
                Field(label: "Shaft weight", hint: "grains per inch", value: $store.arrow.gpi)
                Field(label: "Diameter", hint: "inches, outside", value: $store.arrow.diameter)
                Field(label: "Point", value: $store.arrow.point)
                Field(label: "Insert", hint: "+ collar or outsert", value: $store.arrow.insert)
                Field(label: "Nock", hint: "+ bushing", value: $store.arrow.nock)
                Field(label: "Vane, each", value: $store.arrow.vane)
                Field(label: "Vane count", value: $store.arrow.vaneCount)
                Field(label: "Wrap and glue", value: $store.arrow.wrap)
                HStack { Text("Use").font(.note(14, .semibold)).foregroundStyle(Kraft.ink); Spacer()
                    Picker("Use", selection: $store.arrow.use) { Text("Target").tag("target"); Text("Small game").tag("small"); Text("Deer").tag("deer"); Text("Elk").tag("elk"); Text("Moose").tag("big") }.tint(Kraft.ink)
                }.padding(.vertical, 5)
            }.sheet()
        }
        .onChange(of: store.arrow.length) { store.save() }.onChange(of: store.arrow.gpi) { store.save() }.onChange(of: store.arrow.diameter) { store.save() }
        .onChange(of: store.arrow.point) { store.save() }.onChange(of: store.arrow.insert) { store.save() }.onChange(of: store.arrow.nock) { store.save() }
        .onChange(of: store.arrow.vane) { store.save() }.onChange(of: store.arrow.vaneCount) { store.save() }.onChange(of: store.arrow.wrap) { store.save() }.onChange(of: store.arrow.use) { store.save() }
    }
    func focNote(_ f: Double) -> String {
        f < 7 ? "Under 7%: tail-heavy, drifts in wind. Add point weight." : f <= 12 ? "7 to 12%: the classic target range. Flat and forgiving." : f <= 18 ? "12 to 18%: hunting territory. Better in wind and on penetration, a little more drop." : "Over 18%: very front heavy. Great penetration, needs a stiffer spine, drops faster."
    }
}

/// The arrow inked on the page, with balance point and centre marked.
struct ArrowDrawing: View {
    let arrow: Arrow
    var body: some View {
        Canvas { ctx, size in
            let L = arrow.length
            let x0 = 30.0, x1 = size.width - 30
            let px = (x1 - x0) / (L + 1.4)
            let X: (Double) -> Double = { x0 + $0 * px }
            let cy = size.height * 0.42
            let d = max(3, arrow.diameter * 30)
            ctx.fill(Path(roundedRect: CGRect(x: X(0), y: cy - d / 2, width: L * px, height: d), cornerRadius: 1.5), with: .color(Kraft.ink))
            for s in [-1.0, 1.0] {
                var v = Path()
                v.move(to: CGPoint(x: X(0.9), y: cy + s * d / 2)); v.addLine(to: CGPoint(x: X(1.5), y: cy + s * (d / 2 + 14))); v.addLine(to: CGPoint(x: X(3.4), y: cy + s * (d / 2 + 12))); v.addLine(to: CGPoint(x: X(3.8), y: cy + s * d / 2)); v.closeSubpath()
                ctx.fill(v, with: .color(s < 0 ? Kraft.fletch : Kraft.fletchDeep))
            }
            var nock = Path(); nock.move(to: CGPoint(x: X(-0.6), y: cy - 4)); nock.addLine(to: CGPoint(x: X(0), y: cy - 2.5)); nock.addLine(to: CGPoint(x: X(0), y: cy + 2.5)); nock.addLine(to: CGPoint(x: X(-0.6), y: cy + 4)); nock.closeSubpath()
            ctx.fill(nock, with: .color(Kraft.amber))
            ctx.fill(Path(CGRect(x: X(L), y: cy - d / 2 - 1, width: 0.7 * px, height: d + 2)), with: .color(Kraft.ink2))
            var tip = Path(); tip.move(to: CGPoint(x: X(L + 0.7), y: cy - d / 2 - 1)); tip.addLine(to: CGPoint(x: X(L + 1.3), y: cy)); tip.addLine(to: CGPoint(x: X(L + 0.7), y: cy + d / 2 + 1)); tip.closeSubpath()
            ctx.fill(tip, with: .color(Kraft.ink))
            // centre and balance
            var c = Path(); c.move(to: CGPoint(x: X(L / 2), y: cy - 26)); c.addLine(to: CGPoint(x: X(L / 2), y: cy + 26))
            ctx.stroke(c, with: .color(Kraft.ink3), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            ctx.draw(Text("centre").font(.note(10)).foregroundStyle(Kraft.ink3), at: CGPoint(x: X(L / 2), y: cy + 38))
            let bx = X(arrow.balance)
            var tri = Path(); tri.move(to: CGPoint(x: bx, y: cy + 10)); tri.addLine(to: CGPoint(x: bx - 7, y: cy + 22)); tri.addLine(to: CGPoint(x: bx + 7, y: cy + 22)); tri.closeSubpath()
            ctx.fill(tri, with: .color(Kraft.red))
            ctx.draw(Text("balance \(f1(arrow.balance, 2))\"").font(.note(11, .bold)).foregroundStyle(Kraft.red), at: CGPoint(x: bx, y: cy + 54))
            ctx.draw(Text("\(f1(L, 1))\" shaft · \(f1(arrow.shaft, 0)) gr").font(.note(11)).foregroundStyle(Kraft.ink2), at: CGPoint(x: X(L / 2), y: cy - 40))
            ctx.draw(Text("\(f1(arrow.point + arrow.insert, 0)) gr").font(.note(11)).foregroundStyle(Kraft.ink2), at: CGPoint(x: X(L + 0.6), y: cy - 40))
            ctx.draw(Text("\(f1(arrow.nock + arrow.fletch + arrow.wrap, 0)) gr").font(.note(11)).foregroundStyle(Kraft.ink2), at: CGPoint(x: X(1.8), y: cy - 40))
        }
        .frame(height: 150)
        .sheet(padding: 8, tilt: -0.6)
    }
}

struct FOCScale: View {
    let foc: Double
    var body: some View {
        GeometryReader { g in
            let pos = max(0, min(1, foc / 25)) * g.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(LinearGradient(colors: [Kraft.ink3, Kraft.fletch, Kraft.amber, Kraft.red], startPoint: .leading, endPoint: .trailing)).frame(height: 8)
                Circle().fill(Kraft.card).overlay(Circle().strokeBorder(Kraft.ink, lineWidth: 3)).frame(width: 20, height: 20).offset(x: pos - 10)
                ForEach([(0.28, "7 target"), (0.48, "12 hunt"), (0.72, "18 heavy")], id: \.0) { t in
                    Text(t.1).font(.note(9, .bold)).foregroundStyle(Kraft.ink3).position(x: t.0 * g.size.width, y: 26)
                }
            }
        }
        .frame(height: 34)
    }
}

// MARK: Bow

struct BowView: View {
    @Environment(Store.self) private var store
    var body: some View {
        @Bindable var store = store
        let zero = store.angle(forFeet: 60)
        Page {
            PageHeader(eyebrow: "Field notes", title: "Bow and speed.")
            HStack(spacing: 12) {
                InkStat(value: f1(store.speed, 0), unit: "fps", label: store.estimated ? "speed, est." : "speed, measured", color: Kraft.fletchDeep)
                InkStat(value: f1(store.flight(feet: 120).speed, 0), unit: "fps", label: "at 40 yd")
                InkStat(value: f1(store.momentum, 3), unit: "", label: "momentum")
            }.sheet()
            VStack(spacing: 0) {
                Eyebrow("Bow").frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 4)
                HStack { Text("Type").font(.note(14, .semibold)).foregroundStyle(Kraft.ink); Spacer()
                    Picker("Type", selection: $store.bow.type) { Text("Compound").tag("compound"); Text("Recurve").tag("recurve"); Text("Longbow").tag("trad") }.pickerStyle(.segmented).frame(width: 230)
                }.padding(.vertical, 5)
                Field(label: "Draw weight", hint: "lb at your draw", value: $store.bow.drawWeight)
                Field(label: "Draw length", hint: "inches, AMO", value: $store.bow.drawLength)
                Field(label: "Rated speed", hint: "IBO / ATA fps, compound", value: $store.bow.ibo)
                Field(label: "String extras", hint: "peep, loop, silencers: grains", value: $store.bow.stringExtras)
                Field(label: "Chronograph", hint: "fps, 0 to estimate instead", value: $store.bow.chrono)
            }.sheet()
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("Drop and drift, 20 yard zero")
                HStack { Text("yd").frame(width: 40, alignment: .leading); Text("time").frame(maxWidth: .infinity); Text("drop").frame(maxWidth: .infinity); Text("10 mph wind").frame(maxWidth: .infinity) }.font(.note(10, .heavy)).foregroundStyle(Kraft.ink3)
                ForEach([10, 20, 30, 40, 50, 60, 70, 80], id: \.self) { y in
                    let ft = Double(y) * 3
                    let fl = store.flight(feet: ft)
                    let drop = store.height(angle: zero, dist: ft) * 12
                    let drift = 14.67 * (fl.time - ft / store.speed) * 12
                    HStack { Text("\(y)").font(.fig(14)).frame(width: 40, alignment: .leading); Text(f1(fl.time, 3) + " s").frame(maxWidth: .infinity); Text(f1(drop, 1) + "\"").frame(maxWidth: .infinity); Text(f1(drift, 1) + "\"").frame(maxWidth: .infinity) }
                        .font(.mono(13)).foregroundStyle(Kraft.ink).padding(.vertical, 3).overlay(alignment: .bottom) { Rectangle().fill(Kraft.rule).frame(height: 0.7) }
                }
                Text(store.estimated ? "Speed is estimated from the rated speed, draw, arrow weight and string extras. A chronograph number makes the sight tape noticeably better." : "Using your chronograph speed with drag from the arrow's diameter, weight and vanes.").font(.note(12)).foregroundStyle(Kraft.ink3)
            }.sheet(tilt: 0.3)
        }
        .onChange(of: store.bow.type) { store.save() }.onChange(of: store.bow.drawWeight) { store.save() }.onChange(of: store.bow.drawLength) { store.save() }
        .onChange(of: store.bow.ibo) { store.save() }.onChange(of: store.bow.stringExtras) { store.save() }.onChange(of: store.bow.chrono) { store.save() }
    }
}

// MARK: Tape

struct TapeView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    var body: some View {
        @Bindable var store = store
        let fit = store.fit
        Page {
            PageHeader(eyebrow: "Field notes", title: "Sight tape.")
            VStack(spacing: 0) {
                Eyebrow("Your sight").frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 4)
                HStack { Text("Scale").font(.note(14, .semibold)).foregroundStyle(Kraft.ink); Spacer()
                    Picker("Scale", selection: $store.tape.unitMM) { Text("mm").tag(1.0); Text("½ mm").tag(0.5); Text("inch").tag(25.4); Text("clicks").tag(0.0) }.pickerStyle(.segmented).frame(width: 220)
                }.padding(.vertical, 5)
                if store.tape.unitMM == 0 { Field(label: "Clicks per mm", hint: "of sight travel", value: $store.tape.clicksPerMM) }
                HStack { Text("Distances").font(.note(14, .semibold)).foregroundStyle(Kraft.ink); Spacer()
                    Picker("Unit", selection: $store.tape.yards) { Text("yards").tag(true); Text("metres").tag(false) }.pickerStyle(.segmented).frame(width: 160)
                }.padding(.vertical, 5)
                Field(label: "From", value: $store.tape.from)
                Field(label: "To", value: $store.tape.to)
                Field(label: "Label every", value: $store.tape.every)
                Field(label: "Tape width", hint: "mm", value: $store.tape.widthMM)
            }.sheet()
            VStack(alignment: .leading, spacing: 6) {
                HStack { Eyebrow("Marks you shot"); Spacer(); Button { store.tape.marks.append(Mark(distance: 40, reading: 0)); store.save() } label: { Label("Add", systemImage: "plus").font(.note(12, .bold)).foregroundStyle(Kraft.ink) } }
                HStack { Text("distance").frame(width: 90, alignment: .leading); Text("sight reading").frame(maxWidth: .infinity, alignment: .leading); Text("").frame(width: 30) }.font(.note(10, .heavy)).foregroundStyle(Kraft.ink3)
                ForEach($store.tape.marks) { $m in
                    HStack(spacing: 8) {
                        TextField("", value: $m.distance, format: .number).keyboardType(.decimalPad).font(.fig(16)).foregroundStyle(Kraft.ink).frame(width: 90).overlay(alignment: .bottom) { Rectangle().fill(Kraft.ink.opacity(0.35)).frame(height: 1) }
                        TextField("", value: $m.reading, format: .number).keyboardType(.decimalPad).font(.fig(16)).foregroundStyle(Kraft.ink).overlay(alignment: .bottom) { Rectangle().fill(Kraft.ink.opacity(0.35)).frame(height: 1) }
                        Button { store.tape.marks.removeAll { $0.id == m.id }; store.save() } label: { Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(Kraft.ink3) }.buttonStyle(.plain).frame(width: 30)
                    }.padding(.vertical, 4)
                }
                Text("Shoot a tight group at two distances far apart (20 and 60 is ideal) and write down the reading. Higher numbers should mean the pin moved down. Three or more marks and the tape fits better.").font(.note(12)).foregroundStyle(Kraft.ink3).padding(.top, 4)
            }.sheet(tilt: -0.3)
            if let fit {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Marks")
                    let rows = stride(from: store.tape.from, through: store.tape.to, by: 5).map { $0 }
                    ForEach(rows, id: \.self) { d in
                        HStack { Text("\(Int(d))").font(.fig(15)).frame(width: 50, alignment: .leading); Text(f1(store.reading(at: d) ?? 0, 2)).font(.mono(14)); Spacer() }.foregroundStyle(Kraft.ink).padding(.vertical, 2).overlay(alignment: .bottom) { Rectangle().fill(Kraft.rule).frame(height: 0.7) }
                    }
                    if fit.b < 0 { Text("Your marks run backwards (further is a smaller number). Check them.").font(.note(12, .bold)).foregroundStyle(Kraft.red) }
                    else if fit.residuals.count > 2 { Text("Largest miss across your marks: \(f1(fit.residuals.map { abs($0) }.max() ?? 0, 2)) units.").font(.note(12)).foregroundStyle(Kraft.ink3) }
                }.sheet()
                InkButton(title: "Print or share the tape", icon: "printer", fill: Kraft.fletch) { router.showTape = true }
            } else {
                Text("Enter at least two sighted-in marks and the tape appears.").font(.note(13)).foregroundStyle(Kraft.ink2).sheet()
            }
        }
        .onChange(of: store.tape.unitMM) { store.save() }.onChange(of: store.tape.clicksPerMM) { store.save() }.onChange(of: store.tape.yards) { store.save() }
        .onChange(of: store.tape.from) { store.save() }.onChange(of: store.tape.to) { store.save() }.onChange(of: store.tape.every) { store.save() }.onChange(of: store.tape.widthMM) { store.save() }
        .onChange(of: store.tape.marks) { store.save() }
    }
}

/// The tape at true size (1 mm = 2.835 pt), shareable as a PDF that prints 1:1.
struct TapeShape: View {
    @Environment(Store.self) private var store
    static let pt: Double = 72 / 25.4
    var body: some View {
        let t = store.tape, mm = store.mmPerUnit
        let r0 = store.reading(at: t.from) ?? 0, r1 = store.reading(at: t.to) ?? 1
        let len = abs(r1 - r0) * mm + 16, W = t.widthMM
        let sign: Double = r1 >= r0 ? 1 : -1
        Canvas { ctx, size in
            let s = TapeShape.pt
            ctx.fill(Path(CGRect(x: 0, y: 0, width: W * s, height: len * s)), with: .color(.white))
            ctx.stroke(Path(CGRect(x: 0, y: 0, width: W * s, height: len * s)), with: .color(.gray), lineWidth: 0.5)
            var d = t.from
            while d <= t.to + 0.001 {
                guard let r = store.reading(at: d) else { break }
                let y = (8 + (r - r0) * mm * sign) * s
                let major = d.truncatingRemainder(dividingBy: t.every) == 0, mid = d.truncatingRemainder(dividingBy: 5) == 0
                let w = major ? W * 0.62 : mid ? W * 0.42 : W * 0.24
                var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w * s, y: y))
                ctx.stroke(p, with: .color(.black), lineWidth: major ? 1 : 0.6)
                if major { ctx.draw(Text("\(Int(d))").font(.system(size: min(3.4, W * 0.26) * s, weight: .bold)).foregroundStyle(.black), at: CGPoint(x: (W - 2.2) * s, y: y), anchor: .trailing) }
                else if mid && W >= 12 { ctx.draw(Text("\(Int(d))").font(.system(size: 2.2 * s)).foregroundStyle(Color(white: 0.3)), at: CGPoint(x: (W - 2) * s, y: y), anchor: .trailing) }
                d += 1
            }
            var bar = Path(); bar.move(to: CGPoint(x: (W + 4) * s, y: (len - 12) * s)); bar.addLine(to: CGPoint(x: (W + 4) * s, y: (len - 2) * s))
            ctx.stroke(bar, with: .color(.black), lineWidth: 0.8)
            ctx.draw(Text("10 mm").font(.system(size: 2.4 * s)).foregroundStyle(.black), at: CGPoint(x: (W + 6) * s, y: (len - 7) * s), anchor: .leading)
        }
        .frame(width: (W + 20) * TapeShape.pt, height: len * TapeShape.pt)
    }
}

struct TapePreview: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var pdf: URL? = nil
    var body: some View {
        VStack(spacing: 14) {
            HStack { Text("Sight tape").font(.hand(24, .bold)).foregroundStyle(Kraft.ink); Spacer(); Button("Done") { dismiss() }.font(.note(15, .bold)).foregroundStyle(Kraft.ink) }.padding(.top, 20)
            Text("Shown at true size on this screen. Share as PDF and print at 100%, no scaling; check the 10 mm bar with a ruler.").font(.note(13)).foregroundStyle(Kraft.ink2)
            ScrollView { HStack { Spacer(); TapeShape().padding(20).background(Color.white.opacity(0.4)); Spacer() } }
            if let pdf { ShareLink(item: pdf) { Label("Share PDF", systemImage: "square.and.arrow.up").font(.hand(16, .bold)).foregroundStyle(Kraft.card).frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 8).fill(Kraft.ink)) } }
            else { InkButton(title: "Make the PDF", icon: "doc") { pdf = render() } }
        }
        .padding(.horizontal, 18).padding(.bottom, 20)
        .onAppear { if pdf == nil { pdf = render() } }
    }

    @MainActor func render() -> URL? {
        let view = TapeShape().environment(store)
        let renderer = ImageRenderer(content: view)
        let url = URL.documentsDirectory.appending(path: "sight-tape.pdf")
        var box = CGRect(x: 0, y: 0, width: 595, height: 842)   // A4 in points
        guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { return nil }
        renderer.render { size, draw in
            ctx.beginPDFPage(nil)
            ctx.translateBy(x: 40, y: 842 - size.height - 40)
            draw(ctx)
            ctx.endPDFPage()
        }
        ctx.closePDF()
        return url
    }
}
