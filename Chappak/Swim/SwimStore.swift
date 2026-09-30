import Foundation
import Observation
import UIKit

/// Owns all swim-session data and persists it locally:
/// session state as JSON, photos as JPEG files, both in Application Support.
@Observable
@MainActor
final class SwimStore {
    private(set) var sessions: [SwimSession]

    private let directory: URL
    private var dataURL: URL { directory.appendingPathComponent("swim-sessions.json") }
    private var photosURL: URL { directory.appendingPathComponent("SwimPhotos", isDirectory: true) }

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Swim", isDirectory: true)
        self.directory = base
        self.sessions = (1...SwimSession.totalCount).map { SwimSession(number: $0) }
        try? FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)
        load()
    }

    var completedCount: Int { sessions.filter(\.isCompleted).count }

    func session(_ number: Int) -> SwimSession {
        sessions[number - 1]
    }

    func toggleCompleted(_ number: Int) {
        sessions[number - 1].isCompleted.toggle()
        save()
    }

    func setNotes(_ notes: String, for number: Int) {
        guard sessions[number - 1].notes != notes else { return }
        sessions[number - 1].notes = notes
        save()
    }

    func addPhoto(_ data: Data, to number: Int) {
        guard let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.85) else { return }
        let name = UUID().uuidString + ".jpg"
        do {
            try jpeg.write(to: photoURL(name), options: .atomic)
        } catch {
            return
        }
        sessions[number - 1].photoFilenames.append(name)
        save()
    }

    func removePhoto(_ name: String, from number: Int) {
        sessions[number - 1].photoFilenames.removeAll { $0 == name }
        try? FileManager.default.removeItem(at: photoURL(name))
        save()
    }

    func photoURL(_ name: String) -> URL {
        photosURL.appendingPathComponent(name)
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: dataURL),
              let saved = try? JSONDecoder().decode([SwimSession].self, from: data) else { return }
        for item in saved where (1...SwimSession.totalCount).contains(item.number) {
            sessions[item.number - 1] = item
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: dataURL, options: .atomic)
    }
}

extension SwimStore {
    /// In-memory-ish store for previews.
    static var preview: SwimStore {
        let store = SwimStore(directory: FileManager.default.temporaryDirectory
            .appendingPathComponent("SwimPreview", isDirectory: true))
        for n in 1...7 where !store.session(n).isCompleted { store.toggleCompleted(n) }
        return store
    }
}
