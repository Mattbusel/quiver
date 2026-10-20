import StoreKit
import SwiftUI

/// Quiver Plus: the auto-renewable tier. Everything in Pro while subscribed, plus Insights, iCloud backup,
/// every ink, five scorecard posters a month and a bonus monthly challenge.
///
/// Separate from Pro and Extras on purpose: Pro's one-time unlock and its grandfathering are untouched, and a
/// lapsed subscription takes back only what Plus lent (Pro owners keep Pro, bought inks stay bought).
@MainActor
@Observable
final class Plus {
    nonisolated static let monthlyID = "com.mattbusel.quiver.plus.monthly"
    nonisolated static let yearlyID = "com.mattbusel.quiver.plus.yearly"
    nonisolated static let ids = [yearlyID, monthlyID]
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://tensorust.com/apps/quiver/privacy/")!
    /// Monthly poster credits that come with Plus.
    static let monthlyPosters = 5

    private(set) var active: Bool
    private(set) var products: [String: Product] = [:]
    private(set) var current: String? = nil
    private(set) var renews: Date? = nil
    private(set) var willRenew = true
    private(set) var trialEligible = true
    var busy = false
    var message: String? = nil
    /// Called when Plus is on, so the store can top up this month's posters and the other objects can lend their perks.
    var onChange: ((Bool) -> Void)?

    private var updates: Task<Void, Never>?
    private let forced: Bool
    private let key = "quiver.plus.active"

    init(forced: Bool? = nil) {
        self.forced = forced != nil
        if let forced { active = forced; return }
        active = UserDefaults.standard.bool(forKey: key)
        updates = Task { [weak self] in
            for await r in Transaction.updates {
                guard case .verified(let t) = r, Plus.ids.contains(t.productID) else { continue }
                await t.finish()
                await self?.refresh()
            }
        }
    }

    func start() {
        onChange?(active)
        guard !forced else { return }
        Task { await refresh() }
    }

    func product(_ id: String) -> Product? { products[id] }
    func price(_ id: String) -> String { products[id]?.displayPrice ?? (id == Plus.yearlyID ? "$14.99" : "$2.99") }

    /// What a year costs per month, for the yearly row.
    var yearlyPerMonth: String? {
        guard let y = products[Plus.yearlyID] else { return nil }
        return (y.price / 12).formatted(y.priceFormatStyle)
    }

    func loadProducts() async {
        guard !forced, products.isEmpty else { return }
        if let ps = try? await Product.products(for: Plus.ids) { for p in ps { products[p.id] = p } }
        if let y = products[Plus.yearlyID], let sub = y.subscription {
            trialEligible = await sub.isEligibleForIntroOffer
        }
    }

    func refresh() async {
        guard !forced else { return }
        await loadProducts()
        var on = false, cur: String? = nil, until: Date? = nil
        for await r in Transaction.currentEntitlements {
            guard case .verified(let t) = r, Plus.ids.contains(t.productID), t.revocationDate == nil else { continue }
            if let e = t.expirationDate, e < .now { continue }
            on = true; cur = t.productID; until = t.expirationDate
        }
        if let cur, let status = try? await products[cur]?.subscription?.status.first,
           case .verified(let info) = status.renewalInfo {
            willRenew = info.willAutoRenew
        }
        current = cur; renews = until
        set(on)
    }

    private func set(_ on: Bool) {
        let changed = on != active
        if changed { withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { active = on } }
        UserDefaults.standard.set(on, forKey: key)
        onChange?(on)
    }

    @discardableResult
    func buy(_ id: String) async -> Bool {
        guard !forced, !busy else { return false }
        busy = true; message = nil
        defer { busy = false }
        await loadProducts()
        guard let p = products[id] else { message = "The App Store did not answer. Check your connection and try again."; return false }
        do {
            switch try await p.purchase() {
            case .success(let r):
                guard case .verified(let t) = r else { message = "Apple could not confirm the purchase. Try Restore in a minute."; return false }
                await t.finish()
                await refresh()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                return active
            case .pending: message = "Waiting for approval. Plus turns on by itself once it is approved."
            case .userCancelled: break
            @unknown default: message = "Something unexpected happened. You were not charged."
            }
        } catch { message = "The purchase did not go through: \(error.localizedDescription)" }
        return false
    }

