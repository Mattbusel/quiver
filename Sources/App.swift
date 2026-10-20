import AppIntents
import StoreKit
import SwiftUI
import TipKit

/// Store screenshots, the App Preview and the review recording run on demo data and never touch StoreKit.
enum Shots {
    static let args = ProcessInfo.processInfo.arguments
    static let on = args.contains("-shot") || args.contains("-demoAutoplay") || args.contains("-preview")
    static var name: String? { args.firstIndex(of: "-shot").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
}

@main
struct QuiverApp: App {
    @State private var store: Store
    @State private var router = Router()
    @State private var pro: Pro
    @State private var extras: Extras
    @State private var plus: Plus
    @Environment(\.scenePhase) private var phase
    init() {
        let a = ProcessInfo.processInfo.arguments
        let demo = Shots.on
        _store = State(initialValue: Store(demo: demo))
        // Store screenshots show everything; the paywall shot is the free app.
        // Store screenshots show everything; the paywall, Plus and shop-with-prices shots (for App Review only) are the free app.
        let lockedShot = a.contains("paywall") || a.contains("plus") || a.contains("shopbuy") || a.contains("-locked")
        _pro = State(initialValue: demo ? Pro(forced: !lockedShot) : Pro())
        _extras = State(initialValue: Extras(demo: demo))
        _plus = State(initialValue: demo ? Plus(forced: !lockedShot) : Plus())
        Sync.shared.demo = demo
        if demo { Tips.hideAllTipsForTesting() }
        try? Tips.configure([.displayFrequency(.daily)])
    }
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).environment(router).environment(pro).environment(extras).environment(plus)
                .preferredColorScheme(.light).tint(Kraft.ink)
                .onAppear {
                    extras.onCredit = { [store] id in
                        if id == Extras.printID { store.printCredits += 1 } else if id == Extras.postersID { store.posterCredits += 3 }
                        store.save()
                    }
                    plus.onChange = { [store, pro, extras, router] on in
                        let lapsed = pro.plus && !on
                        pro.plus = on
                        extras.setPlus(on)
                        if on && !Shots.on { store.plusRefill(Plus.monthlyPosters) }
                        if lapsed { router.themeTick += 1 }
                        Sync.shared.changed(store, unlocked: pro.has, plus: on)
                    }
                    store.onSave = { [store, pro, plus] in Sync.shared.changed(store, unlocked: pro.has, plus: plus.active) }
                    extras.start()
                    plus.start()
                    router.applyShotArgs(store, pro)
                    Autopilot.shared.run(store, router)
                    Sync.shared.changed(store, unlocked: pro.has, plus: plus.active)
                }
                .onOpenURL { router.open($0) }
                .onReceive(NotificationCenter.default.publisher(for: .quiverRoute)) { _ in router.consumeRoute() }
                .onChange(of: phase) { _, p in
                    if p == .active { router.consumeRoute(); Task { await plus.refresh() } }
                }
        }
    }
}

