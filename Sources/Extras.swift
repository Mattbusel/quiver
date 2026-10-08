import StoreKit
import SwiftUI

/// Ink colours for the notebook. Field Green is the original and free; the rest are 99-cent themes,
/// each with its own app icon.
struct InkTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let blurb: String
    let ink: Color
    let fletch: Color
    let fletchDeep: Color
    var icon: String? { id == "field" ? nil : "AppIcon-" + name.replacingOccurrences(of: " ", with: "") }

    static func rgb(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
    static let all: [InkTheme] = [
        InkTheme(id: "field", name: "Field Green", blurb: "Forest ink, chartreuse fletching. Free.", ink: rgb(0x1F3D2B), fletch: rgb(0x9EDB24), fletchDeep: rgb(0x6B9E0F)),
        InkTheme(id: "blaze", name: "Blaze", blurb: "Hunter orange on charcoal.", ink: rgb(0x26262A), fletch: rgb(0xFF7A1A), fletchDeep: rgb(0xC2510A)),
        InkTheme(id: "navy", name: "Navy", blurb: "Navy ink and range-flag yellow.", ink: rgb(0x1B2A4A), fletch: rgb(0xFFD23F), fletchDeep: rgb(0xC79A0A)),
        InkTheme(id: "oxblood", name: "Oxblood", blurb: "Old leather quiver, sky-blue vanes.", ink: rgb(0x4A1A1C), fletch: rgb(0x7CC6F2), fletchDeep: rgb(0x2F86BD)),
        InkTheme(id: "timber", name: "Timber", blurb: "Walnut ink and hot pink vanes.", ink: rgb(0x3B2A1A), fletch: rgb(0xFF5FA2), fletchDeep: rgb(0xD12E77)),
    ]
    static var current: InkTheme = byID(UserDefaults.standard.string(forKey: "quiver.theme") ?? "field")
    static func byID(_ id: String) -> InkTheme { all.first { $0.id == id } ?? all[0] }
    static func apply(_ id: String) { UserDefaults.standard.set(id, forKey: "quiver.theme"); current = byID(id) }
}

/// The 99-cent corner. Two consumables that get used up and bought again (a one-off tape print,
/// scorecard posters), and one-time ink themes. Separate from Pro so Pro's grandfathering stays untouched.
@MainActor
@Observable
final class Extras {
    nonisolated static let printID = "com.mattbusel.quiver.print1"
    nonisolated static let postersID = "com.mattbusel.quiver.posters"
    nonisolated static func themeID(_ id: String) -> String { "com.mattbusel.quiver.theme." + id }
    nonisolated static var allIDs: [String] { [printID, postersID] + InkTheme.all.filter { $0.id != "field" }.map { themeID($0.id) } }

    private(set) var owned: Set<String>
    private(set) var products: [String: Product] = [:]
    var busy: String? = nil
    var message: String? = nil
    /// Credits land in the store, which saves them with everything else.
    var onCredit: ((String) -> Void)?
    private var updates: Task<Void, Never>?
    private let demo: Bool

    init(demo: Bool) {
        self.demo = demo
        let a = ProcessInfo.processInfo.arguments
        if demo { owned = a.contains("themes") ? [Extras.themeID("blaze")] : Set(Extras.allIDs) }
        else { owned = Set((UserDefaults.standard.array(forKey: "quiver.owned") as? [String]) ?? []) }
    }

    func ownsTheme(_ id: String) -> Bool { id == "field" || owned.contains(Extras.themeID(id)) }
    func price(_ id: String) -> String { products[id]?.displayPrice ?? "$0.99" }

    func start() {
        guard !demo, updates == nil else { return }
        updates = Task { [weak self] in
            for await r in Transaction.updates {
                guard let self, case .verified(let t) = r, Extras.allIDs.contains(t.productID) else { continue }
                self.credit(t); await t.finish(); await self.refresh()
            }
        }
        Task {
            await refresh()
            if let ps = try? await Product.products(for: Extras.allIDs) { for p in ps { products[p.id] = p } }
            for await r in Transaction.unfinished {
                if case .verified(let t) = r, Extras.allIDs.contains(t.productID) { credit(t); await t.finish() }
            }
        }
    }

