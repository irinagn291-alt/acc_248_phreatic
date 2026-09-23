import Foundation

/// Default tap volume for the home verb. Family invariant: 250 ml.
enum SipVolume {
    static let defaultMl = 250
    static let minimumMl = 50
    static let maximumMl = 1_000

    static func sanitized(_ millilitres: Int) -> Int {
        min(maximumMl, max(minimumMl, millilitres))
    }

    static func isValid(_ millilitres: Int) -> Bool {
        millilitres > 0 && millilitres <= maximumMl
    }
}
