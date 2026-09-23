import Foundation

/// Atomic property-list write helper. Reads and writes a single Data blob
/// with replace-on-success and complete file protection.
/// Vendored as compiled source. Local adjustments live in the app target.
enum AtomicPlist {
    enum Failure: Error, Sendable {
        case missingFile
        case io
    }

    static func read(from url: URL) throws -> Data {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw Failure.missingFile
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw Failure.io
        }
    }

    static func write(_ data: Data, to url: URL) throws {
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            throw Failure.io
        }
    }
}