    func refresh() async {
        var has: Set<String> = []
        for await r in Transaction.currentEntitlements {
            if case .verified(let t) = r, t.revocationDate == nil, t.productType == .nonConsumable, Extras.allIDs.contains(t.productID) { has.insert(t.productID) }
        }
        owned = has
        UserDefaults.standard.set(Array(has), forKey: "quiver.owned")
        if !ownsTheme(InkTheme.current.id) { InkTheme.apply("field") }
    }

    /// A consumable is banked once per transaction, however often StoreKit reports it.
    private func credit(_ t: StoreKit.Transaction) {
        guard t.productType == .consumable, t.revocationDate == nil else { return }
        let d = UserDefaults.standard
        var seen = Set((d.array(forKey: "quiver.credited") as? [String]) ?? [])
        guard !seen.contains(String(t.id)) else { return }
        seen.insert(String(t.id)); d.set(Array(seen), forKey: "quiver.credited")
        onCredit?(t.productID)
    }

    @discardableResult
    func buy(_ id: String) async -> Bool {
        message = nil
        if demo { if id == Extras.printID || id == Extras.postersID { onCredit?(id) } else { owned.insert(id) }; return true }
        if products[id] == nil, let ps = try? await Product.products(for: [id]) { for p in ps { products[p.id] = p } }
        guard let product = products[id] else { message = "The App Store did not answer. Check your connection and try again."; return false }
        busy = id; defer { busy = nil }
        do {
            switch try await product.purchase() {
            case .success(let r):
                guard case .verified(let t) = r else { message = "Apple could not confirm that purchase. Try again in a minute."; return false }
                credit(t); await t.finish(); await refresh()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                return true
            case .pending: message = "Waiting for approval. It arrives by itself once approved."
            case .userCancelled: break
            @unknown default: break
            }
        } catch { message = "The purchase did not go through: \(error.localizedDescription)" }
        return false
    }

    func restore() async {
        busy = "restore"; defer { busy = nil }
        try? await AppStore.sync()
        await refresh()
    }
}

// MARK: Shop

