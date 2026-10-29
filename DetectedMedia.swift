import Foundation
struct DetectedMedia: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let url: URL
    let kind: String
    let isLive: Bool
}
