import SwiftUI

struct SetupStepCard<Content: View>: View {
    let number: Int
    let title: String
    let subtitle: String
    let complete: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(complete ? Color.accentColor.opacity(0.2) : Theme.background)
                    if complete { Image(systemName: "checkmark").foregroundStyle(.tint) }
                    else { Text(number, format: .number).font(.subheadline.weight(.bold)) }
                }.frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(Theme.secondary)
                }
            }
            if let screenshot = UIImage(named: SetupConstants.screenshotNames[number - 1]) {
                Image(uiImage: screenshot).resizable().scaledToFit().frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .accessibilityLabel(title)
            }
            content
        }.frame(maxWidth: .infinity, alignment: .leading)
            .padding(20).background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
    }
}
