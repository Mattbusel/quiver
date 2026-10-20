import ActivityKit
import SwiftUI
import TipKit
import WidgetKit

// MARK: The glance for widgets, Siri and the Lock Screen

extension Store {
    /// Everything the widgets need, computed here so the extension never runs the ballistics.
    @MainActor func glance(unlocked: Bool) -> Glance {
        var g = Glance()
        g.setup = currentName
        g.yards = tape.yards
        g.unit = tape.unitMM == 0 ? "clicks" : tape.unitMM == 0.5 ? "½ mm" : tape.unitMM == 25.4 ? "inch" : "mm"
        if fit != nil {
            let lo = max(5, (min(tape.from, tape.to) - 10).rounded()), hi = min(150, (max(tape.from, tape.to) + 10).rounded())
            if hi > lo {
                for d in stride(from: lo, through: hi, by: 1) {
                    if let r = reading(at: d) { g.distances.append(d); g.readings.append((r * 100).rounded() / 100) }
                }
            }
        }
        if let s = sessions.first(where: { $0.arrows > 0 }) {
            g.lastRound = s.info.name; g.lastTotal = s.total; g.lastOutOf = s.info.maxScore; g.lastXs = s.xs; g.lastDate = s.date; g.lastDistance = s.distanceText
        }
        g.recent = Array(sessions.filter { $0.arrows > 0 }.prefix(8).reversed().map(\.percent))
        g.unlocked = unlocked
        let t = InkTheme.current
        g.ink = t.inkHex; g.fletch = t.fletchHex
        let c = Challenge.thisMonth
        g.challenge = c.title; g.challengeProgress = c.progress(Challenge.sessions(sessions))
        return g
    }

    // MARK: Backup

    /// The notebook as one JSON file (same format as quiver.json). `keep` trims to the newest rounds.
    func backupData(keep: Int? = nil) -> Data? {
        stashForBackup()
        let list = keep.map { Array(sessions.prefix($0)) } ?? sessions
        let disk = Disk(arrow: arrow, bow: bow, tape: tape, setups: setups, current: current, sessions: list, notes: notes,
                        printCredits: printCredits, posterCredits: posterCredits, freePosterUsed: freePosterUsed)
        return try? JSONEncoder().encode(disk)
    }

    /// Personal best per round type: the highest total among finished-looking rounds.
    var personalBests: [(Round, Session)] {
        var out: [(Round, Session)] = []
        for r in Round.all where r.id != "practice" {
            if let b = sessions.filter({ $0.round == r.id && $0.arrows > 0 }).max(by: { ($0.total, $0.percent) < ($1.total, $1.percent) }) {
                out.append((r, b))
            }
        }
        return out
    }
    /// True when this session beats every earlier one of the same round (by total).
    func isPersonalBest(_ s: Session) -> Bool {
        guard s.round != "practice", s.arrows > 0 else { return false }
        let earlier = sessions.filter { $0.round == s.round && $0.id != s.id && $0.arrows > 0 }
        guard !earlier.isEmpty else { return false }
        return s.total > (earlier.map(\.total).max() ?? 0)
    }
}

extension InkTheme {
    var inkHex: UInt32 { InkTheme.hex[id]?.0 ?? 0x1F3D2B }
    var fletchHex: UInt32 { InkTheme.hex[id]?.1 ?? 0x9EDB24 }
}

/// Keeps the widgets, the Siri answers and the iCloud copy in step with the notebook.
@MainActor
final class Sync {
    static let shared = Sync()
    private var glanceTask: Task<Void, Never>?
    private var backupTask: Task<Void, Never>?
    private var last: Glance? = nil
    var demo = false

    func changed(_ store: Store, unlocked: Bool, plus: Bool) {
        glanceTask?.cancel()
        glanceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700)); if Task.isCancelled { return }
            let g = store.glance(unlocked: unlocked)
            guard g != last else { return }
            last = g
            if !demo { g.save(); WidgetCenter.shared.reloadAllTimelines() }
        }
        guard plus, !demo else { return }
        backupTask?.cancel()
        backupTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(8)); if Task.isCancelled { return }
            _ = Backup.save(store)
        }
    }
}

// MARK: iCloud backup (Plus)

@MainActor
enum Backup {
    private static var kv: NSUbiquitousKeyValueStore { .default }
    private static let key = "quiver.notebook", dateKey = "quiver.notebook.date", countKey = "quiver.notebook.rounds"
    /// Under the 1 MB per-key limit with room to spare.
    private static let limit = 900_000

    static var lastDate: Date? { kv.object(forKey: dateKey) as? Date }
    static var lastRounds: Int { Int(kv.longLong(forKey: countKey)) }

