import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var model: PolaroidDocumentModel
    @State private var isShowingStylePicker = false
    @State private var shareView: NSView?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if model.screenshot == nil {
                    DropZoneView(model: model)
                } else {
                    PolaroidView(model: model)
                }
            }

            if let toast = model.toast {
                Text(toast.message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.76), in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            VStack {
                Spacer()
                HStack {
                    Text(model.renderDiagnostics)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.regularMaterial, in: Capsule())
                    Spacer()
                }
                .padding(.leading, 18)
                .padding(.bottom, 18)
            }
        }
        .background(ShareAnchorView { view in
            shareView = view
        }.frame(width: 0, height: 0))
        .toolbar {
            ToolbarItemGroup {
                Button {
                    model.openImagePanel()
                } label: {
                    Label("New Polaroid", systemImage: "photo.badge.plus")
                }
                .help("New Polaroid")

                Button {
                    model.pasteImageFromClipboard()
                } label: {
                    Label("Paste Image", systemImage: "clipboard")
                }
                .keyboardShortcut("v", modifiers: .command)
                .help("Paste image from clipboard")

                Button {
                    model.triggerDevelop()
                } label: {
                    Label("Develop", systemImage: "camera.filters")
                }
                .help("Develop again")
                .disabled(model.screenshot == nil)

                Button {
                    isShowingStylePicker.toggle()
                } label: {
                    Label("Style", systemImage: "paintpalette")
                }
                .help("Style")
                .popover(isPresented: $isShowingStylePicker, arrowEdge: .bottom) {
                    StylePickerView(model: model)
                }

                Menu {
                    ForEach(model.captionSuggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            model.applyCaptionSuggestion(suggestion)
                        }
                    }
                    Divider()
                    Button("Uppercase") { model.uppercaseCaption() }
                    Button("Lowercase") { model.lowercaseCaption() }
                    Button("Title Case") { model.titleCaseCaption() }
                    Button("Clear Caption") { model.clearCaption() }
                } label: {
                    Label("Caption", systemImage: "textformat")
                }
                .disabled(model.screenshot == nil)

                Menu {
                    Button("Nudge Left") { model.nudgeRotationLeft() }
                        .keyboardShortcut("[", modifiers: .command)
                    Button("Nudge Right") { model.nudgeRotationRight() }
                        .keyboardShortcut("]", modifiers: .command)
                    Button("Straighten") { model.straightenRotation() }
                        .keyboardShortcut("0", modifiers: .command)
                    Button("Shuffle Rotation") { model.shuffleRotation() }
                    Divider()
                    Button("Cycle Paper") { model.cyclePaperTexture() }
                    Button("Cycle Ink") { model.cycleInkColor() }
                    Button("Cycle Font") { model.cycleFont() }
                    Button("Randomize Style") { model.randomizeStyle() }
                    Button("Reset Style") { model.resetStyle() }
                    Divider()
                    Button("Use Current Style as Defaults") { model.useCurrentStyleAsDefaults() }
                    Button("Apply Default Style") { model.applyDefaultStyle() }
                } label: {
                    Label("Adjust", systemImage: "slider.horizontal.3")
                }
                .disabled(model.screenshot == nil)
            }

            ToolbarItemGroup {
                Button {
                    model.save()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
                .help("Save")
                .disabled(model.screenshot == nil)

                Button {
                    model.saveAs()
                } label: {
                    Label("Save As", systemImage: "square.and.arrow.down.on.square")
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                .help("Save As")
                .disabled(model.screenshot == nil)

                Button {
                    model.copy()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .keyboardShortcut("c", modifiers: .command)
                .help("Copy")
                .disabled(model.screenshot == nil)

                Button {
                    model.share(from: shareView)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .help("Share")
                .disabled(model.screenshot == nil)

                Menu {
                    Button("Reveal Last Export") { model.revealLastExport() }
                    Button("Open Save Folder") { model.openSaveFolder() }
                    Button("Copy Last Export Path") { model.copyLastExportPath() }
                    Divider()
                    Button("Remove Current Polaroid") { model.removeCurrentPolaroid() }
                    Divider()
                    Button(model.isWatcherPausedForSession ? "Resume Desktop Watcher" : "Pause Desktop Watcher") {
                        if model.isWatcherPausedForSession {
                            model.resumeWatcher()
                        } else {
                            model.pauseWatcherForSession()
                        }
                    }
                    Button("Rescan Desktop") { model.rescanDesktop() }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }

                Button {
                    openWindow(id: "settings")
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .keyboardShortcut(",", modifiers: .command)
                .help("Settings")
            }
        }
        .task {
            model.openMainWindow = {
                openWindow(id: "main")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            model.startWatchingDesktop()
        }
        .onChange(of: model.settings.showDateStamp) { _, show in
            model.style.showDateStamp = show
        }
        .frame(minWidth: 820, minHeight: 720)
    }
}

private struct ShareAnchorView: NSViewRepresentable {
    let onResolve: @MainActor (NSView) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        Task { @MainActor in
            onResolve(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        Task { @MainActor in
            onResolve(nsView)
        }
    }
}
