import SwiftUI

struct SettingsView: View {
    let model: PolaroidDocumentModel
    @Bindable private var settings: AppSettings

    init(model: PolaroidDocumentModel) {
        self.model = model
        settings = model.settings
    }

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Paper texture", selection: $settings.defaultPaperTexture) {
                    ForEach(PaperTexture.allCases) { texture in
                        Text(texture.displayName).tag(texture)
                    }
                }

                Picker("Ink color", selection: $settings.defaultInkColor) {
                    ForEach(InkColor.allCases) { ink in
                        Text(ink.displayName).tag(ink)
                    }
                }

                Picker("Font", selection: $settings.defaultFont) {
                    ForEach(HandwritingFont.allCases) { font in
                        Text(font.displayName).tag(font)
                    }
                }

                Picker("Rotation", selection: $settings.defaultRotationBehavior) {
                    ForEach(RotationBehavior.allCases) { behavior in
                        Text(behavior.displayName).tag(behavior)
                    }
                }

                Picker("Caption alignment", selection: $settings.defaultCaptionAlignment) {
                    ForEach(CaptionAlignment.allCases) { alignment in
                        Text(alignment.displayName).tag(alignment)
                    }
                }

                Picker("Caption position", selection: $settings.defaultCaptionPosition) {
                    ForEach(CaptionPosition.allCases) { position in
                        Text(position.displayName).tag(position)
                    }
                }

                Picker("Caption size", selection: $settings.defaultCaptionSize) {
                    ForEach(CaptionSize.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }

                Picker("Shadow", selection: $settings.defaultShadowStrength) {
                    ForEach(ShadowStrength.allCases) { shadow in
                        Text(shadow.displayName).tag(shadow)
                    }
                }
            }

            Section("Behavior") {
                Toggle("Auto-watch Desktop", isOn: Binding(
                    get: { settings.autoWatchDesktop },
                    set: {
                        settings.autoWatchDesktop = $0
                        model.updateWatcher()
                    }
                ))

                Button("Choose Desktop watch folder...") {
                    model.chooseDesktopWatchFolder()
                }

                Toggle("Skip develop animation", isOn: $settings.skipDevelopAnimation)
                Toggle("Show date stamp", isOn: $settings.showDateStamp)
                Button(model.isWatcherPausedForSession ? "Resume Desktop watcher" : "Pause Desktop watcher") {
                    if model.isWatcherPausedForSession {
                        model.resumeWatcher()
                    } else {
                        model.pauseWatcherForSession()
                    }
                }
                Button("Rescan Desktop now") {
                    model.rescanDesktop()
                }
            }

            Section("Export") {
                HStack {
                    Text("Save location")
                    Spacer()
                    Text(settings.resolvedSaveDirectory().path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                    Button("Choose...") {
                        model.chooseSaveLocation()
                    }
                }

                Picker("Export size", selection: $settings.exportSize) {
                    ForEach(ExportSize.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }

                Picker("Frame preset", selection: $settings.defaultExportFrameMode) {
                    ForEach(ExportFrameMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Picker("Canvas background", selection: $settings.defaultCanvasBackground) {
                    ForEach(CanvasBackground.allCases) { background in
                        Text(background.displayName).tag(background)
                    }
                }

                TextField("File naming pattern", text: $settings.fileNamingPattern)

                LabeledContent("Filename preview", value: settings.filenamePreview)

                HStack {
                    Button("Open save folder") {
                        model.openSaveFolder()
                    }
                    Button("Reveal last export") {
                        model.revealLastExport()
                    }
                    Button("Copy last path") {
                        model.copyLastExportPath()
                    }
                }
            }

            Section("Maintenance") {
                Button("Use current style as defaults") {
                    model.useCurrentStyleAsDefaults()
                }
                Button("Apply defaults to current Polaroid") {
                    model.applyDefaultStyle()
                }
                Button("Clear recent Polaroids") {
                    model.clearRecentPolaroids()
                }
                Button("Reset all settings") {
                    model.resetSettingsToDefaults()
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                if let url = URL(string: "https://nosleeplab.com") {
                    Link("NoSleepLab", destination: url)
                }
                Text("Made by Mark Studios")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(18)
        .frame(width: 640, height: 760)
    }
}
