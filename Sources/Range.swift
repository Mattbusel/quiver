import SwiftUI

// MARK: Rounds and faces

/// How a face scores. Positions are stored in face radii: (0, 0) is the centre, 1 is the outer edge, y is up.
enum Face: String, Codable {
    case wa10, nfaa5, threeD

    /// Score and X for an arrow at radius r (in face radii).
    func score(r: Double) -> (Int, Bool) {
        switch self {
        case .wa10: return r > 1 ? (0, false) : (max(1, 10 - Int(r * 10)), r <= 0.05)
        case .nfaa5: return r > 1 ? (0, false) : (max(1, 5 - Int(r * 5)), r <= 0.1)
        case .threeD: return (0, false)
        }
    }
    var top: Int { self == .nfaa5 ? 5 : self == .threeD ? 12 : 10 }
}

struct Round: Identifiable, Hashable {
    let id: String
    let name: String
    let face: Face
    let perEnd: Int
    let ends: Int?          // nil: open practice
    let distance: Double
    let yards: Bool
    let faceCm: Double
    let blurb: String
    var maxScore: Int? { ends.map { $0 * perEnd * face.top } }

    static let all: [Round] = [
        Round(id: "wa18", name: "WA 18 m indoor", face: .wa10, perEnd: 3, ends: 20, distance: 18, yards: false, faceCm: 40, blurb: "60 arrows on a 40 cm face, ends of three. Out of 600."),
        Round(id: "wa70", name: "WA 70 m", face: .wa10, perEnd: 6, ends: 12, distance: 70, yards: false, faceCm: 122, blurb: "The Olympic recurve distance. 72 arrows, 122 cm face. Out of 720."),
        Round(id: "wa50", name: "WA 50 m compound", face: .wa10, perEnd: 6, ends: 12, distance: 50, yards: false, faceCm: 80, blurb: "72 arrows on an 80 cm face. Out of 720."),
        Round(id: "nfaa300", name: "NFAA 300", face: .nfaa5, perEnd: 5, ends: 12, distance: 20, yards: true, faceCm: 40, blurb: "Blue face, five-ring scoring, 20 yards. 60 arrows, out of 300."),
        Round(id: "vegas", name: "Vegas 450", face: .wa10, perEnd: 3, ends: 10, distance: 20, yards: true, faceCm: 40, blurb: "30 arrows at 20 yards, ends of three. Out of 450 on the ten-ring."),
        Round(id: "3d", name: "3D course", face: .threeD, perEnd: 1, ends: 20, distance: 30, yards: true, faceCm: 30, blurb: "20 targets, one arrow each. 12, 11, 10, 8, 5 or a miss."),
        Round(id: "practice", name: "Practice", face: .wa10, perEnd: 6, ends: nil, distance: 30, yards: true, faceCm: 80, blurb: "Any distance, as many ends as you like. Best for checking a sight mark."),
    ]
    static func byID(_ id: String) -> Round { all.first { $0.id == id } ?? all[all.count - 1] }
}

struct Shot: Codable, Hashable {
    var x: Double? = nil
    var y: Double? = nil
    var score: Int
    var x10: Bool = false
}

struct End: Codable, Identifiable, Hashable {
    var id = UUID()
    var shots: [Shot] = []
    var total: Int { shots.reduce(0) { $0 + $1.score } }
}

struct Session: Codable, Identifiable, Hashable {
    var id = UUID()
    var date = Date()
    var round: String
    var distance: Double
    var yards: Bool
    var faceCm: Double
    var setup: String
    /// The sight reading the round was shot with, so the group can correct the tape.
    var sightReading: Double? = nil
    var ends: [End] = []
    var note: String = ""

    var info: Round { Round.byID(round) }
    var shots: [Shot] { ends.flatMap(\.shots) }
    var total: Int { ends.reduce(0) { $0 + $1.total } }
    var xs: Int { shots.filter(\.x10).count }
    var arrows: Int { shots.count }
    var average: Double { arrows == 0 ? 0 : Double(total) / Double(arrows) }
    var maxSoFar: Int { arrows * info.face.top }
    var percent: Double { maxSoFar == 0 ? 0 : Double(total) / Double(maxSoFar) }
    var distanceText: String { "\(f1(distance, distance.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1)) \(yards ? "yd" : "m")" }

    /// Centre of the group and its mean spread, in centimetres on the face (y up). Nil without placed arrows.
    var group: (x: Double, y: Double, spread: Double, count: Int)? {
        let placed = shots.compactMap { s -> (Double, Double)? in
            guard let x = s.x, let y = s.y else { return nil }
            return (x, y)
        }
        guard placed.count >= 3 else { return nil }
        let half = faceCm / 2
        let mx = placed.map(\.0).reduce(0, +) / Double(placed.count) * half
        let my = placed.map(\.1).reduce(0, +) / Double(placed.count) * half
        let spread = placed.map { (($0.0 * half - mx) * ($0.0 * half - mx) + ($0.1 * half - my) * ($0.1 * half - my)).squareRoot() }.reduce(0, +) / Double(placed.count)
        return (mx, my, spread, placed.count)
    }

