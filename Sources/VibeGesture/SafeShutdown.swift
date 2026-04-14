import Foundation

enum SafeShutdownReason: String, Codable, Equatable {
    case permissionMissing
    case recognitionDisabled
    case recognitionTimedOut
}

@MainActor
protocol SafeShutdownHandling {
    func requestSafeShutdown(reason: SafeShutdownReason)
}
