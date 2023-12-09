import XCTest
@testable import AppDMG

final class AppDMGTests: XCTestCase {
    func testCreateDMG() async throws {
        AppDMG.default.log = true
        try await AppDMG.default.createDMG(
            url: URL(string: "file:///Users/chocoford/Downloads/test_hdituil/TrickleCapture_Test.app")!,
            backgroundImage: nil,
            appIconPos: CGPoint(x: 180, y: 170),
            appendixes: [.application(position: CGPoint(x: 480, y: 170))]
        )
    }
    
    func testSecurity() async throws {
        print(try await SecurityHelper.shared.listIdentities(policy: .codesigning))
    }
    
    func testMakingIcon() async throws {
        let icon = try AppDMG.default.makeIcon(appIcon: URL(string: "file:///Volumes/Trickle Capture Test 0.1.19 RC 2(18)/TrickleCapture_Test.app/Contents/Resources/AppIcon.icns")!)
        print(icon)
    }
}
