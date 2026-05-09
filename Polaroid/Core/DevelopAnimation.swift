import Foundation
import SwiftUI

struct DevelopAnimation: Equatable, Sendable {
    static let totalDuration: TimeInterval = 1.4
    static let dropDuration: TimeInterval = 0.3
    static let developDuration: TimeInterval = 1.1

    let token: UUID

    init(token: UUID = UUID()) {
        self.token = token
    }

    static var paperDrop: Animation {
        .interpolatingSpring(mass: 0.74, stiffness: 185, damping: 17, initialVelocity: 0.7)
    }

    static var photoDevelop: Animation {
        .easeInOut(duration: developDuration)
    }
}
