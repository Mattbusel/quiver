import Foundation
import Observation

struct Arrow: Codable {
    var length: Double = 28.5      // inches, nock throat to shaft end
    var gpi: Double = 8.6
    var diameter: Double = 0.246
    var point: Double = 100
    var insert: Double = 20
    var nock: Double = 10
    var vane: Double = 8
    var vaneCount: Double = 3
    var wrap: Double = 8
    var use: String = "deer"

    var shaft: Double { length * gpi }
    var fletch: Double { vane * vaneCount }
    var total: Double { shaft + point + insert + nock + fletch + wrap }
    /// Balance point from the nock throat, inches.
    var balance: Double {
        let L = length
        let moment = fletch * 1.5 + wrap * 4 + shaft * L / 2 + insert * (L - 0.5) + point * (L + 0.4)
        return moment / max(1, total)
    }
    var foc: Double { 100 * (balance / max(1, length) - 0.5) }
}

struct Bow: Codable {
    var type: String = "compound"
    var drawWeight: Double = 62
    var drawLength: Double = 28.5
    var ibo: Double = 335
    var stringExtras: Double = 25
    var chrono: Double = 0            // 0 = estimate
    var sightRadius: Double = 34
}

struct Mark: Codable, Identifiable, Hashable {
    var id = UUID()
    var distance: Double
    var reading: Double
}

struct TapeSettings: Codable {
    var unitMM: Double = 1            // mm per sight unit; 0 = clicks
    var clicksPerMM: Double = 10
    var yards: Bool = true
    var from: Double = 20
    var to: Double = 80
    var every: Double = 10
    var widthMM: Double = 14
    var marks: [Mark] = [Mark(distance: 20, reading: 12.5), Mark(distance: 60, reading: 41.2)]
}

@Observable
final class Store {
    var arrow = Arrow()
    var bow = Bow()
    var tape = TapeSettings()
    private var saveTask: Task<Void, Never>?
    private let url = URL.documentsDirectory.appending(path: "quiver.json")
    struct Disk: Codable { var arrow: Arrow; var bow: Bow; var tape: TapeSettings }

    init(demo: Bool) {
        if demo { return }
        if let d = try? Data(contentsOf: url), let disk = try? JSONDecoder().decode(Disk.self, from: d) { arrow = disk.arrow; bow = disk.bow; tape = disk.tape }
    }
    func save() {
        saveTask?.cancel(); let disk = Disk(arrow: arrow, bow: bow, tape: tape); let u = url
        saveTask = Task.detached(priority: .utility) {
            try? await Task.sleep(for: .milliseconds(250)); if Task.isCancelled { return }
            if let d = try? JSONEncoder().encode(disk) { try? d.write(to: u, options: .atomic) }
        }
    }

    // MARK: speed and ballistics

    var speed: Double {
        if bow.chrono > 0 { return bow.chrono }
        let w = arrow.total
        var v: Double
        switch bow.type {
        case "compound": v = bow.ibo - 10 * (30 - bow.drawLength) - 2 * (70 - bow.drawWeight) - (w - 350) / 3 - bow.stringExtras / 3
        case "recurve": v = 160 + (bow.drawWeight - 30) * 1.5 - (w - 400) / 8 - 5 * (28 - bow.drawLength)
        default: v = 150 + (bow.drawWeight - 40) * 1.4 - (w - 500) / 9 - 5 * (28 - bow.drawLength)
        }
        return max(120, v)
    }
    var estimated: Bool { bow.chrono <= 0 }
    var ke: Double { arrow.total * speed * speed / 450240 }
    var momentum: Double { arrow.total * speed / 225218 }

    /// Drag per foot, scaled so a 407 gr .246" three-vane arrow loses about 4% over 40 yards.
    var drag: Double {
        let area = Double.pi * (arrow.diameter / 2) * (arrow.diameter / 2)
        let vaneArea = arrow.vaneCount * 0.9 * 0.5 * 0.06
        return 0.0006 * (area + 2.5 * vaneArea) / 0.25 * 407 / max(1, arrow.total)
    }

    /// Height (ft) at distance (ft) for a launch angle, drag-free-ish integration.
    func height(angle: Double, dist: Double) -> Double {
        var x = 0.0, y = 0.0, vx = speed * cos(angle), vy = speed * sin(angle)
        let dt = 0.002, g = 32.174, k = drag
        while x < dist {
            let v = (vx * vx + vy * vy).squareRoot()
            vx += -k * v * vx * dt; vy += (-g - k * v * vy) * dt
            x += vx * dt; y += vy * dt
            if y < -60 { break }
        }
        return y
    }
    func angle(forFeet d: Double) -> Double {
        var lo = 0.0, hi = 0.25
        for _ in 0..<26 { let m = (lo + hi) / 2; if height(angle: m, dist: d) < 0 { lo = m } else { hi = m } }
        return (lo + hi) / 2
    }
    func flight(feet d: Double) -> (time: Double, speed: Double) {
        var x = 0.0, t = 0.0, v = speed; let dt = 0.002, k = drag
        while x < d { v -= k * v * v * dt; x += v * dt; t += dt }
        return (t, v)
    }

    /// Spine starting point from effective draw weight.
    var effectiveWeight: Double {
        var e = bow.drawWeight + (arrow.point + arrow.insert - 125) / 25 * 3 + (arrow.length - 28) * 5
        if bow.type != "compound" { e -= 10 }
        return e
    }
    var spine: Int {
        let e = effectiveWeight
        return e <= 40 ? 600 : e <= 48 ? 500 : e <= 58 ? 400 : e <= 68 ? 340 : e <= 78 ? 300 : 250
    }

    // MARK: tape fit: reading = a + b * tan(angle)

    var feetPerUnit: Double { tape.yards ? 3 : 3.28084 }
    var fit: (a: Double, b: Double, residuals: [Double])? {
        let marks = tape.marks.filter { $0.distance > 0 }.sorted { $0.distance < $1.distance }
        guard marks.count >= 2 else { return nil }
        let xs = marks.map { tan(angle(forFeet: $0.distance * feetPerUnit)) }, ys = marks.map { $0.reading }
        let n = Double(xs.count), mx = xs.reduce(0, +) / n, my = ys.reduce(0, +) / n
        var num = 0.0, den = 0.0
        for i in 0..<xs.count { num += (xs[i] - mx) * (ys[i] - my); den += (xs[i] - mx) * (xs[i] - mx) }
        guard den > 0 else { return nil }
        let b = num / den, a = my - b * mx
        let res = (0..<xs.count).map { ys[$0] - (a + b * xs[$0]) }
        return (a, b, res)
    }
    func reading(at distance: Double) -> Double? {
        guard let f = fit else { return nil }
        return f.a + f.b * tan(angle(forFeet: distance * feetPerUnit))
    }
    var mmPerUnit: Double { tape.unitMM == 0 ? 1 / max(0.1, tape.clicksPerMM) : tape.unitMM }
}

func f1(_ v: Double, _ d: Int = 1) -> String { String(format: "%.\(d)f", v) }
