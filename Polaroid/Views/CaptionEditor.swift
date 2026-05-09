import SwiftUI

struct CaptionEditor: View {
    @Bindable var model: PolaroidDocumentModel
    @FocusState private var isFocused: Bool
    @State private var isEditing = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let captionRect = CGRect(
                x: width * 0.19,
                y: height * 0.78,
                width: width * 0.62,
                height: height * 0.10
            )

            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isEditing = false
                        isFocused = false
                    }

                if isEditing {
                    TextField("", text: Binding(
                        get: { model.caption },
                        set: { model.caption = String($0.prefix(60)).replacingOccurrences(of: "\n", with: " ") }
                    ))
                    .font(.custom(model.style.handwritingFont.displayName, size: max(18, width * 0.042)))
                    .foregroundStyle(Color(nsColor: model.style.inkColor.nsColor))
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .frame(width: captionRect.width, height: captionRect.height)
                    .position(x: captionRect.midX, y: captionRect.midY)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.30))
                            .frame(width: captionRect.width + 18, height: captionRect.height + 12)
                            .position(x: captionRect.midX, y: captionRect.midY)
                    }
                    .onSubmit {
                        isEditing = false
                        isFocused = false
                    }
                    .onExitCommand {
                        isEditing = false
                        isFocused = false
                    }
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: captionRect.width, height: captionRect.height)
                        .position(x: captionRect.midX, y: captionRect.midY)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isEditing = true
                            isFocused = true
                        }
                }
            }
        }
    }
}
