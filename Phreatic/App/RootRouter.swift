import Foundation

/// Presentation destinations over the locked well. Depth is one: a sheet
/// or the intake cover, never a stack of both.
enum WellSheet: String, Identifiable, Equatable, Sendable {
    case history
    case settings
    case ebbDrain
    case dial

    var id: String { rawValue }
}

enum RootRouter {
    static func sheet(for key: ReviewScreenKey) -> WellSheet? {
        switch key {
        case .today, .intake:
            return nil
        case .log:
            return .history
        case .goals:
            return .settings
        case .ebb:
            return .ebbDrain
        case .dial:
            return .dial
        }
    }

    static func opensIntake(_ key: ReviewScreenKey) -> Bool {
        key == .intake
    }
}
