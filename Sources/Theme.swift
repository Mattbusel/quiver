import SwiftUI

/// A field notebook: kraft paper, ruled lines, forest-green ink, one chartreuse fletching.
enum Kraft {
    static let paper = Color(red: 0.851, green: 0.780, blue: 0.627)      // #D9C7A0
    static let paper2 = Color(red: 0.902, green: 0.843, blue: 0.702)
    static let card = Color(red: 0.965, green: 0.937, blue: 0.867)       // a lighter sheet
    static let ink = Color(red: 0.122, green: 0.239, blue: 0.169)        // #1F3D2B
    static let ink2 = Color(red: 0.122, green: 0.239, blue: 0.169).opacity(0.68)
    static let ink3 = Color(red: 0.122, green: 0.239, blue: 0.169).opacity(0.42)
    static let rule = Color(red: 0.122, green: 0.239, blue: 0.169).opacity(0.14)
    static let fletch = Color(red: 0.62, green: 0.86, blue: 0.14)        // chartreuse
    static let fletchDeep = Color(red: 0.42, green: 0.62, blue: 0.06)
    static let red = Color(red: 0.72, green: 0.22, blue: 0.16)
    static let amber = Color(red: 0.78, green: 0.52, blue: 0.10)
}

extension Font {
    static func hand(_ size: CGFloat, _ w: Font.Weight = .bold) -> Font { .system(size: size, weight: w, design: .serif) }
    static func note(_ size: CGFloat, _ w: Font.Weight = .medium) -> Font { .system(size: size, weight: w, design: .default) }
    static func fig(_ size: CGFloat, _ w: Font.Weight = .bold) -> Font { .system(size: size, weight: w, design: .serif).monospacedDigit() }
    static func mono(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .monospaced) }
}

/// Kraft paper with a ruled grid and a red margin line.
struct PaperBackground: View {
    var body: some View {
        ZStack {
            Kraft.paper
            RadialGradient(colors: [Kraft.paper2.opacity(0.9), .clear], center: .init(x: 0.3, y: 0.1), startRadius: 20, endRadius: 500)
            Canvas { ctx, size in
                var y: CGFloat = 0
                while y < size.height {
                    var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(p, with: .color(Kraft.rule), lineWidth: 0.7)
                    y += 28
                }
                var m = Path(); m.move(to: CGPoint(x: 34, y: 0)); m.addLine(to: CGPoint(x: 34, y: size.height))
                ctx.stroke(m, with: .color(Kraft.red.opacity(0.35)), lineWidth: 1)
                // Paper fibres.
                var seed: UInt64 = 0xA5A5A5A5DEADBEEF
                for _ in 0..<700 {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    let x = CGFloat(seed >> 33 % 10000) / 10000 * size.width
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    let yy = CGFloat(seed >> 33 % 10000) / 10000 * size.height
                    ctx.fill(Path(CGRect(x: x, y: yy, width: 1.5, height: 1)), with: .color(Kraft.ink.opacity(0.06)))
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct Eyebrow: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View { Text(text.uppercased()).font(.note(11, .heavy)).tracking(2).foregroundStyle(Kraft.ink3) }
}

extension View {
    /// A lighter sheet taped onto the page.
    func sheet(padding: CGFloat = 16, tilt: Double = 0) -> some View {
        self.padding(padding)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Kraft.card).shadow(color: Kraft.ink.opacity(0.18), radius: 10, y: 5))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Kraft.ink.opacity(0.12)))
            .overlay(alignment: .top) { TapeStrip().offset(y: -8) }
            .rotationEffect(.degrees(tilt))
    }
}

struct TapeStrip: View {
    var body: some View {
        Rectangle().fill(Color.white.opacity(0.45)).frame(width: 64, height: 16)
            .overlay(Rectangle().strokeBorder(Color.white.opacity(0.6), lineWidth: 0.5))
            .rotationEffect(.degrees(-2))
    }
}

/// A stat inked into the notebook.
struct InkStat: View {
    let value: String
    let unit: String
    let label: String
    var color: Color = Kraft.ink
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value).font(.fig(28)).foregroundStyle(color)
                Text(unit).font(.note(12, .bold)).foregroundStyle(Kraft.ink3)
            }
            Text(label.uppercased()).font(.note(10, .heavy)).tracking(1.2).foregroundStyle(Kraft.ink3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InkButton: View {
    let title: String
    var icon: String? = nil
    var fill: Color = Kraft.ink
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 14, weight: .bold)) }
                Text(title).font(.hand(16, .bold))
            }
            .foregroundStyle(fill == Kraft.fletch ? Kraft.ink : Kraft.card)
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(fill).shadow(color: Kraft.ink.opacity(0.25), radius: 8, y: 4))
        }.buttonStyle(.plain)
    }
}

struct Field: View {
    let label: String
    var hint: String = ""
    @Binding var value: Double
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.note(14, .semibold)).foregroundStyle(Kraft.ink)
                if !hint.isEmpty { Text(hint).font(.note(11)).foregroundStyle(Kraft.ink3) }
            }
            Spacer()
            TextField("", value: $value, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                .font(.fig(17)).foregroundStyle(Kraft.ink).frame(width: 88, height: 34)
                .overlay(alignment: .bottom) { Rectangle().fill(Kraft.ink.opacity(0.35)).frame(height: 1) }
        }
        .padding(.vertical, 5)
    }
}

struct NotebookTabBar: View {
    @Binding var selection: Tab
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button { withAnimation(.snappy(duration: 0.25)) { selection = t } } label: {
                    VStack(spacing: 4) {
                        Image(systemName: t.icon).font(.system(size: 17, weight: .bold))
                        Text(t.rawValue).font(.hand(12, .bold))
                    }
                    .foregroundStyle(selection == t ? Kraft.card : Kraft.ink2)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(selection == t ? Kraft.ink : Kraft.card.opacity(0.7)))
                }.buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Kraft.paper2).shadow(color: Kraft.ink.opacity(0.25), radius: 16, y: 8))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Kraft.ink.opacity(0.15)))
        .padding(.horizontal, 16)
    }
}
