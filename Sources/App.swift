import SwiftUI

@main
struct QuiverApp: App {
    @State private var store: Store
    @State private var router = Router()
    @State private var pro: Pro
    init() {
        let a = ProcessInfo.processInfo.arguments
        let demo = a.contains("-shot") || a.contains("-demoAutoplay")
        _store = State(initialValue: Store(demo: demo))
        // Store screenshots show everything; the paywall shot is the free app.
        let lockedShot = a.contains("paywall") || a.contains("-locked")
        _pro = State(initialValue: demo ? Pro(forced: !lockedShot) : Pro())
    }
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).environment(router).environment(pro).preferredColorScheme(.light).tint(Kraft.ink)
                .onAppear { router.applyShotArgs(store, pro); Autopilot.shared.run(store, router) }
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
    @MainActor func applyShotArgs(_ s: Store, _ pro: Pro) {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-shot"), i + 1 < a.count else { return }
        switch a[i + 1] {
        case "bow", "drop": tab = .bow
        case "tape": tab = .tape
        case "print": tab = .tape; showTape = true
        case "builder": tab = .arrow; s.arrow.point = 125; s.arrow.use = "elk"
        case "paywall": tab = .tape; pro.paywall = .print
        default: break
        }
    }
}

struct RootView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(Pro.self) private var pro
    var body: some View {
        @Bindable var router = router
        @Bindable var pro = pro
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
        .sheet(item: $pro.paywall) { r in PaywallView(reason: r).presentationBackground(Kraft.paper) }
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
            HStack(alignment: .center) { Eyebrow(eyebrow); Spacer(); SetupChip() }
            Text(title).font(.hand(34, .bold)).foregroundStyle(Kraft.ink)
        }.padding(.top, 12)
    }
}

/// Which bow this page is about. More than one setup is Pro; switching between ones you have never is.
struct SetupChip: View {
    @Environment(Store.self) private var store
    @Environment(Pro.self) private var pro
    @State private var naming: Naming? = nil
    @State private var text = ""
    @State private var confirmDelete = false
    enum Naming: Identifiable { case new, rename; var id: Int { self == .new ? 0 : 1 } }

    var body: some View {
        Menu {
            ForEach(Array(store.setups.enumerated()), id: \.element.id) { i, s in
                Button { store.select(i) } label: {
                    if i == store.current { Label(s.name, systemImage: "checkmark") } else { Text(s.name) }
                }
            }
            Divider()
            Button {
                if pro.unlocked { text = ""; naming = .new } else { pro.ask(.setups) }
            } label: { Label(pro.unlocked ? "New setup" : "New setup (Pro)", systemImage: pro.unlocked ? "plus" : "lock") }
            Button { text = store.currentName; naming = .rename } label: { Label("Rename", systemImage: "pencil") }
            if store.setups.count > 1 {
                Button(role: .destructive) { confirmDelete = true } label: { Label("Delete this setup", systemImage: "trash") }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "scope").font(.system(size: 11, weight: .bold))
                Text(store.currentName).font(.hand(13, .bold)).lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .heavy))
            }
            .foregroundStyle(Kraft.ink)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(Kraft.card).shadow(color: Kraft.ink.opacity(0.15), radius: 4, y: 2))
            .overlay(Capsule().strokeBorder(Kraft.ink.opacity(0.15)))
        }
        .alert(naming == .new ? "New setup" : "Rename setup", isPresented: Binding(get: { naming != nil }, set: { if !$0 { naming = nil } })) {
            TextField("Name", text: $text)
            Button("Cancel", role: .cancel) { naming = nil }
            Button("Save") {
                let n = text.trimmingCharacters(in: .whitespaces)
                if naming == .new { store.addSetup(named: n.isEmpty ? "Setup \(store.setups.count + 1)" : n) } else { store.rename(n) }
                naming = nil
            }
        } message: { Text(naming == .new ? "Starts as a copy of \(store.currentName)." : "") }
        .confirmationDialog("Delete \(store.currentName)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { store.deleteCurrent() }
        }
    }
}
