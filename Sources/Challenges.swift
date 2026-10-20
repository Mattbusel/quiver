import SwiftUI

/// One challenge a month, the same for everyone, worked out from the rounds you score. Plus adds a harder bonus one.
struct Challenge: Identifiable {
    enum Goal {
        case arrows(Int)              // arrows shot this month
        case xs(Int)                  // Xs this month
        case rounds(Int)              // rounds finished this month
        case distances(Int)           // different distances shot this month
        case cleanEnd(Int)            // an end where every arrow scores at least this (10-ring faces)
        case percent(Double, Int)     // a round of at least `Int` arrows at this fraction of possible
        case noMiss(Int)              // a round of at least this many arrows with no misses
        case full(String)             // finish a full round of this id
        case tightGroup(Double)       // a round whose group spread is under this many cm
    }
    let id: String
    let title: String
    let blurb: String
    let symbol: String
    let goal: Goal

    /// 0...1 from this month's rounds.
    func progress(_ ss: [Session]) -> Double {
        switch goal {
        case .arrows(let n): return min(1, Double(ss.reduce(0) { $0 + $1.arrows }) / Double(n))
        case .xs(let n): return min(1, Double(ss.reduce(0) { $0 + $1.xs }) / Double(n))
        case .rounds(let n): return min(1, Double(ss.filter { $0.arrows > 0 }.count) / Double(n))
        case .distances(let n): return min(1, Double(Set(ss.filter { $0.arrows > 0 }.map(\.distanceText)).count) / Double(n))
        case .cleanEnd(let floor):
            return ss.contains { s in s.info.face == .wa10 && s.ends.contains { e in e.shots.count >= s.info.perEnd && e.shots.allSatisfy { $0.score >= floor } } } ? 1 : 0
        case .percent(let p, let minArrows):
            let best = ss.filter { $0.arrows >= minArrows }.map(\.percent).max() ?? 0
            return min(1, best / p)
        case .noMiss(let n):
            return ss.contains { $0.arrows >= n && !$0.shots.contains { $0.score == 0 } } ? 1 : min(0.99, Double(ss.filter { !$0.shots.contains { $0.score == 0 } }.map(\.arrows).max() ?? 0) / Double(n))
        case .full(let rid):
            let r = Round.byID(rid)
            let need = (r.ends ?? 1) * r.perEnd
            return min(1, Double(ss.filter { $0.round == rid }.map(\.arrows).max() ?? 0) / Double(need))
        case .tightGroup(let cm):
            guard let best = ss.compactMap({ $0.group?.spread }).min() else { return 0 }
            return best <= cm ? 1 : min(0.95, cm / best)
        }
    }

    func status(_ ss: [Session]) -> String {
        switch goal {
        case .arrows(let n): return "\(ss.reduce(0) { $0 + $1.arrows }) of \(n) arrows"
        case .xs(let n): return "\(ss.reduce(0) { $0 + $1.xs }) of \(n) Xs"
        case .rounds(let n): return "\(ss.filter { $0.arrows > 0 }.count) of \(n) rounds"
        case .distances(let n): return "\(Set(ss.filter { $0.arrows > 0 }.map(\.distanceText)).count) of \(n) distances"
        case .percent(let p, _): return "Best so far \(Int(((ss.map(\.percent).max() ?? 0) * 100).rounded()))%, goal \(Int(p * 100))%"
        case .tightGroup(let cm): return ss.compactMap({ $0.group?.spread }).min().map { "Tightest so far \(f1($0, 1)) cm, goal \(f1(cm, 1)) cm" } ?? "Place at least three arrows on a face"
        default: return progress(ss) >= 1 ? "Done" : "Not yet"
        }
    }

    // MARK: The calendar

