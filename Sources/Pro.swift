import SwiftUI
import StoreKit

/// Quiver Pro: one non-consumable. The arrow sheet, the bow page and the fitted marks are free
/// forever; Pro adds more setups, the true-size printable tape and the drop and drift chart.
///
/// Everyone who installed a build from before Pro existed keeps everything: they paid for it.
/// AppTransaction's originalAppVersion is the build number they first installed. Only trusted in
/// production: sandbox and Xcode report made-up values, and App Review must see the real paywall.
@MainActor
@Observable
final class Pro {
    static let productID = "com.mattbusel.quiver.pro"
    /// The first build with Pro in it. Anything earlier was the paid app with every feature.
    static let firstFreemiumBuild = 2

    enum Reason: String, Identifiable { case setups, print, drop, settings; var id: String { rawValue } }

    private(set) var unlocked: Bool
    private(set) var grandfathered = false
    private(set) var product: Product?
    var busy = false
    var message: String?
    var paywall: Reason? = nil

    private var updates: Task<Void, Never>?
    private let key = "quiver.pro.unlocked"
    private let forced: Bool

    /// `forced` is for screenshots and the review recording, which must not touch StoreKit.
    init(forced: Bool? = nil) {
        self.forced = forced != nil
        if let forced { unlocked = forced; return }
        unlocked = UserDefaults.standard.bool(forKey: key)
        updates = Task { [weak self] in
            for await result in Transaction.updates { await self?.apply(result) }
        }
        Task { await refresh() }
    }

    var price: String { product?.displayPrice ?? "$3.99" }

    func ask(_ why: Reason) { if !unlocked { paywall = why } }

    func refresh() async {
        guard !forced else { return }
        if product == nil { product = try? await Product.products(for: [Pro.productID]).first }
        for await result in Transaction.currentEntitlements { await apply(result) }
        if case .verified(let app)? = try? await AppTransaction.shared,
           app.environment == .production, (Int(app.originalAppVersion) ?? Int.max) < Pro.firstFreemiumBuild {
            grandfathered = true
            grant()
        }
    }

    func buy() async {
        guard !forced, !busy else { return }
        busy = true; message = nil
        defer { busy = false }
        if product == nil { product = try? await Product.products(for: [Pro.productID]).first }
        guard let product else {
            message = "The App Store did not answer. Check your connection and try again."
            return
        }
        do {
            switch try await product.purchase() {
            case .success(let result):
                await apply(result)
                if !unlocked { message = "Apple could not confirm the purchase. Try Restore in a minute." }
            case .pending:
                message = "Waiting for approval. Pro unlocks by itself once it is approved."
            case .userCancelled:
                break
            @unknown default:
                message = "Something unexpected happened. You were not charged."
            }
        } catch {
            message = "The purchase did not go through: \(error.localizedDescription)"
        }
    }

    func restore() async {
        guard !forced, !busy else { return }
        busy = true; message = nil
        defer { busy = false }
        do { try await AppStore.sync() } catch {
            if let e = error as? StoreKitError, case .userCancelled = e { return }
            message = "Could not reach the App Store. Check your connection and try again."
            return
        }
        await refresh()
        message = unlocked ? "Pro is unlocked. Welcome back." : "No Pro purchase found on this Apple ID."
    }

    private func apply(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let t) = result, t.productID == Pro.productID else { return }
        if t.revocationDate == nil { grant() } else if !grandfathered { revoke() }
        await t.finish()
    }

    private func grant() {
        guard !unlocked else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { unlocked = true }
        paywall = nil
        UserDefaults.standard.set(true, forKey: key)
    }

    private func revoke() {
        unlocked = false
        UserDefaults.standard.set(false, forKey: key)
    }
}

// MARK: - Paywall

