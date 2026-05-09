import SwiftUI

struct StylePickerView: View {
    @Bindable var model: PolaroidDocumentModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Paper", selection: $model.style.paperTexture) {
                ForEach(PaperTexture.allCases) { texture in
                    Label(texture.displayName, systemImage: icon(for: texture))
                        .tag(texture)
                }
            }
            .pickerStyle(.radioGroup)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Ink")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(34), spacing: 9), count: 6), spacing: 9) {
                    ForEach(InkColor.allCases) { ink in
                        Button {
                            model.style.inkColor = ink
                        } label: {
                            Circle()
                                .fill(Color(nsColor: ink.nsColor))
                                .overlay {
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(model.style.inkColor == ink ? 0.75 : 0.18), lineWidth: model.style.inkColor == ink ? 3 : 1)
                                }
                                .frame(width: 28, height: 28)
                                .accessibilityLabel(ink.displayName)
                        }
                        .buttonStyle(.plain)
                        .help(ink.displayName)
                    }
                }
            }

            Divider()

            Picker("Font", selection: $model.style.handwritingFont) {
                ForEach(HandwritingFont.allCases) { font in
                    Text(font.displayName).tag(font)
                }
            }

            Divider()

            Picker("Caption align", selection: $model.style.captionAlignment) {
                ForEach(CaptionAlignment.allCases) { alignment in
                    Text(alignment.displayName).tag(alignment)
                }
            }
            .pickerStyle(.segmented)

            Picker("Caption position", selection: $model.style.captionPosition) {
                ForEach(CaptionPosition.allCases) { position in
                    Text(position.displayName).tag(position)
                }
            }

            Picker("Caption size", selection: $model.style.captionSize) {
                ForEach(CaptionSize.allCases) { size in
                    Text(size.displayName).tag(size)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Caption")
                Spacer()
                Text(model.captionCharacterCountText)
                    .foregroundStyle(model.caption.count >= 60 ? .red : .secondary)
                    .monospacedDigit()
            }

            Menu("Suggestions") {
                ForEach(model.captionSuggestions, id: \.self) { suggestion in
                    Button(suggestion) {
                        model.applyCaptionSuggestion(suggestion)
                    }
                }
            }

            Divider()

            Picker("Frame", selection: $model.style.exportFrameMode) {
                ForEach(ExportFrameMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Picker("Background", selection: $model.style.canvasBackground) {
                ForEach(CanvasBackground.allCases) { background in
                    Text(background.displayName).tag(background)
                }
            }

            Picker("Shadow", selection: $model.style.shadowStrength) {
                ForEach(ShadowStrength.allCases) { shadow in
                    Text(shadow.displayName).tag(shadow)
                }
            }

            Toggle("Date stamp", isOn: $model.style.showDateStamp)

            Divider()

            HStack {
                Button("Randomize") {
                    model.randomizeStyle()
                }
                Button("Reset") {
                    model.resetStyle()
                }
            }

            Text(model.styleMetadataSummary)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(16)
        .frame(width: 320)
    }

    private func icon(for texture: PaperTexture) -> String {
        switch texture {
        case .cleanWhite: "square"
        case .agedCream: "sun.max"
        case .worn: "scribble"
        case .coolGray: "snowflake"
        }
    }
}
