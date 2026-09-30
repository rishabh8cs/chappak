import PhotosUI
import SwiftUI

struct SessionDetailView: View {
    @Environment(SwimStore.self) private var store
    let number: Int

    @State private var notes = ""
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var selectedPhoto: String?
    @FocusState private var notesFocused: Bool

    private var session: SwimSession { store.session(number) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                completionButton
                notesSection
                photosSection
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Session \(number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { notesFocused = false }
            }
        }
        .onAppear { notes = session.notes }
        .onChange(of: notes) { _, new in store.setNotes(new, for: number) }
        .onChange(of: pickerItems) { _, items in importPhotos(items) }
        .fullScreenCover(item: $selectedPhoto) { name in
            PhotoViewer(url: store.photoURL(name))
        }
    }

    private var completionButton: some View {
        Button {
            withAnimation(.snappy) { store.toggleCompleted(number) }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            Label(session.isCompleted ? "Completed" : "Mark as Completed",
                  systemImage: session.isCompleted ? "xmark.square.fill" : "square")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(session.isCompleted ? .blue : .gray)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes").font(.headline)
            TextEditor(text: $notes)
                .focused($notesFocused)
                .frame(minHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("How did the class go?")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Photos").font(.headline)
                Spacer()
                PhotosPicker(selection: $pickerItems, matching: .images) {
                    Label("Add", systemImage: "photo.badge.plus")
                }
            }
            if session.photoFilenames.isEmpty {
                Text("No photos yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(session.photoFilenames, id: \.self) { name in
                        PhotoThumbnail(url: store.photoURL(name))
                            .onTapGesture { selectedPhoto = name }
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation { store.removePhoto(name, from: number) }
                                } label: {
                                    Label("Delete Photo", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    private func importPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        pickerItems = []
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    store.addPhoto(data, to: number)
                }
            }
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

private struct PhotoThumbnail: View {
    let url: URL

    var body: some View {
        Color(.tertiarySystemGroupedBackground)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct PhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .white.opacity(0.3))
                    .padding()
            }
        }
    }
}
