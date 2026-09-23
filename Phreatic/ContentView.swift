import SwiftUI

struct ContentView: View {
    @StateObject private var store: AquiferStore
    private let supportDirectory: URL

    init() {
        let directory = Self.makeSupportDirectory()
        supportDirectory = directory
        _store = StateObject(wrappedValue: AquiferStore(directory: directory))
    }

    var body: some View {
        WellRootView(store: store, supportDirectory: supportDirectory)
    }

    private static func makeSupportDirectory() -> URL {
        if let url = try? AquiferStore.applicationSupportDirectory() {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }
        let fallback = FileManager.default.temporaryDirectory.appendingPathComponent("phr", isDirectory: true)
        try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
    }
}

#Preview {
    ContentView()
}
