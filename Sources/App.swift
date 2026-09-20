import SwiftUI

@main
struct QuiverApp: App {
    @State private var store: Store
    @State private var router = Router()
    init() {
        let a = ProcessInfo.processInfo.arguments
        _store = State(initialValue: Store(demo: a.contains("-shot") || a.contains("-demoAutoplay")))
    }
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).environment(router).preferredColorScheme(.light).tint(Kraft.ink)
                .onAppear { router.applyShotArgs(store); Autopilot.shared.run(store, router) }
        }
    }
}

enum Tab: String, CaseIterable {
    case arrow = "Arrow", bow = "Bow", tape = "Sight tape"
    var icon: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .bow: return "scope"
        case .tape: return "ruler"
        }
    }
}

@Observable
final class Router {
    var tab: Tab = .arrow
    var showTape = false
    func applyShotArgs(_ s: Store) {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-shot"), i + 1 < a.count else { return }
        switch a[i + 1] {
        case "bow", "drop": tab = .bow
        case "tape": tab = .tape
        case "print": tab = .tape; showTape = true
        case "builder": tab = .arrow; s.arrow.point = 125; s.arrow.use = "elk"
        default: break
        }
    }
}

struct RootView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    var body: some View {
        @Bindable var router = router
        ZStack(alignment: .bottom) {
            PaperBackground()
            Group {
                switch router.tab {
                case .arrow: ArrowView()
                case .bow: BowView()
                case .tape: TapeView()
                }
            }
            NotebookTabBar(selection: $router.tab).padding(.bottom, 2)
        }
        .sheet(isPresented: $router.showTape) { TapePreview().presentationBackground(Kraft.paper) }
    }
}

struct Page<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) { content }.padding(.leading, 44).padding(.trailing, 18).padding(.top, 8).padding(.bottom, 110)
        }
    }
}

struct PageHeader: View {
    let eyebrow: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(eyebrow)
            Text(title).font(.hand(34, .bold)).foregroundStyle(Kraft.ink)
        }.padding(.top, 12)
    }
}
