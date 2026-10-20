import AppIntents
import SwiftUI
import WidgetKit

/// Kraft paper for the widgets: the app's palette, without the app's theme machinery.
enum Paper {
    static let paper = Color(red: 0.851, green: 0.780, blue: 0.627)
    static let paper2 = Color(red: 0.902, green: 0.843, blue: 0.702)
    static let card = Color(red: 0.965, green: 0.937, blue: 0.867)
    static let red = Color(red: 0.72, green: 0.22, blue: 0.16)
}

struct PaperFill: View {
    var body: some View {
        ZStack {
            Paper.paper
            RadialGradient(colors: [Paper.paper2.opacity(0.9), .clear], center: .init(x: 0.25, y: 0.1), startRadius: 10, endRadius: 220)
        }
    }
}

/// Small widget: one distance, its mark, and buttons to walk it back or forward.
struct SightMarkGlanceView: View {
    let g: Glance
    var interactive = true
    var body: some View {
        let ink = Color(hex: g.ink), fletch = Color(hex: g.fletch)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "scope").font(.system(size: 10, weight: .heavy))
                Text(g.setup.uppercased()).font(.system(size: 10, weight: .heavy)).tracking(1).lineLimit(1)
            }.foregroundStyle(ink.opacity(0.55))
            if let i = g.selected {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(fmt(g.distances[i], 0)).font(.system(size: 30, weight: .bold, design: .serif)).monospacedDigit()
                    Text(g.unitWord).font(.system(size: 12, weight: .bold)).foregroundStyle(ink.opacity(0.55))
                }.foregroundStyle(ink)
                Text(fmt(g.readings[i], 2)).font(.system(size: 26, weight: .heavy, design: .monospaced))
                    .foregroundStyle(ink).padding(.horizontal, 6).padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 4).fill(fletch.opacity(0.85)))
                    .minimumScaleFactor(0.6).lineLimit(1)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    stepButton(-5, "minus")
                    stepButton(5, "plus")
                }
            } else {
                Spacer(minLength: 0)
                Text("Add two sight marks in Quiver and your tape lands here.").font(.system(size: 12, weight: .semibold)).foregroundStyle(ink)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    @ViewBuilder func stepButton(_ by: Int, _ icon: String) -> some View {
        let ink = Color(hex: g.ink)
        let label = Image(systemName: icon).font(.system(size: 13, weight: .heavy)).foregroundStyle(Paper.card)
            .frame(maxWidth: .infinity).frame(height: 26).background(RoundedRectangle(cornerRadius: 7).fill(ink))
        if interactive {
            Button(intent: StepDistanceIntent(step: by)) { label }.buttonStyle(.plain)
                .accessibilityLabel(by > 0 ? "Five \(g.unitWord) further" : "Five \(g.unitWord) closer")
        } else { label }
    }
}