    /// How far to move the sight, in millimetres at the sight, to bring the group centre to the middle.
    /// Follow the arrow: a high group means the sight goes up.
    func correction(sightRadiusInches: Double) -> (up: Double, right: Double)? {
        guard let g = group else { return nil }
        let distMM = distance * (yards ? 914.4 : 1000)
        let k = sightRadiusInches * 25.4 / max(1, distMM)
        return (g.y * 10 * k, g.x * 10 * k)
    }

    static func csv(_ all: [Session]) -> String {
        var rows = ["date,round,distance,unit,setup,end,arrow,score,x,pos_x_cm,pos_y_cm"]
        let f = ISO8601DateFormatter()
        for s in all {
            for (e, end) in s.ends.enumerated() {
                for (k, sh) in end.shots.enumerated() {
                    let px = sh.x.map { f1($0 * s.faceCm / 2, 2) } ?? "", py = sh.y.map { f1($0 * s.faceCm / 2, 2) } ?? ""
                    rows.append([f.string(from: s.date), s.info.name, f1(s.distance, 1), s.yards ? "yd" : "m", "\"" + s.setup.replacingOccurrences(of: "\"", with: "\"\"") + "\"",
                                 "\(e + 1)", "\(k + 1)", "\(sh.score)", sh.x10 ? "1" : "0", px, py].joined(separator: ","))
                }
            }
        }
        return rows.joined(separator: "\n")
    }

    static func demo() -> [Session] {
        var seed: UInt64 = 11
        func r() -> Double { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Double((seed >> 33) % 10_000) / 10_000 }
        func gauss() -> Double { (r() + r() + r() + r() - 2) / 2 }
        var out: [Session] = []
        let plan: [(String, Double, Double, Double, Int)] = [("wa18", 0.20, -0.06, 0.04, 0), ("vegas", 0.18, 0.02, -0.05, 2), ("wa18", 0.22, 0.05, 0.02, 5),
                                                              ("nfaa300", 0.3, -0.03, 0.03, 8), ("wa18", 0.25, 0.08, -0.04, 12), ("practice", 0.16, 0.03, -0.11, 0)]
        for (i, p) in plan.enumerated().reversed() {
            let rd = Round.byID(p.0)
            var s = Session(round: rd.id, distance: rd.distance, yards: rd.yards, faceCm: rd.faceCm, setup: "Hunting rig")
            s.date = Calendar.current.date(byAdding: .day, value: -p.4 - (i == 5 ? 0 : 1), to: .now) ?? .now
            if rd.id == "practice" { s.distance = 40; s.yards = true; s.sightReading = 24.3 }
            let ends = rd.ends ?? 4
            for e in 0..<(i == 5 ? 4 : ends) {
                var end = End()
                for _ in 0..<rd.perEnd {
                    let x = p.2 + gauss() * p.1, y = p.3 + gauss() * p.1 - Double(e) * 0.002
                    let (sc, x10) = rd.face.score(r: (x * x + y * y).squareRoot())
                    end.shots.append(Shot(x: x, y: y, score: sc, x10: x10))
                }
                s.ends.append(end)
            }
            if i == 0 { s.note = "Felt the shot break clean. Wind from the left." }
            out.append(s)
        }
        return out.sorted { $0.date > $1.date }
    }
}

// MARK: The Range tab

struct RangeView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(Pro.self) private var pro
    @State private var picking = false
    @State private var csv: URL? = nil
    var body: some View {
        Page {
            PageHeader(eyebrow: "Score book", title: "The range.")
            Button { picking = true } label: {
                HStack(spacing: 14) {
                    FaceIcon().frame(width: 58, height: 58)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Shoot a round").font(.hand(20, .bold)).foregroundStyle(Kraft.ink)
                        Text("Tap where each arrow lands. Quiver scores it and reads your group.").font(.note(12.5)).foregroundStyle(Kraft.ink2).multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .heavy)).foregroundStyle(Kraft.ink)
                }.sheet(padding: 14, tilt: -0.4)
            }.buttonStyle(.plain)
            if store.sessions.isEmpty {
                Text("No rounds yet. Shoot a practice end at one of your sight marks: if the group sits off centre, Quiver tells you which way to move the sight and corrects the mark.").font(.note(13)).foregroundStyle(Kraft.ink2).sheet(tilt: 0.3)
            } else {
                if pro.unlocked { TrendCard() } else {
                    LockedBlock(reason: .trends, title: "Your scores over time") { TrendSample().sheet(tilt: 0.3) }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow("Rounds shot")
                    ForEach(store.sessions) { s in
                        Button { router.session = s.id } label: { SessionRow(session: s) }.buttonStyle(.plain)
                    }
                    if pro.unlocked, let csv {
                        ShareLink(item: csv) { Label("Export the score book (CSV)", systemImage: "tablecells").font(.note(13, .bold)).foregroundStyle(Kraft.ink) }.padding(.top, 8)
                    } else if !pro.unlocked {
                        Button { pro.ask(.export) } label: { Label("Export the score book (Pro)", systemImage: "lock").font(.note(13, .bold)).foregroundStyle(Kraft.ink2) }.buttonStyle(.plain).padding(.top, 8)
                    }
                }.sheet()
            }
        }
        .sheet(isPresented: $picking) { RoundPicker().presentationBackground(Kraft.paper).presentationDetents([.large]) }
        .task(id: store.sessions.count) {
            guard pro.unlocked else { return }
            let u = URL.temporaryDirectory.appending(path: "Quiver score book.csv")
            try? Session.csv(store.sessions).write(to: u, atomically: true, encoding: .utf8)
            csv = u
        }
    }
}

