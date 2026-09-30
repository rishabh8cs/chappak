import Foundation

/// One swim class. Photos are stored on disk; only their filenames live here.
struct SwimSession: Identifiable, Codable, Equatable {
    static let totalCount = 30

    let number: Int
    var isCompleted = false
    var notes = ""
    var photoFilenames: [String] = []

    var id: Int { number }
}
