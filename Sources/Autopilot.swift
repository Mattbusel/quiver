import SwiftUI

/// Drives the real screens for the App Review recording (-demoAutoplay) and the App Store preview (-preview).
@Observable
final class Autopilot {
    static let shared = Autopilot()
    static var on: Bool { ProcessInfo.processInfo.arguments.contains("-demoAutoplay") }
    static var preview: Bool { ProcessInfo.processInfo.arguments.contains("-preview") }
    private var running = false
    @MainActor private func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
    @MainActor
    func run(_ store: Store, _ router: Router) {
        guard Autopilot.on || Autopilot.preview, !running else { return }
        running = true
        if Autopilot.preview { Task { @MainActor in await self.previewFlow(store, router) }; return }
        Task { @MainActor in
            await wait(3)
            store.arrow.point = 125; await wait(1.5)
            store.arrow.point = 150; await wait(1.5)
            router.tab = .bow; await wait(3)
            store.bow.chrono = 281; await wait(2.5)
            router.tab = .tape; await wait(3)
            store.tape.marks.append(Mark(distance: 40, reading: 24.3)); await wait(2.5)
            router.showTape = true; await wait(4)
            router.showTape = false; await wait(1)
            router.widgets = true; await wait(4)
            router.widgets = false; await wait(1)
            router.tab = .range; await wait(3)
            var x = Session(round: "wa18", distance: 18, yards: false, faceCm: 40, setup: store.currentName)
            x.ends = [End()]
            store.sessions.insert(x, at: 0)
            router.scoring = x.id; await wait(2)
            for (px, py) in [(0.04, 0.06), (-0.1, -0.02), (0.08, -0.12)] {
                let (sc, x10) = Face.wa10.score(r: (px * px + py * py).squareRoot())
                store.sessions[0].ends[0].shots.append(Shot(x: px, y: py, score: sc, x10: x10)); await wait(1.2)
            }
            await wait(1.5)
            router.scoring = nil; await wait(1)
            router.session = store.sessions.first { $0.round == "practice" }?.id; await wait(4)
            router.session = nil; await wait(1)
            router.plus = true; await wait(4)
            router.plus = false; await wait(1)
            router.shop = true; await wait(3)
            router.shop = false; await wait(1)
            try? Data("ok".utf8).write(to: URL.documentsDirectory.appending(path: "demo_done"))
        }
    }

    /// About 26 seconds: score an end, read the group, the tape, the Lock Screen, insights, an ink. No prices on screen.
    @MainActor private func previewFlow(_ store: Store, _ router: Router) async {
        await wait(2.5)                                   // the recording starts a moment after launch
        router.tab = .range; await wait(2)
        var x = Session(round: "wa18", distance: 18, yards: false, faceCm: 40, setup: store.currentName)
        x.ends = [End()]
        store.sessions.insert(x, at: 0)
        router.scoring = x.id; await wait(1.4)
        for (px, py) in [(0.03, 0.04), (-0.08, 0.1), (0.11, -0.05)] {
            let (sc, x10) = Face.wa10.score(r: (px * px + py * py).squareRoot())
            store.sessions[0].ends[0].shots.append(Shot(x: px, y: py, score: sc, x10: x10)); await wait(0.9)
        }
        await wait(1)
        router.scoring = nil; await wait(0.8)
        router.session = store.sessions.first { $0.round == "practice" }?.id; await wait(3.5)
        router.session = nil; await wait(0.8)
        router.tab = .tape; await wait(2.2)
        router.showTape = true; await wait(2.5)
        router.showTape = false; await wait(0.8)
        router.widgets = true; await wait(3.5)
        router.widgets = false; await wait(0.8)
        router.tab = .range; router.focus = "insights"; await wait(3)
        router.focus = nil
        router.tab = .tape; router.shop = true; await wait(1.5)
        InkTheme.apply("blaze"); router.themeTick += 1; await wait(2.5)
        try? Data("ok".utf8).write(to: URL.documentsDirectory.appending(path: "demo_done"))
    }
}