struct SessionRow: View {
    let session: Session
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.info.name).font(.hand(16, .bold)).foregroundStyle(Kraft.ink)
                Text("\(session.date.formatted(.dateTime.month(.abbreviated).day())) · \(session.distanceText) · \(session.setup)").font(.note(11.5)).foregroundStyle(Kraft.ink3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(session.total)").font(.fig(22)).foregroundStyle(Kraft.ink)
                    if let m = session.info.maxScore { Text("/\(m)").font(.note(11, .bold)).foregroundStyle(Kraft.ink3) }
                }
                Text(session.xs > 0 ? "\(session.xs) X · \(f1(session.average, 2)) avg" : "\(f1(session.average, 2)) avg").font(.note(10.5, .bold)).foregroundStyle(Kraft.fletchDeep)
            }
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Rectangle().fill(Kraft.rule).frame(height: 0.7) }
        .contentShape(Rectangle())
    }
}

/// A little inked target, the Range card's icon.
struct FaceIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2), R = min(size.width, size.height) / 2
            let cols: [Color] = [Kraft.card, Kraft.ink, Kraft.ink2, Kraft.red, Kraft.fletch]
            for (i, col) in cols.enumerated() {
                let rr = R * (1 - Double(i) * 0.19)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2)), with: .color(col))
            }
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - R, y: c.y - R, width: R * 2, height: R * 2)), with: .color(Kraft.ink), lineWidth: 1.2)
            for (dx, dy) in [(0.12, -0.08), (-0.05, 0.1), (0.02, 0.02)] {
                ctx.fill(Path(ellipseIn: CGRect(x: c.x + dx * R * 2 - 2.5, y: c.y + dy * R * 2 - 2.5, width: 5, height: 5)), with: .color(Kraft.card))
            }
        }
    }
}

struct RoundPicker: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var chosen = Round.all[0]
    @State private var distance = 18.0
    @State private var yards = false
    @State private var reading: Double? = nil
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack { Text("Which round?").font(.hand(28, .bold)).foregroundStyle(Kraft.ink); Spacer(); Button("Cancel") { dismiss() }.font(.note(15, .bold)).foregroundStyle(Kraft.ink2) }.padding(.top, 22)
                VStack(spacing: 0) {
                    ForEach(Round.all) { r in
                        Button { chosen = r; distance = r.distance; yards = r.yards; suggest() } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: chosen == r ? "largecircle.fill.circle" : "circle").font(.system(size: 18, weight: .bold)).foregroundStyle(Kraft.ink)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.name).font(.hand(16, .bold)).foregroundStyle(Kraft.ink)
                                    Text(r.blurb).font(.note(12)).foregroundStyle(Kraft.ink2).multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 0)
                            }.padding(.vertical, 8).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }.sheet()
                VStack(spacing: 0) {
                    Eyebrow("Shooting").frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 4)
                    Field(label: "Distance", hint: yards ? "yards" : "metres", value: $distance)
                    HStack { Text("Unit").font(.note(14, .semibold)).foregroundStyle(Kraft.ink); Spacer()
                        Picker("Unit", selection: $yards) { Text("yards").tag(true); Text("metres").tag(false) }.pickerStyle(.segmented).frame(width: 160)
                    }.padding(.vertical, 5)
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Sight reading").font(.note(14, .semibold)).foregroundStyle(Kraft.ink)
                            Text("optional: lets the group correct your tape").font(.note(11)).foregroundStyle(Kraft.ink3)
                        }
                        Spacer()
                        TextField("–", value: $reading, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .font(.fig(17)).foregroundStyle(Kraft.ink).frame(width: 88, height: 34)
                            .overlay(alignment: .bottom) { Rectangle().fill(Kraft.ink.opacity(0.35)).frame(height: 1) }
                    }.padding(.vertical, 5)
                }.sheet(tilt: -0.3)
                InkButton(title: "Start · \(store.currentName)", icon: "scope", fill: Kraft.fletch) {
                    var s = Session(round: chosen.id, distance: distance, yards: yards, faceCm: chosen.faceCm, setup: store.currentName)
                    s.sightReading = reading
                    s.ends = [End()]
                    store.sessions.insert(s, at: 0)
                    store.save()
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { router.scoring = s.id }
                }
            }.padding(.leading, 30).padding(.trailing, 18).padding(.bottom, 30)
        }
        .onAppear { suggest() }
    }
    /// Fill the sight reading in from the tape when it has a fit, converted to the tape's distance unit.
    func suggest() {
        let d = yards == store.tape.yards ? distance : yards ? distance * 0.9144 : distance / 0.9144
        if let r = store.reading(at: d) { reading = (r * 100).rounded() / 100 } else { reading = nil }
    }
}

