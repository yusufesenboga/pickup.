import PickupCore
import SwiftUI

struct HistoryView: View {
    @Bindable var model: AppModel
    @State private var dayToDelete: Date?

    private var days: [Date] {
        Set(model.sessions.map { Calendar.current.startOfDay(for: $0.startedAt) }).sorted(by: >)
    }

    private func sessions(on day: Date) -> [SessionRecord] {
        model.sessions.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: day) }
    }

    var body: some View {
        List {
            if days.isEmpty {
                ContentUnavailableView("A fresh start", systemImage: "clock.arrow.circlepath",
                    description: Text("Every session stays here until you delete it, including short ones."))
                    .listRowBackground(Color.clear)
            }
            ForEach(days, id: \.self) { day in
                Section {
                    ForEach(sessions(on: day)) { session in
                        NavigationLink(value: session.id) { SessionRow(session: session) }
                    }
                    .onDelete { offsets in
                        let rows = sessions(on: day)
                        let ids = Set(offsets.map { rows[$0].id })
                        Task { await model.delete(ids: ids) }
                    }
                } header: {
                    HStack {
                        Text(day, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                        Spacer()
                        Menu {
                            Button("Clear all for this day", role: .destructive) { dayToDelete = day }
                        } label: {
                            Image(systemName: "ellipsis.circle").padding(8)
                        }.accessibilityLabel("Day actions")
                    }
                }.listRowBackground(Theme.card)
            }
        }
        .scrollContentBackground(.hidden).background(Theme.background)
        .navigationTitle("History")
        .confirmationDialog("Delete this day's sessions?", isPresented: Binding(
            get: { dayToDelete != nil }, set: { if !$0 { dayToDelete = nil } }), titleVisibility: .visible) {
                Button("Delete sessions", role: .destructive) {
                    if let day = dayToDelete {
                        let ids = Set(sessions(on: day).map(\.id))
                        Task { await model.delete(ids: ids) }
                    }
                    dayToDelete = nil
                }
            } message: { Text("This cannot be undone. A session crossing midnight belongs to the day it started.") }
    }
}
