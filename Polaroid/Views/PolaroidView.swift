import AppKit
import SwiftUI

struct PolaroidView: View {
    @Bindable var model: PolaroidDocumentModel
    @Namespace private var namespace
    @State private var paperVisible = false
    @State private var photoDeveloped = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(nsColor: .windowBackgroundColor)

                if let image = model.previewImage {
                    ZStack {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .saturation(photoDeveloped || model.settings.skipDevelopAnimation ? 1 : 0)
                            .colorMultiply(photoDeveloped || model.settings.skipDevelopAnimation ? .white : Color(red: 0.72, green: 0.55, blue: 0.36))
                            .opacity(photoDeveloped || model.settings.skipDevelopAnimation ? 1 : 0.34)

                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .opacity(photoDeveloped || model.settings.skipDevelopAnimation ? 1 : 0)
                    }
                    .matchedGeometryEffect(id: "polaroid", in: namespace)
                    .frame(width: min(proxy.size.width * 0.78, proxy.size.height * 0.64))
                    .rotationEffect(.degrees(model.style.rotationDegrees))
                    .scaleEffect(paperVisible ? 1 : 0.94)
                    .offset(y: paperVisible ? 0 : -44)
                    .animation(DevelopAnimation.paperDrop, value: paperVisible)
                    .animation(DevelopAnimation.photoDevelop.delay(DevelopAnimation.dropDuration), value: photoDeveloped)
                    .overlay {
                        CaptionEditor(model: model)
                    }
                    .id(model.developAnimation.token)
                    .onAppear(perform: runAnimation)
                    .onChange(of: model.developAnimation.token) { _, _ in
                        runAnimation()
                    }
                }
            }
            .background(DirectTouchShakeMonitor {
                model.triggerDevelop()
            })
        }
    }

    private func runAnimation() {
        if model.settings.skipDevelopAnimation {
            paperVisible = true
            photoDeveloped = true
            return
        }

        paperVisible = false
        photoDeveloped = false

        DispatchQueue.main.async {
            withAnimation(DevelopAnimation.paperDrop) {
                paperVisible = true
            }
            withAnimation(DevelopAnimation.photoDevelop.delay(DevelopAnimation.dropDuration)) {
                photoDeveloped = true
            }
        }
    }
}

private struct DirectTouchShakeMonitor: NSViewRepresentable {
    let onShake: @MainActor () -> Void

    func makeNSView(context: Context) -> MonitorView {
        let view = MonitorView()
        view.onShake = onShake
        return view
    }

    func updateNSView(_ nsView: MonitorView, context: Context) {
        nsView.onShake = onShake
    }

    final class MonitorView: NSView {
        var onShake: (@MainActor () -> Void)?
        private var monitor: Any?
        private var lastShake = Date.distantPast
        private var touchHistory: [CGFloat] = []

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window == nil {
                if let monitor {
                    NSEvent.removeMonitor(monitor)
                }
                monitor = nil
                return
            }

            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.directTouch]) { [weak self] event in
                self?.handle(event)
                return event
            }
        }

        private func handle(_ event: NSEvent) {
            let touches = event.touches(matching: .any, in: self)
            guard touches.count >= 2 else { return }

            let averageX = touches.map(\.normalizedPosition.x).reduce(0, +) / CGFloat(touches.count)
            touchHistory.append(averageX)
            if touchHistory.count > 8 {
                touchHistory.removeFirst()
            }

            guard
                touchHistory.count == 8,
                let minX = touchHistory.min(),
                let maxX = touchHistory.max(),
                maxX - minX > 0.42,
                Date().timeIntervalSince(lastShake) > 0.9
            else {
                return
            }

            lastShake = Date()
            Task { @MainActor in
                onShake?()
            }
        }

    }
}