struct ShopSheet: View {
    @Environment(Store.self) private var store
    @Environment(Extras.self) private var extras
    @Environment(Pro.self) private var pro
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var current = InkTheme.current.id
    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Eyebrow("The back pocket")
                            Text("Inks and extras.").font(.hand(30, .bold)).foregroundStyle(Kraft.ink)
                        }
                        Spacer()
                        Button("Done") { dismiss() }.font(.note(15, .bold)).foregroundStyle(Kraft.ink)
                    }.padding(.top, 20)
                    Text("Each ink recolours the whole notebook and swaps the app icon to match. \(extras.price(Extras.themeID("blaze"))) each, yours for good.").font(.note(13)).foregroundStyle(Kraft.ink2)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(InkTheme.all) { t in card(t) }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow("Credits")
                        creditRow("printer", "One tape print", pro.unlocked ? "Pro prints as many tapes as you like." : "Print one true-size tape without Pro. You have \(store.printCredits).", Extras.printID, hide: pro.unlocked)
                        creditRow("photo.artframe", "Scorecard posters, three", "Kraft-paper scorecards of your rounds, ready to post. You have \(store.posterCredits)\(store.freePosterUsed ? "" : ", plus one free").", Extras.postersID, hide: false)
                    }.sheet(tilt: -0.3)
                    if let m = extras.message { Text(m).font(.note(12, .semibold)).foregroundStyle(Kraft.red) }
                    Button { Task { await extras.restore(); await pro.restore() } } label: {
                        Label("Restore purchases", systemImage: "arrow.clockwise").font(.note(13, .bold)).foregroundStyle(Kraft.ink2)
                    }.buttonStyle(.plain)
                }.padding(.leading, 30).padding(.trailing, 18).padding(.bottom, 40)
            }
        }
    }

    func card(_ t: InkTheme) -> some View {
        let owned = extras.ownsTheme(t.id), on = current == t.id
        return Button {
            if owned { use(t) } else { Task { if await extras.buy(Extras.themeID(t.id)) { use(t) } } }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Canvas { ctx, size in
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Kraft.paper))
                    let cy = size.height / 2
                    ctx.fill(Path(roundedRect: CGRect(x: 14, y: cy - 2, width: size.width - 34, height: 4), cornerRadius: 2), with: .color(t.ink))
                    for s in [-1.0, 1.0] {
                        var v = Path(); v.move(to: CGPoint(x: 18, y: cy + s * 2)); v.addLine(to: CGPoint(x: 24, y: cy + s * 14)); v.addLine(to: CGPoint(x: 44, y: cy + s * 12)); v.addLine(to: CGPoint(x: 48, y: cy + s * 2)); v.closeSubpath()
                        ctx.fill(v, with: .color(s < 0 ? t.fletch : t.fletchDeep))
                    }
                    var tip = Path(); tip.move(to: CGPoint(x: size.width - 20, y: cy - 6)); tip.addLine(to: CGPoint(x: size.width - 8, y: cy)); tip.addLine(to: CGPoint(x: size.width - 20, y: cy + 6)); tip.closeSubpath()
                    ctx.fill(tip, with: .color(t.ink))
                }.frame(height: 54).clipShape(RoundedRectangle(cornerRadius: 4))
                HStack {
                    Text(t.name).font(.hand(15, .bold)).foregroundStyle(Kraft.ink)
                    Spacer()
                    if on { Image(systemName: "checkmark.circle.fill").foregroundStyle(t.fletchDeep) }
                    else if owned { Text("Use").font(.note(12, .heavy)).foregroundStyle(t.ink) }
                    else if extras.busy == Extras.themeID(t.id) { ProgressView() }
                    else { Text(extras.price(Extras.themeID(t.id))).font(.note(11, .heavy)).foregroundStyle(.white).padding(.horizontal, 7).padding(.vertical, 3).background(Capsule().fill(t.ink)) }
                }
                Text(t.blurb).font(.note(11)).foregroundStyle(Kraft.ink2).lineLimit(2, reservesSpace: true)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Kraft.card).shadow(color: Kraft.ink.opacity(0.15), radius: 6, y: 3))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(on ? t.ink : Kraft.ink.opacity(0.1), lineWidth: on ? 2 : 1))
        }.buttonStyle(.plain).disabled(extras.busy != nil)
    }

    @ViewBuilder func creditRow(_ icon: String, _ title: String, _ detail: String, _ id: String, hide: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(Kraft.ink).frame(width: 34, height: 34).background(Circle().fill(Kraft.fletch))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.hand(16, .bold)).foregroundStyle(Kraft.ink)
                Text(detail).font(.note(12)).foregroundStyle(Kraft.ink2).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            if !hide {
                Button { Task { await extras.buy(id) } } label: {
                    Group { if extras.busy == id { ProgressView().tint(Kraft.card) } else { Text(extras.price(id)).font(.note(13, .heavy)) } }
                        .foregroundStyle(Kraft.card).padding(.horizontal, 12).padding(.vertical, 8).background(Capsule().fill(Kraft.ink))
                }.buttonStyle(.plain).disabled(extras.busy != nil)
            }
        }
    }

    func use(_ t: InkTheme) {
        InkTheme.apply(t.id)
        current = t.id
        if !router.demo, UIApplication.shared.supportsAlternateIcons, UIApplication.shared.alternateIconName != t.icon {
            UIApplication.shared.setAlternateIconName(t.icon)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        router.themeTick += 1
    }
}
