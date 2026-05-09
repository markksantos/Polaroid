import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Bindable var model: PolaroidDocumentModel
    @State private var isTargeted = false

    var body: some View {
        Button {
            model.openImagePanel()
        } label: {
            VStack(spacing: 22) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .frame(width: 154, height: 188)
                        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
                        .rotationEffect(.degrees(-4))

                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 46, weight: .regular))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(-4))
                }

                VStack(spacing: 7) {
                    Text("Drop an image")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                    Text("or click to choose one")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isTargeted ? Color.accentColor : Color.secondary.opacity(0.28),
                        style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [8, 7])
                    )
                    .padding(32)
            }
        }
        .buttonStyle(.plain)
        .onDrop(of: [UTType.image.identifier], isTargeted: $isTargeted) { providers in
            model.loadDroppedProviders(providers)
        }
        .padding(28)
    }
}