// MARK: Scoring

struct ScoringView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var finished = false
    var body: some View {
        if let i = store.sessions.firstIndex(where: { $0.id == id }) {
            let s = store.sessions[i], rd = s.info
            let endIndex = max(0, s.ends.count - 1)
            let end = s.ends.last ?? End()
            let full = end.shots.count >= rd.perEnd
            let done = rd.ends.map { s.ends.count >= $0 && full } ?? false
            ZStack {
                PaperBackground()
                VStack(spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Eyebrow(rd.name + " · " + s.distanceText)
                            Text(rd.ends.map { "End \(min(endIndex + 1, $0)) of \($0)" } ?? "End \(endIndex + 1)").font(.hand(26, .bold)).foregroundStyle(Kraft.ink)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(s.total)").font(.fig(34)).foregroundStyle(Kraft.ink).contentTransition(.numericText())
                            Text(s.xs > 0 ? "\(s.xs) X" : "total").font(.note(11, .heavy)).foregroundStyle(Kraft.fletchDeep)
                        }
                    }.padding(.top, 18)
                    if rd.face == .threeD {
                        ThreeDPad { sc, x in add(i, Shot(score: sc, x10: x)) }.disabled(full)
                    } else {
                        TargetFace(face: rd.face, shots: s.shots, current: end.shots, onTap: full ? nil : tapper(i, rd.face))
                        .aspectRatio(1, contentMode: .fit)
                    }
                    HStack(spacing: 8) {
                        ForEach(0..<rd.perEnd, id: \.self) { k in
                            let sh = k < end.shots.count ? end.shots[k] : nil
                            Text(sh.map { $0.x10 ? "X" : $0.score == 0 ? "M" : "\($0.score)" } ?? "·")
                                .font(.fig(20)).foregroundStyle(sh == nil ? Kraft.ink3 : Kraft.ink)
                                .frame(maxWidth: .infinity).frame(height: 44)
                                .background(RoundedRectangle(cornerRadius: 6).fill(sh == nil ? Kraft.card.opacity(0.5) : Kraft.card))
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Kraft.ink.opacity(0.15)))
                        }
                        Text("\(end.total)").font(.fig(20)).foregroundStyle(Kraft.fletchDeep).frame(width: 46)
                    }
                    HStack(spacing: 10) {
                        Button { undo(i) } label: { Label("Undo", systemImage: "arrow.uturn.backward").font(.note(14, .bold)).foregroundStyle(Kraft.ink2) }
                            .buttonStyle(.plain).disabled(s.shots.isEmpty)
                        Spacer()
                        if done || (rd.ends == nil && full) || (rd.ends == nil && !s.shots.isEmpty) {
                            Button { finish(i) } label: { Text("Finish").font(.note(14, .bold)).foregroundStyle(Kraft.ink) }.buttonStyle(.plain)
                        }
                    }
                    if full && !done {
                        InkButton(title: "Next end", icon: "arrow.right", fill: Kraft.fletch) {
                            store.sessions[i].ends.append(End()); store.save()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    } else if done {
                        InkButton(title: "Done: see the group", icon: "checkmark", fill: Kraft.fletch) { finish(i) }
                    } else {
                        Text(rd.face == .threeD ? "Tap the ring the arrow scored." : "Tap where the arrow landed. Hold a finger still and lift: the dot lands where you let go.").font(.note(12)).foregroundStyle(Kraft.ink3)
                    }
                    Spacer(minLength: 0)
                }.padding(.horizontal, 20)
            }
        }
    }
    func tapper(_ i: Int, _ face: Face) -> ((Double, Double) -> Void) {
        { x, y in
            let (sc, x10) = face.score(r: (x * x + y * y).squareRoot())
            add(i, Shot(x: x, y: y, score: sc, x10: x10))
        }
    }
    func add(_ i: Int, _ shot: Shot) {
        if store.sessions[i].ends.isEmpty { store.sessions[i].ends.append(End()) }
        let last = store.sessions[i].ends.count - 1
        store.sessions[i].ends[last].shots.append(shot)
        store.save()
        UIImpactFeedbackGenerator(style: shot.score >= store.sessions[i].info.face.top - 1 ? .heavy : .light).impactOccurred()
    }
    func undo(_ i: Int) {
        var ends = store.sessions[i].ends
        if let last = ends.indices.last, ends[last].shots.isEmpty, ends.count > 1 { ends.removeLast() }
        if let last = ends.indices.last, !ends[last].shots.isEmpty { ends[last].shots.removeLast() }
        store.sessions[i].ends = ends
        store.save()
    }
    func finish(_ i: Int) {
        store.sessions[i].ends.removeAll { $0.shots.isEmpty }
        if store.sessions[i].ends.isEmpty { store.sessions.remove(at: i) }
        store.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

/// The face, inked. Taps come back in face radii, y up.
struct TargetFace: View {
    let face: Face
    let shots: [Shot]
    var current: [Shot] = []
    var showGroup: (x: Double, y: Double, spread: Double)? = nil
    var onTap: ((Double, Double) -> Void)? = nil
    var body: some View {
        GeometryReader { g in
            let side = min(g.size.width, g.size.height)
            let R = side / 2 * 0.94
            let c = CGPoint(x: g.size.width / 2, y: g.size.height / 2)
            Canvas { ctx, _ in
                draw(&ctx, c: c, R: R)
                for s in shots where !current.contains(s) { dot(&ctx, s, c: c, R: R, fill: Kraft.ink.opacity(0.35), size: 7) }
                for s in current { dot(&ctx, s, c: c, R: R, fill: Kraft.fletch, size: 11) }
                if let gr = showGroup {
                    let gx = c.x + gr.x * R, gy = c.y - gr.y * R
                    var h = Path(); h.move(to: CGPoint(x: gx - 12, y: gy)); h.addLine(to: CGPoint(x: gx + 12, y: gy)); h.move(to: CGPoint(x: gx, y: gy - 12)); h.addLine(to: CGPoint(x: gx, y: gy + 12))
                    ctx.stroke(h, with: .color(Kraft.fletch), lineWidth: 3)
                    let sr = gr.spread * R
                    ctx.stroke(Path(ellipseIn: CGRect(x: gx - sr, y: gy - sr, width: sr * 2, height: sr * 2)), with: .color(Kraft.fletch), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onEnded { v in
                guard let onTap else { return }
                let x = (v.location.x - c.x) / R, y = -(v.location.y - c.y) / R
                guard (x * x + y * y).squareRoot() <= 1.15 else { return }
                onTap(x, y)
            })
        }
    }
    func dot(_ ctx: inout GraphicsContext, _ s: Shot, c: CGPoint, R: Double, fill: Color, size: Double) {
        guard let x = s.x, let y = s.y else { return }
        let p = CGPoint(x: c.x + x * R, y: c.y - y * R)
        let rect = CGRect(x: p.x - size / 2, y: p.y - size / 2, width: size, height: size)
        ctx.fill(Path(ellipseIn: rect), with: .color(fill))
        ctx.stroke(Path(ellipseIn: rect), with: .color(Kraft.ink), lineWidth: 1.2)
    }
    func draw(_ ctx: inout GraphicsContext, c: CGPoint, R: Double) {
        func ring(_ f: Double, _ col: Color, _ line: Color) {
            let rr = R * f
            let rect = CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(col))
            ctx.stroke(Path(ellipseIn: rect), with: .color(line), lineWidth: 0.8)
        }
        switch face {
        case .wa10:
            let gold = Color(red: 0.98, green: 0.84, blue: 0.20), red = Color(red: 0.86, green: 0.20, blue: 0.18), blue = Color(red: 0.18, green: 0.55, blue: 0.85)
            let cols: [Color] = [.white, .white, Color(white: 0.12), Color(white: 0.12), blue, blue, red, red, gold, gold]
            for i in 0..<10 { ring(1 - Double(i) * 0.1, cols[i], i == 2 || i == 3 ? .white.opacity(0.6) : Color(white: 0.2).opacity(0.5)) }
            ring(0.05, gold, Color(white: 0.2).opacity(0.5))
        case .nfaa5:
            let blue = Color(red: 0.12, green: 0.30, blue: 0.62)
            for i in 0..<5 { ring(1 - Double(i) * 0.2, i == 4 ? .white : blue, .white.opacity(0.8)) }
            ring(0.1, .white, blue)
        case .threeD:
            break
        }
        var cross = Path(); cross.move(to: CGPoint(x: c.x - 4, y: c.y)); cross.addLine(to: CGPoint(x: c.x + 4, y: c.y)); cross.move(to: CGPoint(x: c.x, y: c.y - 4)); cross.addLine(to: CGPoint(x: c.x, y: c.y + 4))
        ctx.stroke(cross, with: .color(Color(white: 0.2).opacity(0.6)), lineWidth: 0.8)
    }
}

/// 3D scoring: one big button per ring.
struct ThreeDPad: View {
    let add: (Int, Bool) -> Void
    var body: some View {
        let rings: [(String, Int, Bool, Color)] = [("12", 12, true, Kraft.fletch), ("11", 11, true, Kraft.fletch), ("10", 10, false, Kraft.fletchDeep),
                                                  ("8", 8, false, Kraft.amber), ("5", 5, false, Kraft.ink2), ("Miss", 0, false, Kraft.red)]
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(rings, id: \.0) { r in
                Button { add(r.1, r.2) } label: {
                    Text(r.0).font(.fig(32)).foregroundStyle(r.3 == Kraft.fletch ? Kraft.ink : Kraft.card)
                        .frame(maxWidth: .infinity).frame(height: 96)
                        .background(RoundedRectangle(cornerRadius: 12).fill(r.3).shadow(color: Kraft.ink.opacity(0.2), radius: 6, y: 3))
                }.buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Text("12 and 11 are the inner rings on ASA and IBO.").font(.note(11)).foregroundStyle(Kraft.ink3).offset(y: 18) }
    }
}

// MARK: Session detail

struct SessionDetail: View {
    @Environment(Store.self) private var store
    @Environment(Pro.self) private var pro
    @Environment(Extras.self) private var extras
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var poster: UIImage? = nil
    @State private var confirmDelete = false
    @State private var markAdded = false
    var body: some View {
        if let i = store.sessions.firstIndex(where: { $0.id == id }) {
            let s = store.sessions[i]
            ZStack {
                PaperBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Eyebrow(s.date.formatted(.dateTime.weekday(.wide).month(.wide).day()) + " · " + s.setup)
                                Text(s.info.name).font(.hand(28, .bold)).foregroundStyle(Kraft.ink)
                                Text(s.distanceText + (s.sightReading.map { " · sight " + f1($0, 2) } ?? "")).font(.note(13)).foregroundStyle(Kraft.ink2)
                            }
                            Spacer()
                            Button("Done") { dismiss() }.font(.note(15, .bold)).foregroundStyle(Kraft.ink)
                        }.padding(.top, 20)
                        HStack(spacing: 12) {
                            InkStat(value: "\(s.total)", unit: s.info.maxScore.map { "/\($0)" } ?? "", label: "score")
                            InkStat(value: f1(s.average, 2), unit: "", label: "per arrow")
                            InkStat(value: "\(s.xs)", unit: "", label: "X count", color: Kraft.fletchDeep)
                        }.sheet()
                        if s.info.face != .threeD {
                            let g = s.group
                            TargetFace(face: s.info.face, shots: s.shots, showGroup: g.map { (x: $0.x / (s.faceCm / 2), y: $0.y / (s.faceCm / 2), spread: $0.spread / (s.faceCm / 2)) })
                                .aspectRatio(1, contentMode: .fit).sheet(padding: 10, tilt: 0.4)
                            groupCard(s)
                        }
                        endsTable(s)
                        VStack(alignment: .leading, spacing: 6) {
                            Eyebrow("Note")
                            TextField("How it felt, the wind, what changed", text: Binding(get: { store.sessions[i].note }, set: { store.sessions[i].note = $0; store.save() }), axis: .vertical)
                                .lineLimit(2...5).font(.note(14)).foregroundStyle(Kraft.ink)
                        }.sheet(tilt: -0.3)
                        shareRow(s)
                        Button(role: .destructive) { confirmDelete = true } label: { Label("Delete this round", systemImage: "trash").font(.note(13, .bold)).foregroundStyle(Kraft.red) }.buttonStyle(.plain)
                    }.padding(.leading, 30).padding(.trailing, 18).padding(.bottom, 40)
                }
            }
            .confirmationDialog("Delete this round?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { store.sessions.removeAll { $0.id == id }; store.save(); dismiss() }
            }
            .sheet(item: Binding(get: { poster.map { PosterBox(image: $0) } }, set: { if $0 == nil { poster = nil } })) { p in
                PosterSheet(image: p.image).presentationBackground(Kraft.paper)
            }
        }
    }

    @ViewBuilder func groupCard(_ s: Session) -> some View {
        if let g = s.group, let c = s.correction(sightRadiusInches: store.bow.sightRadius) {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("Your group")
                Text("Centre \(dir(g.y, "high", "low")) and \(dir(g.x, "right", "left")); arrows sit \(f1(g.spread, 1)) cm from it on average.").font(.note(14, .semibold)).foregroundStyle(Kraft.ink)
                let tiny = abs(c.up) < 0.15 && abs(c.right) < 0.15
                if tiny {
                    Text("The sight is right where it should be. Leave it alone.").font(.note(13)).foregroundStyle(Kraft.fletchDeep)
                } else {
                    Text("Move the sight \(f1(abs(c.up), 1)) mm \(c.up >= 0 ? "up" : "down") and \(f1(abs(c.right), 1)) mm \(c.right >= 0 ? "right" : "left"). Follow the arrow.").font(.note(13)).foregroundStyle(Kraft.ink2)
                }
                Text("From a \(f1(store.bow.sightRadius, 1))\" sight radius (Bow page) and \(g.count) placed arrows.").font(.note(11)).foregroundStyle(Kraft.ink3)
                if let r = s.sightReading, !tiny {
                    // Higher readings move the pin down on this tape, so a low group adds to the reading.
                    let fixed = r - c.up / store.mmPerUnit
                    let d = s.yards == store.tape.yards ? s.distance : s.yards ? s.distance * 0.9144 : s.distance / 0.9144
                    Button {
                        store.addMark(distance: (d * 10).rounded() / 10, reading: fixed)
                        withAnimation { markAdded = true }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } label: {
                        HStack {
                            Image(systemName: markAdded ? "checkmark" : "ruler").font(.system(size: 13, weight: .bold))
                            Text(markAdded ? "Mark saved to \(store.currentName)'s tape" : "Save \(f1(d, 0)) \(store.tape.yards ? "yd" : "m") at \(f1(fixed, 2)) to the tape")
                                .font(.note(13, .bold))
                        }
                        .foregroundStyle(Kraft.ink).padding(.horizontal, 12).padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 7).fill(Kraft.fletch))
                    }.buttonStyle(.plain).disabled(markAdded)
                }
            }.sheet(tilt: -0.4)
        }
    }
    func dir(_ v: Double, _ pos: String, _ neg: String) -> String { abs(v) < 0.3 ? "level" : "\(f1(abs(v), 1)) cm \(v > 0 ? pos : neg)" }

    func endsTable(_ s: Session) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow("Ends")
            ForEach(Array(s.ends.enumerated()), id: \.offset) { k, e in
                HStack {
                    Text("\(k + 1)").font(.fig(13)).foregroundStyle(Kraft.ink3).frame(width: 26, alignment: .leading)
                    Text(e.shots.map { $0.x10 ? "X" : $0.score == 0 ? "M" : "\($0.score)" }.joined(separator: "  ")).font(.mono(13)).foregroundStyle(Kraft.ink)
                    Spacer()
                    Text("\(e.total)").font(.fig(14)).foregroundStyle(Kraft.ink).frame(width: 34, alignment: .trailing)
                    Text("\(s.ends.prefix(k + 1).reduce(0) { $0 + $1.total })").font(.fig(14)).foregroundStyle(Kraft.fletchDeep).frame(width: 44, alignment: .trailing)
                }.padding(.vertical, 2).overlay(alignment: .bottom) { Rectangle().fill(Kraft.rule).frame(height: 0.7) }
            }
        }.sheet()
    }

    func shareRow(_ s: Session) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Share")
            HStack(spacing: 10) {
                ShareLink(item: "\(s.info.name), \(s.distanceText): \(s.total)\(s.info.maxScore.map { "/\($0)" } ?? "") with \(s.xs) X. Scored in Quiver.") {
                    Label("Text", systemImage: "square.and.arrow.up").font(.note(13, .bold)).foregroundStyle(Kraft.ink)
                        .padding(.horizontal, 12).padding(.vertical, 9).overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Kraft.ink.opacity(0.3)))
                }
                Button { Task { await makePoster(s) } } label: {
                    Label(posterLabel, systemImage: "photo.artframe").font(.note(13, .bold)).foregroundStyle(Kraft.ink)
                        .padding(.horizontal, 12).padding(.vertical, 9).background(RoundedRectangle(cornerRadius: 7).fill(Kraft.fletch))
                }.buttonStyle(.plain).disabled(extras.busy != nil)
            }
            Text("A scorecard poster is the face with every arrow, the ends and your total, drawn on kraft paper, ready to post. Your first one is free; then \(extras.price(Extras.postersID)) for three.").font(.note(11.5)).foregroundStyle(Kraft.ink3)
            if let m = extras.message { Text(m).font(.note(12, .semibold)).foregroundStyle(Kraft.red) }
        }.sheet(tilt: 0.3)
    }
    var posterLabel: String {
        !store.freePosterUsed ? "Poster, free" : store.posterCredits > 0 ? "Poster (\(store.posterCredits) left)" : "Posters, \(extras.price(Extras.postersID)) for 3"
    }
    @MainActor func makePoster(_ s: Session) async {
        if store.freePosterUsed && store.posterCredits == 0 {
            guard await extras.buy(Extras.postersID) else { return }
        }
        if !store.freePosterUsed { store.freePosterUsed = true } else { store.posterCredits -= 1 }
        store.save()
        let r = ImageRenderer(content: PosterView(session: s).environment(store))
        r.scale = 3
        poster = r.uiImage
    }
}