    @discardableResult
    static func save(_ store: Store) -> Bool {
        var keep: Int? = nil
        while true {
            guard let raw = store.backupData(keep: keep), let z = try? (raw as NSData).compressed(using: .lzfse) as Data else { return false }
            if z.count <= limit {
                kv.set(z, forKey: key); kv.set(Date(), forKey: dateKey)
                kv.set(Int64(keep.map { min($0, store.sessions.count) } ?? store.sessions.count), forKey: countKey)
                kv.synchronize()
                return true
            }
            // Very large score books: keep the newest rounds that fit.
            let n = keep ?? store.sessions.count
            if n <= 10 { return false }
            keep = n * 3 / 4
        }
    }

    static func restore(_ store: Store) -> Bool {
        kv.synchronize()
        guard let z = kv.data(forKey: key), let raw = try? (z as NSData).decompressed(using: .lzfse) as Data else { return false }
        return store.load(raw)
    }
}

struct BackupRow: View {
    @Environment(Store.self) private var store
    @State private var stamp = Backup.lastDate
    @State private var confirm = false
    @State private var note: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "icloud").font(.system(size: 13, weight: .bold)).foregroundStyle(Kraft.ink)
                Text(stamp.map { "Backed up \($0.formatted(.relative(presentation: .named)))" } ?? "Not backed up yet").font(.note(12, .semibold)).foregroundStyle(Kraft.ink2)
                Spacer()
                Button("Back up now") {
                    note = Backup.save(store) ? nil : "iCloud is not available. Check that you're signed in to iCloud."
                    stamp = Backup.lastDate
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }.font(.note(12, .bold)).foregroundStyle(Kraft.ink)
                Button("Restore") { confirm = true }.font(.note(12, .bold)).foregroundStyle(Kraft.ink2)
            }.buttonStyle(.plain)
            if let note { Text(note).font(.note(11, .semibold)).foregroundStyle(Kraft.red) }
        }
        .confirmationDialog("Replace this notebook with the iCloud copy?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Restore from iCloud", role: .destructive) {
                note = Backup.restore(store) ? "Restored \(store.sessions.count) rounds and \(store.setups.count) setups." : "No iCloud backup found on this Apple ID yet."
            }
        } message: { Text(Backup.lastDate.map { "The iCloud copy is from \($0.formatted(date: .abbreviated, time: .shortened)), \(Backup.lastRounds) rounds." } ?? "") }
    }
}

// MARK: Live Activity for the round in progress

@MainActor
enum LiveRound {
    private static var activity: Activity<RoundActivity>?

    static func state(_ s: Session) -> RoundActivity.ContentState {
        let end = s.ends.last ?? End()
        return .init(total: s.total, end: max(1, s.ends.count), ends: s.info.ends, arrows: s.arrows, xs: s.xs, outOf: s.info.maxScore,
                     current: end.shots.map { $0.x10 ? "X" : $0.score == 0 ? "M" : "\($0.score)" }, perEnd: s.info.perEnd)
    }

    static func start(_ s: Session) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }
        let t = InkTheme.current
        let a = RoundActivity(round: s.info.name, distance: s.distanceText, setup: s.setup, ink: t.inkHex, fletch: t.fletchHex)
        activity = try? Activity.request(attributes: a, content: .init(state: state(s), staleDate: nil))
    }

    static func update(_ s: Session) {
        guard let activity else { return }
        let st = state(s)
        Task { await activity.update(.init(state: st, staleDate: nil)) }
    }

    static func end(_ s: Session?) {
        guard let a = activity else { return }
        activity = nil
        let st = s.map(state)
        Task { await a.end(st.map { .init(state: $0, staleDate: nil) }, dismissalPolicy: .after(.now.addingTimeInterval(60 * 15))) }
    }
}

// MARK: Tips

struct ScoreTip: Tip {
    var title: Text { Text("Score by tapping the face") }
    var message: Text? { Text("Tap where each arrow landed. After three arrows Quiver reads your group and tells you how far to move the sight.") }
    var image: Image? { Image(systemName: "target") }
}

struct WidgetTip: Tip {
    var title: Text { Text("Your marks on the Lock Screen") }
    var message: Text? { Text("Add the Sight Mark widget, or ask Siri \"What's my sight mark in Quiver?\"") }
    var image: Image? { Image(systemName: "lock.iphone") }
}

struct GroupTip: Tip {
    var title: Text { Text("Fix the mark in one tap") }
    var message: Text? { Text("Enter the sight reading when you start a round and Quiver can save the corrected mark straight to your tape.") }
    var image: Image? { Image(systemName: "ruler") }
}