    /// January first. Index = month - 1.
    static let main: [Challenge] = [
        Challenge(id: "m01", title: "Five hundred arrows", blurb: "Shoot and score 500 arrows this month. Volume is the cheapest coach there is.", symbol: "arrow.up.right", goal: .arrows(500)),
        Challenge(id: "m02", title: "Clean end", blurb: "One end where every arrow scores 9 or better on a ten-ring face.", symbol: "sparkle", goal: .cleanEnd(9)),
        Challenge(id: "m03", title: "Walk-back month", blurb: "Score rounds at four different distances. Your tape gets better with every one.", symbol: "figure.walk", goal: .distances(4)),
        Challenge(id: "m04", title: "The full indoor", blurb: "Shoot a complete WA 18 m round: 60 arrows, 20 ends of three.", symbol: "building.2", goal: .full("wa18")),
        Challenge(id: "m05", title: "No misses", blurb: "A round of at least 30 arrows without a single miss.", symbol: "checkmark.shield", goal: .noMiss(30)),
        Challenge(id: "m06", title: "Eight rounds", blurb: "Finish eight scored rounds this month. Any round, any distance.", symbol: "calendar", goal: .rounds(8)),
        Challenge(id: "m07", title: "Tight group", blurb: "Hold a group with an average spread under 4 cm on any face.", symbol: "scope", goal: .tightGroup(4)),
        Challenge(id: "m08", title: "3D course", blurb: "Walk a full 20-target 3D course and score every target.", symbol: "tree", goal: .full("3d")),
        Challenge(id: "m09", title: "Eighty percent", blurb: "One round of at least 30 arrows at 80% of the possible score.", symbol: "chart.line.uptrend.xyaxis", goal: .percent(0.8, 30)),
        Challenge(id: "m10", title: "Three hundred arrows", blurb: "Score 300 arrows before the month is out. Season prep starts here.", symbol: "arrow.up.right", goal: .arrows(300)),
        Challenge(id: "m11", title: "Ten Xs", blurb: "Put ten arrows in the X this month. Every round counts.", symbol: "xmark.circle", goal: .xs(10)),
        Challenge(id: "m12", title: "Vegas month", blurb: "Shoot a full Vegas 450: 30 arrows at 20 yards, ends of three.", symbol: "star", goal: .full("vegas")),
    ]
    /// The Plus bonus: a harder second challenge each month.
    static let bonus: [Challenge] = [
        Challenge(id: "b01", title: "Twenty Xs", blurb: "Twenty arrows in the X this month.", symbol: "xmark.circle.fill", goal: .xs(20)),
        Challenge(id: "b02", title: "Ninety percent", blurb: "A round of 30 arrows or more at 90% of possible.", symbol: "flame", goal: .percent(0.9, 30)),
        Challenge(id: "b03", title: "Six distances", blurb: "Score rounds at six different distances.", symbol: "ruler", goal: .distances(6)),
        Challenge(id: "b04", title: "Perfect end", blurb: "One end of all tens on a ten-ring face.", symbol: "sparkles", goal: .cleanEnd(10)),
        Challenge(id: "b05", title: "Sixty clean", blurb: "Sixty arrows in one round without a miss.", symbol: "checkmark.shield.fill", goal: .noMiss(60)),
        Challenge(id: "b06", title: "A thousand arrows", blurb: "Score 1,000 arrows this month.", symbol: "bolt", goal: .arrows(1000)),
        Challenge(id: "b07", title: "Pinhole group", blurb: "An average group spread under 2.5 cm.", symbol: "scope", goal: .tightGroup(2.5)),
        Challenge(id: "b08", title: "The long one", blurb: "Finish a full WA 70 m round: 72 arrows.", symbol: "mountain.2", goal: .full("wa70")),
        Challenge(id: "b09", title: "Twelve rounds", blurb: "Twelve finished rounds this month.", symbol: "calendar.badge.checkmark", goal: .rounds(12)),
        Challenge(id: "b10", title: "NFAA 300", blurb: "A complete NFAA 300 round, 60 arrows.", symbol: "target", goal: .full("nfaa300")),
        Challenge(id: "b11", title: "Thirty Xs", blurb: "Thirty Xs before the month is out.", symbol: "xmark.seal", goal: .xs(30)),
        Challenge(id: "b12", title: "Eighty-five, twice", blurb: "A round of 60 arrows or more at 85% of possible.", symbol: "chart.bar", goal: .percent(0.85, 60)),
    ]