struct PosterBox: Identifiable { let id = UUID(); let image: UIImage }

struct PosterSheet: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 14) {
            HStack { Text("Your scorecard").font(.hand(24, .bold)).foregroundStyle(Kraft.ink); Spacer(); Button("Done") { dismiss() }.font(.note(15, .bold)).foregroundStyle(Kraft.ink) }.padding(.top, 20)
            Image(uiImage: image).resizable().scaledToFit().shadow(color: Kraft.ink.opacity(0.3), radius: 10, y: 5)
            ShareLink(item: Image(uiImage: image), preview: SharePreview("Scorecard", image: Image(uiImage: image))) {
                Label("Share the poster", systemImage: "square.and.arrow.up").font(.hand(16, .bold)).foregroundStyle(Kraft.card).frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 8).fill(Kraft.ink))
            }
            Spacer(minLength: 0)
        }.padding(.horizontal, 18).padding(.bottom, 20)
    }
}

/// The poster itself: a scorecard on kraft paper.
struct PosterView: View {
    let session: Session
    var body: some View {
        let s = session
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("QUIVER").font(.note(12, .heavy)).tracking(3).foregroundStyle(Kraft.ink3)
                Spacer()
                Text(s.date.formatted(.dateTime.month(.wide).day().year())).font(.note(12, .bold)).foregroundStyle(Kraft.ink2)
            }
            Text(s.info.name).font(.hand(30, .bold)).foregroundStyle(Kraft.ink)
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(s.total)").font(.fig(84)).foregroundStyle(Kraft.ink)
                if let m = s.info.maxScore { Text("/ \(m)").font(.fig(26)).foregroundStyle(Kraft.ink3) }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(s.xs) X").font(.fig(24)).foregroundStyle(Kraft.fletchDeep)
                    Text(s.distanceText).font(.note(14, .bold)).foregroundStyle(Kraft.ink2)
                }
            }
            if s.info.face != .threeD {
                TargetFace(face: s.info.face, shots: s.shots).frame(width: 340, height: 340).frame(maxWidth: .infinity)
            }
            Text(s.ends.map { e in "\(e.total)" }.joined(separator: " · ")).font(.mono(13)).foregroundStyle(Kraft.ink2)
            Text(s.setup).font(.note(12, .bold)).foregroundStyle(Kraft.ink3)
        }
        .padding(26)
        .frame(width: 420)
        .background(ZStack { Kraft.paper; Kraft.card.opacity(0.35) })
        .overlay(Rectangle().strokeBorder(Kraft.ink.opacity(0.2), lineWidth: 2).padding(10))
    }
}