/// A page torn from the back of the notebook: what Pro adds, one price, restore in reach.
struct PaywallView: View {
    @Environment(Pro.self) private var pro
    @Environment(\.dismiss) private var dismiss
    let reason: Pro.Reason
    @State private var shown = false

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Eyebrow("Quiver Pro")
                            Text(headline).font(.hand(32, .bold)).foregroundStyle(Kraft.ink).fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Kraft.ink2)
                                .frame(width: 36, height: 36).overlay(Circle().strokeBorder(Kraft.ink.opacity(0.25)))
                        }.buttonStyle(.plain).accessibilityLabel("Close")
                    }
                    .padding(.top, 20)

                    TapeTeaser(shown: shown)

                    VStack(alignment: .leading, spacing: 14) {
                        feature("printer", "The tape, printed", "True size on paper: a PDF that prints 1:1 with a 10 mm check bar. Cut it, stick it on the sight.")
                        feature("square.stack.3d.up", "Every bow you own", "Separate setups for the hunting rig, the 3D bow and the spare: arrow, bow and tape each.")
                        feature("wind", "Drop and drift chart", "Time of flight, drop from a 20 yard zero and 10 mph crosswind drift, 10 to 80 yards.")
                    }
                    .sheet(tilt: -0.3)

                    HStack(alignment: .center, spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pro.price).font(.fig(36)).foregroundStyle(Kraft.ink)
                            Text("ONCE, NOT A SEASON").font(.note(10, .heavy)).tracking(1.6).foregroundStyle(Kraft.fletchDeep)
                        }
                        Spacer()
                        Text("No\nsubscription").font(.hand(13, .bold)).multilineTextAlignment(.trailing).foregroundStyle(Kraft.red)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Kraft.red.opacity(0.7), style: StrokeStyle(lineWidth: 1.4, dash: [4, 3])))
                            .rotationEffect(.degrees(4))
                    }
                    .sheet(tilt: 0.4)

                    if let m = pro.message {
                        Text(m).font(.note(13, .semibold)).foregroundStyle(Kraft.red).frame(maxWidth: .infinity).multilineTextAlignment(.center)
                    }
                    InkButton(title: pro.busy ? "One moment" : "Unlock Pro for \(pro.price)", icon: "lock.open", fill: Kraft.fletch) {
                        Task { await pro.buy() }
                    }
                    .disabled(pro.busy)
                    HStack {
                        Button { Task { await pro.restore() } } label: {
                            Label("Restore purchase", systemImage: "arrow.clockwise").font(.note(14, .bold)).foregroundStyle(Kraft.ink)
                        }.buttonStyle(.plain)
                        Spacer()
                        Button("Not now") { dismiss() }.font(.note(14, .bold)).foregroundStyle(Kraft.ink2)
                    }
                    Text("One payment, yours for good. Family Sharing works. The arrow sheet, bow page and fitted marks stay free, and nothing you have entered is ever locked.")
                        .font(.note(11.5)).foregroundStyle(Kraft.ink3).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 44).padding(.trailing, 18).padding(.bottom, 40)
            }
        }
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.15)) { shown = true } }
        .onChange(of: pro.unlocked) { _, now in if now { dismiss() } }
    }

    var headline: String {
        switch reason {
        case .setups: return "One notebook, every bow."
        case .drop: return "Know where it lands."
        default: return "Print the tape. Stick it on."
        }
    }

    func feature(_ icon: String, _ title: String, _ body: String) -> some View {
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

/// A strip of sight tape with a fletching-green "PRO" tag pinned beside it.
private struct TapeTeaser: View {
    let shown: Bool
    var body: some View {
        HStack(spacing: 0) {
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                var y: CGFloat = 10
                var d = 20
                while y < size.height - 6 {
                    let major = d % 10 == 0
                    let w: CGFloat = size.width * (major ? 0.6 : 0.3)
                    var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y))
                    ctx.stroke(p, with: .color(.black), lineWidth: major ? 1.2 : 0.6)
                    if major { ctx.draw(Text("\(d)").font(.system(size: 11, weight: .bold)).foregroundStyle(.black), at: CGPoint(x: size.width - 6, y: y), anchor: .trailing) }
                    let step: CGFloat = 7 + CGFloat(d - 20) * 0.12
                    y += step
                    d += 5
                }
            }
            .frame(width: 58, height: 170)
            .overlay(Rectangle().strokeBorder(Color.gray.opacity(0.5), lineWidth: 0.5))
            .rotationEffect(.degrees(-3))
            .shadow(color: Kraft.ink.opacity(0.2), radius: 6, y: 3)
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("1 : 1").font(.fig(44)).foregroundStyle(Kraft.ink)
                Text("printed at true size").font(.note(12, .semibold)).foregroundStyle(Kraft.ink2)
                Text("PRO").font(.hand(15, .heavy)).tracking(2).foregroundStyle(Kraft.ink)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Kraft.fletch))
                    .rotationEffect(.degrees(shown ? -6 : -40)).scaleEffect(shown ? 1 : 0.4)
                    .padding(.top, 6)
            }
        }
        .sheet(tilt: 0.5)
    }
}