/// Medium widget: the tape itself, every ten.
struct TapeGlanceView: View {
    let g: Glance
    var body: some View {
        let ink = Color(hex: g.ink), fletch = Color(hex: g.fletch)
        let rows = Array(g.tapeRows.prefix(10))
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("SIGHT TAPE").font(.system(size: 10, weight: .heavy)).tracking(1.4).foregroundStyle(ink.opacity(0.55))
                Text(g.setup).font(.system(size: 17, weight: .bold, design: .serif)).foregroundStyle(ink).lineLimit(2)
                Spacer(minLength: 0)
                Text("\(g.unit) scale · \(g.yards ? "yards" : "metres")").font(.system(size: 10, weight: .semibold)).foregroundStyle(ink.opacity(0.55))
            }.frame(width: 92, alignment: .leading)
            if rows.isEmpty {
                Text("Add two sight marks in Quiver and the tape lands here.").font(.system(size: 12, weight: .semibold)).foregroundStyle(ink)
            } else {
                let half = (rows.count + 1) / 2
                HStack(alignment: .top, spacing: 10) {
                    column(Array(rows.prefix(half)), ink, fletch)
                    column(Array(rows.dropFirst(half)), ink, fletch)
                }
            }
        }
    }
    func column(_ rows: [(Double, Double)], _ ink: Color, _ fletch: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(rows, id: \.0) { r in
                HStack(spacing: 6) {
                    Rectangle().fill(ink).frame(width: 10, height: 1.5)
                    Text(fmt(r.0, 0)).font(.system(size: 13, weight: .bold, design: .serif)).monospacedDigit().frame(width: 24, alignment: .leading)
                    Text(fmt(r.1, 2)).font(.system(size: 13, weight: .semibold, design: .monospaced))
                }.foregroundStyle(ink)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Small widget: the last round and the trend line under it.
struct LastRoundGlanceView: View {
    let g: Glance
    var body: some View {
        let ink = Color(hex: g.ink), fletch = Color(hex: g.fletch)
        VStack(alignment: .leading, spacing: 3) {
            Text("LAST ROUND").font(.system(size: 10, weight: .heavy)).tracking(1.2).foregroundStyle(ink.opacity(0.55))
            if let name = g.lastRound, let t = g.lastTotal {
                Text(name).font(.system(size: 13, weight: .bold, design: .serif)).foregroundStyle(ink).lineLimit(1)
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(t)").font(.system(size: 34, weight: .bold, design: .serif)).monospacedDigit().foregroundStyle(ink)
                    if let m = g.lastOutOf { Text("/\(m)").font(.system(size: 12, weight: .bold)).foregroundStyle(ink.opacity(0.5)) }
                }
                Text(g.lastXs > 0 ? "\(g.lastXs) X · \(g.lastDistance)" : g.lastDistance).font(.system(size: 11, weight: .heavy)).foregroundStyle(ink.opacity(0.7))
                Spacer(minLength: 0)
                Spark(values: g.recent, ink: ink, dot: fletch).frame(height: 22)
            } else {
                Spacer(minLength: 0)
                Text("Score a round in Quiver and it shows up here.").font(.system(size: 12, weight: .semibold)).foregroundStyle(ink)
                Spacer(minLength: 0)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Spark: View {
    let values: [Double]
    let ink: Color
    let dot: Color
    var body: some View {
        Canvas { ctx, size in
            guard values.count >= 2 else { return }
            let lo = (values.min() ?? 0) - 0.02, hi = (values.max() ?? 1) + 0.02
            func P(_ i: Int) -> CGPoint {
                CGPoint(x: Double(i) / Double(values.count - 1) * (size.width - 6) + 3, y: size.height - 3 - (values[i] - lo) / max(0.01, hi - lo) * (size.height - 6))
            }
            var p = Path(); p.move(to: P(0))
            for i in 1..<values.count { p.addLine(to: P(i)) }
            ctx.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            let e = P(values.count - 1)
            ctx.fill(Path(ellipseIn: CGRect(x: e.x - 3.5, y: e.y - 3.5, width: 7, height: 7)), with: .color(dot))
        }
    }
}

/// Lock Screen rectangle: the mark at the chosen distance, plus its neighbours.
struct LockMarkView: View {
    let g: Glance
    var body: some View {
        if let i = g.selected {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: "scope").font(.system(size: 11, weight: .bold))
                    Text(g.setup).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                }
                Text("\(fmt(g.distances[i], 0)) \(g.unitWord)  \(fmt(g.readings[i], 2))").font(.system(size: 20, weight: .bold, design: .rounded)).monospacedDigit()
                let lo = max(0, i - 10), hi = min(g.distances.count - 1, i + 10)
                Text("\(fmt(g.distances[lo], 0)): \(fmt(g.readings[lo], 1))  ·  \(fmt(g.distances[hi], 0)): \(fmt(g.readings[hi], 1))").font(.system(size: 11, weight: .medium)).monospacedDigit().opacity(0.75)
            }.frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("Quiver: add two sight marks").font(.system(size: 13, weight: .semibold))
        }
    }
}

struct LockCircleView: View {
    let g: Glance
    var body: some View {
        if let i = g.selected {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: -1) {
                    Text(fmt(g.distances[i], 0)).font(.system(size: 11, weight: .bold))
                    Text(fmt(g.readings[i], 1)).font(.system(size: 15, weight: .heavy, design: .rounded)).minimumScaleFactor(0.6)
                }
            }
        } else {
            ZStack { AccessoryWidgetBackground(); Image(systemName: "scope").font(.system(size: 20, weight: .bold)) }
        }
    }
}

/// The round in progress, drawn for the Lock Screen Live Activity.
struct RoundLiveView: View {
    let a: RoundActivity
    let s: RoundActivity.ContentState
    var body: some View {
        let ink = Color(hex: a.ink), fletch = Color(hex: a.fletch)
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(a.round.uppercased() + " · " + a.distance).font(.system(size: 11, weight: .heavy)).tracking(1).foregroundStyle(ink.opacity(0.6)).lineLimit(1)
                Text(s.ends.map { "End \(min(s.end, $0)) of \($0)" } ?? "End \(s.end)").font(.system(size: 20, weight: .bold, design: .serif)).foregroundStyle(ink)
                HStack(spacing: 5) {
                    ForEach(0..<max(s.perEnd, s.current.count), id: \.self) { k in
                        Text(k < s.current.count ? s.current[k] : "·").font(.system(size: 14, weight: .heavy, design: .serif))
                            .foregroundStyle(ink).frame(width: 28, height: 24)
                            .background(RoundedRectangle(cornerRadius: 5).fill(k < s.current.count ? fletch.opacity(0.9) : Paper.card.opacity(0.6)))
                    }
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(s.total)").font(.system(size: 40, weight: .bold, design: .serif)).monospacedDigit().foregroundStyle(ink)
                Text(s.xs > 0 ? "\(s.xs) X · \(s.arrows) arrows" : "\(s.arrows) arrows").font(.system(size: 11, weight: .heavy)).foregroundStyle(ink.opacity(0.65))
            }
        }
        .padding(16)
    }
}
