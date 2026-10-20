import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The app group both the app and the widget extension read: a small Glance of the notebook, written by the app.
enum QuiverGroup {
    static let id = "group.com.mattbusel.quiver"
    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }
    /// A screen the app should open next time it comes forward (set by a Control or Siri).
    static let routeKey = "quiver.route"
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// What the widgets show. Precomputed by the app on every save, so the extension never runs the ballistics.
struct Glance: Codable, Equatable {
    var setup: String = "My bow"
    var yards: Bool = true
    var unit: String = "mm"
    /// Whole distances and their fitted sight readings, from a little before the tape starts to a little past its end.
    var distances: [Double] = []
    var readings: [Double] = []
    var lastRound: String? = nil
    var lastTotal: Int? = nil
    var lastOutOf: Int? = nil
    var lastXs: Int = 0
    var lastDate: Date? = nil
    var lastDistance: String = ""
    /// Percent of possible for the last few scored rounds, oldest first.
    var recent: [Double] = []
    var unlocked: Bool = false
    var ink: UInt32 = 0x1F3D2B
    var fletch: UInt32 = 0x9EDB24
    var challenge: String = ""
    var challengeProgress: Double = 0

    static let key = "quiver.glance"
    static let distanceKey = "quiver.widget.distance"

    static func load() -> Glance {
        guard let d = QuiverGroup.defaults.data(forKey: key), let g = try? JSONDecoder().decode(Glance.self, from: d) else { return Glance() }
        return g
    }
    func save() {
        if let d = try? JSONEncoder().encode(self) { QuiverGroup.defaults.set(d, forKey: Glance.key) }
    }

    var hasTape: Bool { !distances.isEmpty }
    var unitWord: String { yards ? "yd" : "m" }

    /// The distance the Sight Mark widget is on: the one picked with its buttons, else 40 (or the middle of the tape).
    var selected: Int? {
        guard hasTape else { return nil }
        let want = QuiverGroup.defaults.object(forKey: Glance.distanceKey) as? Double ?? 40
        return distances.indices.min { abs(distances[$0] - want) < abs(distances[$1] - want) }
    }
    func reading(at d: Double) -> Double? {
        guard hasTape, d >= distances[0] - 0.01, d <= distances[distances.count - 1] + 0.01 else { return nil }
        // Linear between the stored whole distances: they are 1 unit apart, so this is exact to the hundredth.
        if let i = distances.firstIndex(where: { $0 >= d }) {
            if i == 0 || distances[i] == d { return readings[i] }
            let t = (d - distances[i - 1]) / (distances[i] - distances[i - 1])
            return readings[i - 1] + t * (readings[i] - readings[i - 1])
        }
        return readings.last
    }
    /// Labelled rows for the mini tape: every 10 (or 5 on a short tape).
    var tapeRows: [(Double, Double)] {
        guard hasTape else { return [] }
        let span = (distances.last ?? 0) - (distances.first ?? 0)
        let every: Double = span > 50 ? 10 : 5
        return zip(distances, readings).filter { $0.0.truncatingRemainder(dividingBy: every) == 0 }.map { ($0.0, $0.1) }
    }

    static func step(_ by: Double) {
        let g = load()
        guard let i = g.selected else { return }
        let now = g.distances[i]
        let next = min(g.distances.last ?? now, max(g.distances.first ?? now, (now / 5).rounded() * 5 + by))
        QuiverGroup.defaults.set(next, forKey: distanceKey)
    }

    static let sample: Glance = {
        var g = Glance()
        g.setup = "Hunting rig"
        g.distances = Array(stride(from: 15.0, through: 90, by: 1))
        g.readings = g.distances.map { 0.62 * $0 + 0.0011 * $0 * $0 - 0.6 }
        g.lastRound = "WA 18 m indoor"; g.lastTotal = 548; g.lastOutOf = 600; g.lastXs = 14; g.lastDate = .now; g.lastDistance = "18 m"
        g.recent = [0.84, 0.86, 0.85, 0.88, 0.87, 0.9, 0.91]
        g.unlocked = true
        g.challenge = "Ten Xs this month"; g.challengeProgress = 0.6
        return g
    }()
}

func fmt(_ v: Double, _ d: Int = 1) -> String { String(format: "%.\(d)f", v) }

// MARK: Live Activity

/// A round in progress, on the Lock Screen and in the Dynamic Island.
struct RoundActivity: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var total: Int
        var end: Int
        var ends: Int?
        var arrows: Int
        var xs: Int
        var outOf: Int?
        /// The current end, "X", "10", "9", "M".
        var current: [String]
        var perEnd: Int
    }
    var round: String
    var distance: String
    var setup: String
    var ink: UInt32
    var fletch: UInt32
}

// MARK: Intents (shared by the widgets, Controls, Siri and Shortcuts)

/// The +5 / -5 buttons on the Sight Mark widget.
struct StepDistanceIntent: AppIntent {
    static var title: LocalizedStringResource = "Change the widget distance"
    static var isDiscoverable: Bool = false
    @Parameter(title: "Step") var step: Int
    init() { step = 5 }
    init(step: Int) { self.step = step }
    func perform() async throws -> some IntentResult {
        Glance.step(Double(step))
        return .result()
    }
}

/// "What's my 40 yard mark?" Reads the fitted tape of the current setup.
struct SightMarkIntent: AppIntent {
    static var title: LocalizedStringResource = "Sight Mark"
    static var description = IntentDescription("Reads your sight mark for any distance from the current Quiver setup.")
    @Parameter(title: "Distance", requestValueDialog: "How far?") var distance: Double
    static var parameterSummary: some ParameterSummary { Summary("Sight mark at \(\.$distance)") }
    init() {}
    init(distance: Double) { self.distance = distance }
    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        let g = Glance.load()
        guard g.hasTape else {
            return .result(value: 0, dialog: "Add two sight marks on Quiver's Sight tape page first.")
        }
        guard let r = g.reading(at: distance) else {
            return .result(value: 0, dialog: "\(fmt(distance, 0)) \(g.unitWord) is off \(g.setup)'s tape, which runs \(fmt(g.distances.first ?? 0, 0)) to \(fmt(g.distances.last ?? 0, 0)).")
        }
        return .result(value: (r * 100).rounded() / 100, dialog: "\(fmt(distance, 0)) \(g.unitWord): \(fmt(r, 2)) on \(g.setup).")
    }
}

/// Opens the app on a new round. Used by the Control Center control and Siri.
struct StartRoundIntent: AppIntent {
    static var title: LocalizedStringResource = "Shoot a Round"
    static var description = IntentDescription("Opens Quiver's score book on a new round.")
    static var openAppWhenRun: Bool = true
    init() {}
    func perform() async throws -> some IntentResult {
        QuiverGroup.defaults.set("round", forKey: QuiverGroup.routeKey)
        await MainActor.run { NotificationCenter.default.post(name: .quiverRoute, object: nil) }
        return .result()
    }
}

extension Notification.Name {
    static let quiverRoute = Notification.Name("quiver.route")
}
