// TODO: Widget implementation - placeholder for build
// This file is a stub to satisfy the build system
// Real widget implementation should be added later

import SwiftUI
import WidgetKit

@main
struct ZenBoundWidgetBundle: WidgetBundle {
    var body: some Widget {
        ZenBoundWidget()
    }
}

struct ZenBoundWidget: Widget {
    let kind: String = "ZenBoundWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleProvider()) { entry in
            ZenBoundWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ZenBound")
        .description("Track your focus sessions")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct SimpleProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct ZenBoundWidgetEntryView: View {
    var entry: SimpleEntry
    
    var body: some View {
        VStack {
            Image(systemName: "timer")
                .font(.largeTitle)
            Text("ZenBound")
                .font(.caption)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