/// A Pro block for a free user: the real content underneath, frosted, with a way in.
struct LockedBlock<Content: View>: View {
    @Environment(Pro.self) private var pro
    let reason: Pro.Reason
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            content.blur(radius: 6).allowsHitTesting(false).accessibilityHidden(true)
            VStack(spacing: 10) {
                Image(systemName: "lock.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(Kraft.ink)
                    .frame(width: 44, height: 44).background(Circle().fill(Kraft.fletch))
                Text(title).font(.hand(18, .bold)).foregroundStyle(Kraft.ink).multilineTextAlignment(.center)
                Button { pro.ask(reason) } label: {
                    Text("See Quiver Pro, \(pro.price) once").font(.note(13, .bold)).foregroundStyle(Kraft.card)
                        .padding(.horizontal, 16).padding(.vertical, 10).background(Capsule().fill(Kraft.ink))
                }.buttonStyle(.plain)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 10).fill(Kraft.card.opacity(0.92)))
        }
    }
}

/// Pro status with Restore always in reach, at the foot of the Sight tape page.
struct ProCard: View {
    @Environment(Pro.self) private var pro
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: pro.unlocked ? "checkmark" : "lock.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Kraft.ink)
                .frame(width: 38, height: 38).background(Circle().fill(pro.unlocked ? Kraft.fletch : Kraft.paper2))
            VStack(alignment: .leading, spacing: 2) {
                Text(pro.unlocked ? "Quiver Pro" : "Quiver Pro, \(pro.price) once").font(.hand(16, .bold)).foregroundStyle(Kraft.ink)
                Text(pro.unlocked ? (pro.grandfathered ? "Unlocked. Thanks for buying Quiver early." : "Unlocked. Thank you.") : "Printed tape, more setups, drop chart.")
                    .font(.note(12)).foregroundStyle(Kraft.ink2)
                if let m = pro.message, pro.paywall == nil { Text(m).font(.note(11.5, .semibold)).foregroundStyle(Kraft.red) }
            }
            Spacer(minLength: 4)
            if !pro.unlocked {
                VStack(alignment: .trailing, spacing: 8) {
                    Button { pro.ask(.settings) } label: {
                        Text("SEE").font(.note(12, .heavy)).tracking(1.4).foregroundStyle(Kraft.card)
                            .padding(.horizontal, 14).padding(.vertical, 8).background(RoundedRectangle(cornerRadius: 6).fill(Kraft.ink))
                    }.buttonStyle(.plain)
                    Button { Task { await pro.restore() } } label: {
                        Text("Restore").font(.note(11, .bold)).foregroundStyle(Kraft.ink2).underline()
                    }.buttonStyle(.plain)
                }
            }
        }
        .sheet(padding: 14)
    }
}
