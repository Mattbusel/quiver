import SwiftUI

/// Drives the real screens for the App Review recording (-demoAutoplay).
@Observable
final class Autopilot {
    static let shared = Autopilot()
    static var on: Bool { ProcessInfo.processInfo.arguments.contains("-demoAutoplay") }
    private var running = false
    @MainActor private func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
    @MainActor
    func run(_ store: Store, _ router: Router) {
        guard Autopilot.on, !running else { return }
        running = true
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
            try? Data("ok".utf8).write(to: URL.documentsDirectory.appending(path: "demo_done"))
        }
    }
}
