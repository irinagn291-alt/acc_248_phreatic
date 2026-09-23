import Foundation

/// Off-main file seam. The main thread never blocks on disk.
actor AquiferFileIO {
    func data(at url: URL) throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try AtomicPlist.read(from: url)
    }

    func write(_ data: Data, to url: URL) throws {
        let folder = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try AtomicPlist.write(data, to: url)
    }

    func copy(_ source: URL, to destination: URL) throws {
        let folder = destination.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        guard FileManager.default.fileExists(atPath: source.path) else { return }
        try FileManager.default.copyItem(at: source, to: destination)
    }

    func removeItem(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
