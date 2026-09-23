import Combine
import Foundation

/// The tick that accrues drain and detects crossings. Runs at 1 Hz while
/// the well root is visible and fires once on foreground return.
@MainActor
final class DrawDownClock: ObservableObject {
    @Published private(set) var level: WellLevel
    @Published private(set) var now: Date

    private let store: AquiferStore
    private var timer: AnyCancellable?

    init(store: AquiferStore) {
        self.store = store
        let stamp = Date()
        self.now = stamp
        self.level = store.project(at: stamp)
    }

    func start() {
        refresh()
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.fire(at: date)
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func refresh() {
        fire(at: Date())
    }

    private func fire(at date: Date) {
        store.tick(at: date)
        now = date
        level = store.project(at: date)
    }
}