    static func month(_ d: Date = .now) -> Int { Calendar.current.component(.month, from: d) - 1 }
    static var thisMonth: Challenge { main[month()] }
    static var thisBonus: Challenge { bonus[month()] }

    static func sessions(_ all: [Session], in d: Date = .now) -> [Session] {
        let cal = Calendar.current
        return all.filter { cal.isDate($0.date, equalTo: d, toGranularity: .month) }
    }

    /// Finished challenges across every month you have rounds in.
    static func finished(_ all: [Session], plus: Bool) -> Int {
        let cal = Calendar.current
        var months = Set<DateComponents>()
        for s in all { months.insert(cal.dateComponents([.year, .month], from: s.date)) }
        var n = 0
        for m in months {
            guard let d = cal.date(from: m) else { continue }
            let ss = sessions(all, in: d)
            if main[month(d)].progress(ss) >= 1 { n += 1 }
            if plus && bonus[month(d)].progress(ss) >= 1 { n += 1 }
        }
        return n
    }
}

/// The challenge card at the top of the Range page.
struct ChallengeCard: View {
    @Environment(Store.self) private var store
    @Environment(Plus.self) private var plus
    @Environment(Router.self) private var router
    var body: some View {
        let ss = Challenge.sessions(store.sessions)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(Date.now.formatted(.dateTime.month(.wide)) + " challenge")
                Spacer()
                let n = Challenge.finished(store.sessions, plus: plus.active)
                if n > 0 { Label("\(n) done", systemImage: "rosette").font(.note(11, .heavy)).foregroundStyle(Kraft.fletchDeep) }
            }
            item(Challenge.thisMonth, ss)
            if plus.active {
                Divider().overlay(Kraft.rule)
                item(Challenge.thisBonus, ss, bonus: true)
            } else {
                Button { router.plus = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold))
                        Text("Bonus challenge: \(Challenge.thisBonus.title). With Quiver Plus.").font(.note(12, .bold))
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .heavy))
                    }.foregroundStyle(Kraft.ink2)
                }.buttonStyle(.plain)
            }
        }
        .sheet(tilt: 0.3)
    }

    func item(_ c: Challenge, _ ss: [Session], bonus: Bool = false) -> some View {
        let p = c.progress(ss), done = p >= 1
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: done ? "checkmark" : c.symbol).font(.system(size: 16, weight: .bold)).foregroundStyle(Kraft.ink)
                .frame(width: 40, height: 40).background(Circle().fill(done ? Kraft.fletch : Kraft.paper2))
                .symbolEffect(.bounce, value: done)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(c.title).font(.hand(18, .bold)).foregroundStyle(Kraft.ink)
                    if bonus { Text("BONUS").font(.note(9, .heavy)).tracking(1).padding(.horizontal, 5).padding(.vertical, 2).background(Capsule().fill(Kraft.fletch)).foregroundStyle(Kraft.ink) }
                }
                Text(c.blurb).font(.note(12.5)).foregroundStyle(Kraft.ink2).fixedSize(horizontal: false, vertical: true)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Kraft.ink.opacity(0.1))
                        Capsule().fill(done ? Kraft.fletchDeep : Kraft.ink).frame(width: max(8, g.size.width * p))
                    }
                }.frame(height: 7)
                Text(done ? "Done. Nice shooting." : c.status(ss)).font(.note(11, .heavy)).foregroundStyle(done ? Kraft.fletchDeep : Kraft.ink3)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
