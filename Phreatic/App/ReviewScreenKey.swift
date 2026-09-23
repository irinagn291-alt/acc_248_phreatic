import Foundation

/// Presentation hook. Reads `-ReviewScreen` exactly once after intake is done.
/// Keys are launch arguments, never tabs.
enum ReviewScreenKey: Equatable, Sendable {
    case today
    case log
    case goals
    case intake
    case ebb
    case dial

    static func parse(_ arguments: [String]) -> ReviewScreenKey? {
        guard let flag = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: flag)
        guard arguments.indices.contains(next) else { return nil }
        switch arguments[next] {
        case "today", "well", "home":
            return .today
        case "log", "history":
            return .log
        case "goals", "settings":
            return .goals
        case "intake":
            return .intake
        case "ebb", "twist":
            return .ebb
        case "dial":
            return .dial
        default:
            return nil
        }
    }

    static func consume(
        arguments: [String],
        intakeDone: Bool,
        consumed: inout Bool
    ) -> ReviewScreenKey? {
        guard intakeDone, !consumed else { return nil }
        consumed = true
        return parse(arguments)
    }

    static func consumeProcessInfo(intakeDone: Bool, consumed: inout Bool) -> ReviewScreenKey? {
        consume(
            arguments: ProcessInfo.processInfo.arguments,
            intakeDone: intakeDone,
            consumed: &consumed
        )
    }
}
