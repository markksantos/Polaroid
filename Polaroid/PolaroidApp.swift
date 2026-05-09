import SwiftUI

@main
struct PolaroidApp: App {
    @State private var settings: AppSettings
    @State private var textureStore: PaperTextureStore
    @State private var model: PolaroidDocumentModel

    init() {
        let settings = AppSettings()
        let textureStore = PaperTextureStore()
        _settings = State(initialValue: settings)
        _textureStore = State(initialValue: textureStore)
        _model = State(initialValue: PolaroidDocumentModel(settings: settings, textureStore: textureStore))
    }

    var body: some Scene {
        WindowGroup("Polaroid", id: "main") {
            ContentView(model: model)
        }
        .defaultSize(width: 980, height: 780)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Polaroid...") {
                    model.openImagePanel()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        Window("Settings", id: "settings") {
            SettingsView(model: model)
        }
        .defaultSize(width: 560, height: 620)
        .windowResizability(.contentSize)

        MenuBarExtra("Polaroid", systemImage: "camera.viewfinder") {
            MenuBarContent(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
