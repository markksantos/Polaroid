import AppKit
import SwiftUI

struct MenuBarContent: View {
    @Bindable var model: PolaroidDocumentModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                openMainWindow()
                model.openImagePanel()
            } label: {
                Label("New Polaroid...", systemImage: "photo.badge.plus")
            }
            .keyboardShortcut("n", modifiers: .command)

            Button {
                openMainWindow()
                model.pasteImageFromClipboard()
            } label: {
                Label("Paste Image", systemImage: "clipboard")
            }

            Button {
                openMainWindow()
                model.rescanDesktop()
            } label: {
                Label("Rescan Desktop", systemImage: "arrow.clockwise")
            }

            if !model.settings.recentPolaroids.isEmpty {
                Divider()

                Text("Recent Polaroids")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(model.settings.recentPolaroids) { recent in
                    Menu {
                        Button("Open") {
                            openMainWindow()
                            model.openRecent(recent)
                        }
                        Button("Reveal in Finder") {
                            model.revealRecent(recent)
                        }
                        Button("Remove from Recents") {
                            model.removeRecent(recent)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            thumbnail(for: recent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(recent.caption.isEmpty ? recent.renderedURL.deletingPathExtension().lastPathComponent : recent.caption)
                                    .lineLimit(1)
                                Text(recent.createdAt, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Button("Clear Recent Polaroids") {
                    model.clearRecentPolaroids()
                }
            }

            Divider()

            Button(model.isWatcherPausedForSession ? "Resume Desktop Watcher" : "Pause Desktop Watcher") {
                if model.isWatcherPausedForSession {
                    model.resumeWatcher()
                } else {
                    model.pauseWatcherForSession()
                }
            }

            Button("Open Save Folder") {
                model.openSaveFolder()
            }

            Button {
                openWindow(id: "settings")
                NSApplication.shared.activate(ignoringOtherApps: true)
            } label: {
                Label("Settings...", systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: .command)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit Polaroid", systemImage: "power")
            }
        }
        .padding(14)
        .frame(width: 290)
    }

    @ViewBuilder
    private func thumbnail(for recent: RecentPolaroid) -> some View {
        if let image = NSImage(contentsOf: recent.thumbnailURL) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(.secondary.opacity(0.2))
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
