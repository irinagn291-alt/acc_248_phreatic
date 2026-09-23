import XCTest
@testable import Phreatic

/// Placeholder. Replace with the cases required by SPEC.md section 17.
final class PhreaticTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: PhreaticApp.self), "PhreaticApp")
    }
}