enum Tab: String, CaseIterable {
    case arrow = "Arrow", bow = "Bow", tape = "Sight tape", range = "Range"
    var icon: String {
        switch self {
        case .range: return "target"
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
    var shop = false
    var plus = false
    var widgets = false
    var newRound = false
    var scoring: UUID? = nil
    var session: UUID? = nil
    /// Screenshots of a card further down a page put it first.
    var focus: String? = nil
    /// Bumped when the ink changes, so every page redraws in it.
    var themeTick = 0
    let demo = Shots.on

    /// quiver://round, tape, range, challenge, widgets, plus. From widgets, In-App Events and Siri.
    func open(_ url: URL) {
        guard url.scheme == "quiver" else { return }
        go(url.host() ?? "")
    }
    func go(_ where_: String) {
        switch where_ {
        case "round": tab = .range; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.newRound = true }
        case "range", "challenge": tab = .range
        case "tape": tab = .tape
        case "arrow": tab = .arrow
        case "bow": tab = .bow
        case "widgets": tab = .tape; widgets = true
        case "plus": plus = true
        default: break
        }
    }
    func consumeRoute() {
        let d = QuiverGroup.defaults
        guard let r = d.string(forKey: QuiverGroup.routeKey) else { return }
        d.removeObject(forKey: QuiverGroup.routeKey)
        go(r)
    }

    @MainActor func applyShotArgs(_ s: Store, _ pro: Pro) {
        guard let name = Shots.name else { return }
        switch name {
        case "bow", "drop": tab = .bow
        case "tape": tab = .tape
        case "print": tab = .tape; showTape = true
        case "builder": tab = .arrow; s.arrow.point = 125; s.arrow.use = "elk"
        case "paywall": tab = .tape; pro.paywall = .print
        case "range": tab = .range
        case "insights": tab = .range; focus = "insights"
        case "widgets": tab = .tape; widgets = true
        case "session": tab = .range; session = s.sessions.first(where: { $0.round == "practice" })?.id
        case "scoring":
            tab = .range
            var x = Session(round: "wa18", distance: 18, yards: false, faceCm: 40, setup: s.currentName)
            x.ends = [s.sessions.first { $0.round == "wa18" }?.ends.first ?? End(), End(shots: [Shot(x: 0.03, y: 0.05, score: 10, x10: true), Shot(x: -0.12, y: 0.02, score: 9)])]
            s.sessions.insert(x, at: 0); scoring = x.id
        case "themes", "shopbuy": tab = .tape; shop = true
        case "plus": tab = .tape; plus = true
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
                case .range: RangeView()
                }
            }
            NotebookTabBar(selection: $router.tab).padding(.bottom, 2)
        }
        .id(router.themeTick)
        .sheet(isPresented: $router.showTape) { TapePreview().presentationBackground(Kraft.paper) }
        .sheet(isPresented: $router.shop) { ShopSheet().presentationBackground(Kraft.paper).presentationDetents([.large]) }
        .sheet(isPresented: $router.plus) { PlusPaywall().presentationBackground(Kraft.paper) }
        .sheet(isPresented: $router.widgets) { WidgetsPage().presentationBackground(Kraft.paper) }
        .sheet(isPresented: $router.newRound) { RoundPicker().presentationBackground(Kraft.paper).presentationDetents([.large]) }
        .sheet(item: Binding(get: { router.session.map(SessionID.init) }, set: { router.session = $0?.id })) { s in SessionDetail(id: s.id).presentationDetents([.large]) }
        .fullScreenCover(item: Binding(get: { router.scoring.map(SessionID.init) }, set: { router.scoring = $0?.id })) { s in ScoringView(id: s.id) }
        .sheet(item: $pro.paywall) { r in PaywallView(reason: r).presentationBackground(Kraft.paper) }
    }
}

struct SessionID: Identifiable { let id: UUID }

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
            Text(title).font(.hand(34, .bold)).foregroundStyle(Kraft.ink).accessibilityAddTraits(.isHeader)
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
                if pro.has { text = ""; naming = .new } else { pro.ask(.setups) }
            } label: { Label(pro.has ? "New setup" : "New setup (Pro)", systemImage: pro.has ? "plus" : "lock") }
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
        .accessibilityLabel("Setup: \(store.currentName)")
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

/// Siri and Shortcuts phrases. The intents themselves live in Shared so the widgets and Controls can run them too.
struct QuiverShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: SightMarkIntent(), phrases: [
            "What's my sight mark in \(.applicationName)",
            "Sight mark in \(.applicationName)",
            "Read my \(.applicationName) tape",
        ], shortTitle: "Sight Mark", systemImageName: "scope")
        AppShortcut(intent: StartRoundIntent(), phrases: [
            "Shoot a round in \(.applicationName)",
            "Start a round in \(.applicationName)",
            "Score a round with \(.applicationName)",
        ], shortTitle: "Shoot a Round", systemImageName: "target")
    }
}
