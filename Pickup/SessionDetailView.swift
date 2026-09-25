import PickupCore
import SwiftUI

struct SessionDetailView: View {
    @Bindable var model: AppModel
    let sessionID: UUID

    var body: some View {
        ScrollView {
            if let session = model.sessions.first(where: { $0.id == sessionID }) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(session.startedAt, format: .dateTime.weekday(.wide).month(.wide).day())
                            .foregroundStyle(Theme.secondary)
                        if session.status == .active {
                            Text(session.startedAt, style: .timer)
                                .font(.system(size: 48, weight: .medium, design: .rounded)).monospacedDigit()
                        } else {
                            Text(L10n.duration(session.duration(at: .now)))
                                .font(.system(size: 48, weight: .medium, design: .rounded))
                        }
                        Divider()
                        LabeledContent("Started") { Text(session.startedAt, style: .time) }
                        LabeledContent("Ended") {
                            if let end = session.effectiveEnd { Text(end, style: .time) }
                            else { Text("Still going").foregroundStyle(.tint) }
                        }
                        if session.status == .pendingEnd {
                            Text("Closed. Reopening a tracked app within the grace period resumes this session.")
                                .font(.caption).foregroundStyle(Theme.secondary)
                        }
                    }.padding(20).background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
                    ReportHostView(model: model, kind: .session(session))
                        .padding(20).background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
                }.padding(20)
            } else {
                ContentUnavailableView("Session unavailable", systemImage: "clock.badge.questionmark",
                    description: Text("This session may have been deleted."))
            }
        }.background(Theme.background).navigationTitle("Session").navigationBarTitleDisplayMode(.inline)
    }
}