    func restore() async {
        guard !forced else { return }
        busy = true; defer { busy = false }
        do { try await AppStore.sync() } catch {
            if let e = error as? StoreKitError, case .userCancelled = e { return }
            message = "Could not reach the App Store. Check your connection and try again."; return
        }
        await refresh()
        message = active ? "Plus is on. Welcome back." : "No Quiver Plus subscription found on this Apple ID."
    }
}

// MARK: - The Plus page

struct PlusPaywall: View {
    @Environment(Plus.self) private var plus
    @Environment(Pro.self) private var pro
    @Environment(\.dismiss) private var dismiss
    @State private var pick = Plus.yearlyID
    @State private var manage = false
    @State private var redeem = false
    @State private var shown = false

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Eyebrow("Quiver Plus")
                            Text(plus.active ? "You're on Plus." : "The whole notebook, and more every month.")
                                .font(.hand(30, .bold)).foregroundStyle(Kraft.ink).fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Kraft.ink2)
                                .frame(width: 36, height: 36).overlay(Circle().strokeBorder(Kraft.ink.opacity(0.25)))
                        }.buttonStyle(.plain).accessibilityLabel("Close")
                    }.padding(.top, 20)

                    VStack(alignment: .leading, spacing: 13) {
                        row("checkmark.seal", "Everything in Pro", "Printed tape, every bow, the drop chart, score trends and CSV export.")
                        row("chart.bar.xaxis", "Insights", "Where your points go: tiring ends, consistency, group size over time, and how each distance is going.")
                        row("icloud", "iCloud backup", "Setups, marks and every round, backed up to your iCloud and back on a new iPhone.")
                        row("paintpalette", "Every ink", "All the notebook colours and their app icons, while you're subscribed.")
                        row("photo.artframe", "\(Plus.monthlyPosters) posters every month", "Fresh scorecard poster credits on the first of each month.")
                        row("flag.checkered", "A bonus challenge each month", "A harder second challenge on the Range page, new every month.")
                    }.sheet(tilt: -0.3)

                    if plus.active {
                        activeCard
                    } else {
                        VStack(spacing: 10) {
                            plan(Plus.yearlyID, "Yearly", plus.trialEligible ? "1 week free, then \(plus.price(Plus.yearlyID)) a year" : "\(plus.price(Plus.yearlyID)) a year",
                                 plus.yearlyPerMonth.map { "Works out at \($0) a month" })
                            plan(Plus.monthlyID, "Monthly", "\(plus.price(Plus.monthlyID)) a month", nil)
                        }
                        if let m = plus.message { Text(m).font(.note(13, .semibold)).foregroundStyle(Kraft.red).frame(maxWidth: .infinity).multilineTextAlignment(.center) }
                        InkButton(title: plus.busy ? "One moment" : buyTitle, icon: "sparkles", fill: Kraft.fletch) {
                            Task { await plus.buy(pick) }
                        }.disabled(plus.busy)
                        if pro.unlocked {
                            Text("You own Quiver Pro and keep it for good, whatever you decide here. Plus adds the rest on top.")
                                .font(.note(12, .semibold)).foregroundStyle(Kraft.fletchDeep).fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(terms).font(.note(11)).foregroundStyle(Kraft.ink3).fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 16) {
                            Link("Terms of Use", destination: Plus.terms)
                            Link("Privacy Policy", destination: Plus.privacy)
                        }.font(.note(12, .bold)).foregroundStyle(Kraft.ink)
                        HStack(spacing: 16) {
                            Button("Restore Purchases") { Task { await plus.restore(); await pro.restore() } }
                            Button("Manage subscription") { manage = true }
                            Button("Redeem code") { redeem = true }
                        }.font(.note(12, .bold)).foregroundStyle(Kraft.ink).buttonStyle(.plain)
                    }
                }
                .padding(.leading, 44).padding(.trailing, 18).padding(.bottom, 40)
            }
        }
        .manageSubscriptionsSheet(isPresented: $manage)
        .offerCodeRedemption(isPresented: $redeem) { _ in Task { await plus.refresh() } }
        .task { await plus.loadProducts() }
    }

    var buyTitle: String {
        pick == Plus.yearlyID && plus.trialEligible ? "Start the free week" : "Subscribe"
    }

    var terms: String {
        let trial = plus.trialEligible ? " The yearly plan starts with a 1 week free trial; if you don't cancel before it ends, the yearly price is charged." : ""
        return "Quiver Plus is an auto-renewable subscription: \(plus.price(Plus.monthlyID)) a month or \(plus.price(Plus.yearlyID)) a year.\(trial) Payment is charged to your Apple ID at confirmation of purchase. It renews automatically at the same price unless you turn off auto-renew at least 24 hours before the end of the current period; your account is charged for renewal within 24 hours before the period ends. Manage or cancel any time in Settings > your name > Subscriptions."
    }

    var activeCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(plus.current == Plus.yearlyID ? "Yearly plan" : "Monthly plan", systemImage: "checkmark.seal.fill").font(.hand(17, .bold)).foregroundStyle(Kraft.ink)
            if let r = plus.renews {
                Text(plus.willRenew ? "Renews \(r.formatted(date: .abbreviated, time: .omitted))." : "Ends \(r.formatted(date: .abbreviated, time: .omitted)). Auto-renew is off.")
                    .font(.note(13)).foregroundStyle(Kraft.ink2)
            }
        }.sheet(tilt: 0.3)
    }

    func plan(_ id: String, _ title: String, _ detail: String, _ note: String?) -> some View {
        let on = pick == id
        return Button { pick = id; UISelectionFeedbackGenerator().selectionChanged() } label: {
            HStack(spacing: 12) {
                Image(systemName: on ? "largecircle.fill.circle" : "circle").font(.system(size: 20, weight: .bold)).foregroundStyle(Kraft.ink)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title).font(.hand(18, .bold)).foregroundStyle(Kraft.ink)
                        if id == Plus.yearlyID {
                            Text("BEST VALUE").font(.note(9, .heavy)).tracking(1).foregroundStyle(Kraft.ink)
                                .padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Kraft.fletch))
                        }
                    }
                    Text(detail).font(.note(13, .semibold)).foregroundStyle(Kraft.ink2)
                    if let note { Text(note).font(.note(11)).foregroundStyle(Kraft.ink3) }
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Kraft.card).shadow(color: Kraft.ink.opacity(on ? 0.2 : 0.08), radius: on ? 8 : 3, y: 3))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(on ? Kraft.ink : Kraft.ink.opacity(0.12), lineWidth: on ? 2 : 1))
        }.buttonStyle(.plain)
    }

    func row(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 15, weight: .bold)).foregroundStyle(Kraft.ink)
                .frame(width: 34, height: 34).background(Circle().fill(Kraft.fletch))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.hand(17, .bold)).foregroundStyle(Kraft.ink)
                Text(body).font(.note(13)).foregroundStyle(Kraft.ink2).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// The Plus card on the Sight tape page: status, backup, and the way in.
struct PlusCard: View {
    @Environment(Plus.self) private var plus
    @Environment(Router.self) private var router
    @Environment(Store.self) private var store
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: plus.active ? "sparkles" : "sparkles").font(.system(size: 14, weight: .bold)).foregroundStyle(Kraft.ink)
                    .frame(width: 38, height: 38).background(Circle().fill(plus.active ? Kraft.fletch : Kraft.paper2))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quiver Plus").font(.hand(16, .bold)).foregroundStyle(Kraft.ink)
                    Text(plus.active ? "On. Insights, iCloud backup, every ink, \(Plus.monthlyPosters) posters a month." : "Insights, iCloud backup, every ink, monthly posters and everything in Pro.")
                        .font(.note(12)).foregroundStyle(Kraft.ink2).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Button { router.plus = true } label: {
                    Text(plus.active ? "MANAGE" : "SEE PLUS").font(.note(11, .heavy)).tracking(1.2).foregroundStyle(Kraft.card)
                        .padding(.horizontal, 12).padding(.vertical, 8).background(RoundedRectangle(cornerRadius: 6).fill(Kraft.ink))
                }.buttonStyle(.plain)
            }
            if plus.active { BackupRow() }
        }
        .sheet(padding: 14, tilt: 0.2)
    }
}