// MARK: Trends (Pro)

struct TrendCard: View {
    @Environment(Store.self) private var store
    var body: some View {
        let scored = store.sessions.filter { $0.arrows > 0 }.prefix(20).reversed()
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Scores over time, % of possible")
            Canvas { ctx, size in
                let pts = Array(scored)
                guard pts.count >= 2 else { return }
                let lo = (pts.map(\.percent).min() ?? 0) - 0.05, hi = min(1, (pts.map(\.percent).max() ?? 1) + 0.05)
                func P(_ i: Int) -> CGPoint {
                    CGPoint(x: Double(i) / Double(pts.count - 1) * (size.width - 20) + 10, y: size.height - 14 - (pts[i].percent - lo) / max(0.01, hi - lo) * (size.height - 28))
                }
                var path = Path(); path.move(to: P(0))
                for i in 1..<pts.count { path.addLine(to: P(i)) }
                ctx.stroke(path, with: .color(Kraft.ink), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                for i in 0..<pts.count { let p = P(i); ctx.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)), with: .color(Kraft.fletch)) }
            }.frame(height: 120)
            HeatMap()
            if let best = store.sessions.max(by: { $0.percent < $1.percent }) {
                Text("Best: \(best.total) on \(best.info.name), \(best.date.formatted(.dateTime.month(.abbreviated).day())).").font(.note(12)).foregroundStyle(Kraft.ink2)
            }
        }.sheet(tilt: 0.3)
    }
}

