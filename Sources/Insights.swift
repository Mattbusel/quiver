import SwiftUI

/// Quiver Plus: what the score book says about your shooting, worked out from every round on the phone.
struct Insights {
    let sessions: [Session]

    var scored: [Session] { sessions.filter { $0.arrows > 0 } }

    /// Points per arrow in the first half of each round's ends vs the second half, over the last ten rounds of 4+ ends.
    var fatigue: (first: Double, second: Double)? {
        let rs = scored.filter { $0.ends.count >= 4 && $0.info.face != .threeD }.prefix(10)
        guard !rs.isEmpty else { return nil }
        var a = 0.0, an = 0.0, b = 0.0, bn = 0.0
        for s in rs {
            let half = s.ends.count / 2
            for (i, e) in s.ends.enumerated() {
                let top = Double(s.info.face.top)
                for sh in e.shots { if i < half { a += Double(sh.score) / top; an += 1 } else { b += Double(sh.score) / top; bn += 1 } }
            }
        }
        guard an > 0, bn > 0 else { return nil }
        return (a / an, b / bn)
    }

    /// How steady the ends are: the spread of end averages (as % of the face's top score), lower is better.
    var consistency: Double? {
        let ends = scored.prefix(10).filter { $0.info.face != .threeD }.flatMap { s in
            s.ends.filter { !$0.shots.isEmpty }.map { Double($0.total) / Double($0.shots.count * s.info.face.top) }
        }
        guard ends.count >= 4 else { return nil }
        let m = ends.reduce(0, +) / Double(ends.count)
        return (ends.map { ($0 - m) * ($0 - m) }.reduce(0, +) / Double(ends.count)).squareRoot()
    }

    /// Group size (mean spread, cm) for the most recent rounds that have one, oldest first.
    var groups: [Double] { Array(scored.compactMap { $0.group?.spread }.prefix(10).reversed()) }

    /// Average % of possible per distance, best first.
    var byDistance: [(String, Double, Int)] {
        var d: [String: (Double, Int)] = [:]
        for s in scored where s.info.face != .threeD { let v = d[s.distanceText] ?? (0, 0); d[s.distanceText] = (v.0 + s.percent * Double(s.arrows), v.1 + s.arrows) }
        return d.map { ($0.key, $0.value.0 / Double(max(1, $0.value.1)), $0.value.1) }.sorted { $0.1 > $1.1 }
    }

    /// The best end ever, as a fraction of possible, and where it was.
    var bestEnd: (Session, End)? {
        var best: (Session, End, Double)? = nil
        for s in scored where s.info.face != .threeD {
            for e in s.ends where e.shots.count == s.info.perEnd {
                let p = Double(e.total) / Double(e.shots.count * s.info.face.top)
                if best == nil || p > best!.2 { best = (s, e, p) }
            }
        }
        return best.map { ($0.0, $0.1) }
    }

    /// Arrows this month and last.
    var volume: (this: Int, last: Int) {
        let cal = Calendar.current
        let lastMonth = cal.date(byAdding: .month, value: -1, to: .now) ?? .now
        return (Challenge.sessions(sessions).reduce(0) { $0 + $1.arrows }, Challenge.sessions(sessions, in: lastMonth).reduce(0) { $0 + $1.arrows })
    }
}

