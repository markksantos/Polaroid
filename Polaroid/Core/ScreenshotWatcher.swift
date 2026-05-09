import AppKit
import Darwin
import Foundation
import UniformTypeIdentifiers

final class ScreenshotWatcher: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.nosleeplab.Polaroid.ScreenshotWatcher", qos: .utility)
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1
    private var watchedDirectory: URL?
    private var knownFiles = Set<URL>()
    private let eventContinuation: AsyncStream<URL>.Continuation

    let events: AsyncStream<URL>

    init() {
        let stream = AsyncStream<URL>.makeStream(of: URL.self, bufferingPolicy: .bufferingNewest(12))
        events = stream.stream
        eventContinuation = stream.continuation
    }

    deinit {
        queue.sync {
            stopOnQueue()
        }
        eventContinuation.finish()
    }

    func start(watching directory: URL) {
        queue.async { [weak self] in
            self?.startOnQueue(watching: directory)
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.stopOnQueue()
        }
    }

    static func isScreenshotURL(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        guard name.hasSuffix(".png") else {
            return false
        }
        return name.hasPrefix("Screenshot ") || name.hasPrefix("Screen Shot ")
    }

    private func startOnQueue(watching directory: URL) {
        stopOnQueue()
        watchedDirectory = directory
        knownFiles = Set(scan(directory: directory, maximumAge: nil))

        let descriptor = open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else {
            return
        }

        fileDescriptor = descriptor
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .extend, .attrib],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.scanForNewScreenshots()
        }
        source.setCancelHandler { [descriptor] in
            close(descriptor)
        }

        self.source = source
        source.resume()
    }

    private func stopOnQueue() {
        source?.cancel()
        source = nil
        fileDescriptor = -1
        watchedDirectory = nil
        knownFiles.removeAll()
    }

    private func scanForNewScreenshots() {
        guard let watchedDirectory else { return }
        let current = scan(directory: watchedDirectory, maximumAge: 8)
        for url in current where !knownFiles.contains(url) {
            knownFiles.insert(url)
            queue.asyncAfter(deadline: .now() + 0.25) { [weak self, url] in
                self?.eventContinuation.yield(url)
            }
        }
    }

    private func scan(directory: URL, maximumAge: TimeInterval?) -> [URL] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let now = Date()
        return urls.filter { url in
            guard Self.isScreenshotURL(url) else { return false }

            let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey, .isRegularFileKey])
            guard values?.isRegularFile == true else { return false }

            guard let maximumAge else { return true }
            let date = values?.creationDate ?? values?.contentModificationDate ?? .distantPast
            return now.timeIntervalSince(date) <= maximumAge
        }
    }
}