/// Every placed arrow from every round, on one face: where your misses really go.
struct HeatMap: View {
    @Environment(Store.self) private var store
    var body: some View {
        let shots = store.sessions.filter { $0.info.face == .wa10 }.flatMap(\.shots)
        HStack(spacing: 14) {
            TargetFace(face: .wa10, shots: shots).frame(width: 120, height: 120)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(shots.count) arrows, every round").font(.note(13, .bold)).foregroundStyle(Kraft.ink)
                let mx = shots.compactMap(\.x).reduce(0, +) / Double(max(1, shots.count)), my = shots.compactMap(\.y).reduce(0, +) / Double(max(1, shots.count))
                Text("Your misses lean \(my < -0.03 ? "low" : my > 0.03 ? "high" : "level")\(mx < -0.03 ? " and left" : mx > 0.03 ? " and right" : ""). A steady lean across many rounds is form, not the sight.").font(.note(12)).foregroundStyle(Kraft.ink2)
            }
        }
    }
}

/// Shape of the trend card under the frost, not the user's numbers.
struct TrendSample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Scores over time, % of possible")
            Canvas { ctx, size in
                let ys: [Double] = [0.7, 0.55, 0.62, 0.4, 0.45, 0.3, 0.35, 0.2]
                var p = Path()
                for (i, y) in ys.enumerated() { let pt = CGPoint(x: Double(i) / 7 * size.width, y: y * size.height); if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) } }
                ctx.stroke(p, with: .color(Kraft.ink), lineWidth: 2.5)
            }.frame(height: 120)
        }
    }
}
