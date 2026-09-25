import Foundation

struct ExportItem: Identifiable {
    let url: URL
    var id: URL { url }
}
