import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct QuiverWidgets: WidgetBundle {
    var body: some Widget {
        SightMarkWidget()
        LockMarkWidget()
        TapeWidget()
        LastRoundWidget()
        RoundLiveActivity()
        if #available(iOSApplicationExtension 18.0, *) {
            StartRoundControl()
        }
    }
}

struct GlanceEntry: TimelineEntry {
    let date: Date
    let g: Glance
}

struct GlanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> GlanceEntry { GlanceEntry(date: .now, g: .sample) }
    func getSnapshot(in context: Context, completion: @escaping (GlanceEntry) -> Void) {
        let g = Glance.load()
        completion(GlanceEntry(date: .now, g: context.isPreview && !g.hasTape ? .sample : g))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<GlanceEntry>) -> Void) {
        // The app reloads every timeline when the notebook changes; nothing here goes stale on its own.
        completion(Timeline(entries: [GlanceEntry(date: .now, g: Glance.load())], policy: .never))
    }
}

/// Free: one distance and its mark, walked with +5 / -5. Home Screen and StandBy.
struct SightMarkWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "sightmark", provider: GlanceProvider()) { e in
            SightMarkGlanceView(g: e.g).containerBackground(for: .widget) { PaperFill() }
                .widgetURL(URL(string: "quiver://tape"))
        }
        .configurationDisplayName("Sight Mark")
        .description("Your mark for any distance. Tap plus or minus to walk it back.")
        .supportedFamilies([.systemSmall])
    }
}

/// Free: the mark on the Lock Screen.
struct LockMarkWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "lockmark", provider: GlanceProvider()) { e in
            LockFamilyView(g: e.g).containerBackground(for: .widget) { Color.clear }
                .widgetURL(URL(string: "quiver://tape"))
        }
        .configurationDisplayName("Sight Mark")
        .description("Your sight mark on the Lock Screen. Pick the distance on the Home Screen widget.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct LockFamilyView: View {
    @Environment(\.widgetFamily) private var family
    let g: Glance
    var body: some View {
        switch family {
        case .accessoryCircular: LockCircleView(g: g)
        case .accessoryInline:
            if let i = g.selected { Text("\(fmt(g.distances[i], 0)) \(g.unitWord): \(fmt(g.readings[i], 2))") } else { Text("Quiver: add sight marks") }
        default: LockMarkView(g: g)
        }
    }
}

/// Pro or Plus: the whole tape, every ten.
struct TapeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "tape", provider: GlanceProvider()) { e in
            Group {
                if e.g.unlocked { TapeGlanceView(g: e.g) } else { LockedTapeView(g: e.g) }
            }
            .containerBackground(for: .widget) { PaperFill() }
            .widgetURL(URL(string: "quiver://tape"))
        }
        .configurationDisplayName("Sight Tape")
        .description("Every mark on your tape at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

struct LockedTapeView: View {
    let g: Glance
    var body: some View {
        let ink = Color(hex: g.ink)
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "lock.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(ink)
            Text("The full tape widget comes with Quiver Pro or Plus.").font(.system(size: 14, weight: .bold, design: .serif)).foregroundStyle(ink)
            Text("The Sight Mark widget is included for everyone.").font(.system(size: 12)).foregroundStyle(ink.opacity(0.7))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Free: the last round and its trend.
struct LastRoundWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "lastround", provider: GlanceProvider()) { e in
            LastRoundGlanceView(g: e.g).containerBackground(for: .widget) { PaperFill() }
                .widgetURL(URL(string: "quiver://range"))
        }
        .configurationDisplayName("Last Round")
        .description("Your last score and how the last few rounds went.")
        .supportedFamilies([.systemSmall])
    }
}

/// The round in progress, on the Lock Screen and in the Dynamic Island.
struct RoundLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoundActivity.self) { ctx in
            RoundLiveView(a: ctx.attributes, s: ctx.state)
                .activityBackgroundTint(Paper.paper)
                .activitySystemActionForegroundColor(Color(hex: ctx.attributes.ink))
        } dynamicIsland: { ctx in
            let fletch = Color(hex: ctx.attributes.fletch)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(ctx.state.ends.map { "End \(min(ctx.state.end, $0))/\($0)" } ?? "End \(ctx.state.end)").font(.system(size: 17, weight: .bold, design: .serif))
                        Text(ctx.attributes.distance).font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(ctx.state.total)").font(.system(size: 30, weight: .bold, design: .serif)).monospacedDigit().foregroundStyle(fletch)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Text(ctx.attributes.round).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary).lineLimit(1)
                        Spacer()
                        Text(ctx.state.current.isEmpty ? "New end" : ctx.state.current.joined(separator: "  ")).font(.system(size: 14, weight: .heavy, design: .monospaced))
                    }
                }
            } compactLeading: {
                Image(systemName: "target").foregroundStyle(fletch)
            } compactTrailing: {
                Text("\(ctx.state.total)").font(.system(size: 14, weight: .bold)).monospacedDigit().foregroundStyle(fletch)
            } minimal: {
                Text("\(ctx.state.total)").font(.system(size: 12, weight: .bold)).monospacedDigit().foregroundStyle(fletch)
            }
        }
    }
}

/// Control Center, Lock Screen and Action button: open straight onto a new round.
@available(iOSApplicationExtension 18.0, *)
struct StartRoundControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.mattbusel.quiver.round") {
            ControlWidgetButton(action: StartRoundIntent()) {
                Label("Shoot a Round", systemImage: "target")
            }
        }
        .displayName("Shoot a Round")
        .description("Opens Quiver's score book on a new round.")
    }
}