struct InsightsCard: View {
    @Environment(Store.self) private var store
    var body: some View {
        let ins = Insights(sessions: store.sessions)
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow("Insights")
            if let f = ins.fatigue {
                let drop = (f.first - f.second) * 100
                stat("Late ends", drop > 1.5 ? "Your second half drops \(f1(drop, 1)) points per 100." : drop < -1.5 ? "You finish stronger: +\(f1(-drop, 1)) per 100 late on." : "Steady from the first end to the last.",
                     bars: [f.first, f.second], labels: ["first half", "second half"])
            }
            if let c = ins.consistency {
                let grade = c < 0.06 ? "Very steady" : c < 0.1 ? "Steady" : c < 0.15 ? "Up and down" : "All over the place"
                stat("Consistency", "\(grade): your ends vary by \(f1(c * 100, 1)) points per 100.", bars: nil, labels: [])
            }
            if ins.groups.count >= 2 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Group size").font(.hand(16, .bold)).foregroundStyle(Kraft.ink)
                    Spark(values: ins.groups.map { -$0 }, ink: Kraft.ink, dot: Kraft.fletch).frame(height: 44)
                    let first = ins.groups.first ?? 0, last = ins.groups.last ?? 0
                    Text(last < first ? "Tightening: \(f1(first, 1)) cm to \(f1(last, 1)) cm average spread." : "From \(f1(first, 1)) cm to \(f1(last, 1)) cm average spread. Up on the chart is tighter.")
                        .font(.note(12)).foregroundStyle(Kraft.ink2)
                }
            }
            if !ins.byDistance.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("By distance").font(.hand(16, .bold)).foregroundStyle(Kraft.ink)
                    ForEach(ins.byDistance.prefix(5), id: \.0) { d in
                        HStack(spacing: 8) {
                            Text(d.0).font(.fig(13)).foregroundStyle(Kraft.ink).frame(width: 56, alignment: .leading)
                            GeometryReader { g in
                                Capsule().fill(Kraft.fletch).frame(width: max(6, g.size.width * d.1)).overlay(Capsule().strokeBorder(Kraft.ink.opacity(0.2)))
                            }.frame(height: 10)
                            Text("\(Int((d.1 * 100).rounded()))%").font(.mono(12)).foregroundStyle(Kraft.ink).frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
            HStack(spacing: 12) {
                let v = ins.volume
                InkStat(value: "\(v.this)", unit: "", label: "arrows this month")
                InkStat(value: "\(v.last)", unit: "", label: "last month")
                if let b = ins.bestEnd { InkStat(value: "\(b.1.total)", unit: "", label: "best end", color: Kraft.fletchDeep) }
            }
        }
        .sheet(tilt: -0.3)
    }

    func stat(_ title: String, _ line: String, bars: [Double]?, labels: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.hand(16, .bold)).foregroundStyle(Kraft.ink)
            if let bars {
                HStack(alignment: .bottom, spacing: 14) {
                    ForEach(Array(bars.enumerated()), id: \.offset) { i, v in
                        VStack(spacing: 3) {
                            Text("\(Int((v * 100).rounded()))").font(.fig(15)).foregroundStyle(Kraft.ink)
                            RoundedRectangle(cornerRadius: 3).fill(i == 0 ? Kraft.ink : Kraft.fletch).frame(width: 46, height: max(6, 60 * (v - 0.4) / 0.6))
                            Text(labels[i]).font(.note(10, .bold)).foregroundStyle(Kraft.ink3)
                        }
                    }
                }
            }
            Text(line).font(.note(12.5)).foregroundStyle(Kraft.ink2).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Shape of the Insights card under the frost, not the user's numbers.
struct InsightsSample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Insights")
            Text("Late ends").font(.hand(16, .bold)).foregroundStyle(Kraft.ink)
            HStack(alignment: .bottom, spacing: 14) {
                RoundedRectangle(cornerRadius: 3).fill(Kraft.ink).frame(width: 46, height: 52)
                RoundedRectangle(cornerRadius: 3).fill(Kraft.fletch).frame(width: 46, height: 40)
            }
            Text("By distance").font(.hand(16, .bold)).foregroundStyle(Kraft.ink)
            ForEach([0.9, 0.82, 0.7], id: \.self) { v in Capsule().fill(Kraft.fletch).frame(width: 220 * v, height: 10) }
        }
    }
}

/// Free: the best score for every round you've shot.
struct BestsCard: View {
    @Environment(Store.self) private var store
    var body: some View {
        let bests = store.personalBests
        if !bests.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow("Personal bests")
                ForEach(bests, id: \.0.id) { r, s in
                    HStack {
                        Text(r.name).font(.hand(15, .bold)).foregroundStyle(Kraft.ink)
                        Spacer()
                        Text("\(s.total)").font(.fig(17)).foregroundStyle(Kraft.ink)
                        if let m = r.maxScore { Text("/\(m)").font(.note(11, .bold)).foregroundStyle(Kraft.ink3) }
                        Text(s.date.formatted(.dateTime.month(.abbreviated).day())).font(.note(11)).foregroundStyle(Kraft.ink3).frame(width: 52, alignment: .trailing)
                    }
                    .padding(.vertical, 3).overlay(alignment: .bottom) { Rectangle().fill(Kraft.rule).frame(height: 0.7) }
                    .accessibilityElement(children: .combine)
                }
            }.sheet(tilt: 0.2)
        }
    }
}
