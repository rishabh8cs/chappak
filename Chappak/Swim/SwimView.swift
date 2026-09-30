import SwiftUI

struct SwimView: View {
    @Environment(SwimStore.self) private var store

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)
    private let weekdaySymbols = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    progressHeader
                    grid
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Swim")
            .navigationDestination(for: Int.self) { number in
                SessionDetailView(number: number)
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(store.completedCount) of \(SwimSession.totalCount) classes done")
                .font(.headline)
            ProgressView(value: Double(store.completedCount), total: Double(SwimSession.totalCount))
                .tint(.blue)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var grid: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(weekdaySymbols.indices, id: \.self) { i in
                    Text(weekdaySymbols[i])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.sessions) { session in
                    NavigationLink(value: session.number) {
                        SessionCell(session: session)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            store.toggleCompleted(session.number)
                        } label: {
                            Label(session.isCompleted ? "Mark Incomplete" : "Mark Completed",
                                  systemImage: session.isCompleted ? "xmark.circle" : "checkmark.circle")
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct SessionCell: View {
    let session: SwimSession

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(session.isCompleted ? Color.blue.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(session.isCompleted ? Color.blue : .clear, lineWidth: 1.5)

            Text("\(session.number)")
                .font(.body.weight(.medium))
                .foregroundStyle(session.isCompleted ? Color.blue.opacity(0.6) : .primary)

            if session.isCompleted {
                Image(systemName: "xmark")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.blue)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(alignment: .topTrailing) {
            if !session.notes.isEmpty || !session.photoFilenames.isEmpty {
                Circle().fill(.orange).frame(width: 6, height: 6).padding(5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Session \(session.number), \(session.isCompleted ? "completed" : "not completed")")
    }
}

#Preview {
    SwimView().environment(SwimStore.preview)
}
