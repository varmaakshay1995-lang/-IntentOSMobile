import XCTest
@testable import IntentOSKit

final class IntentOSKitTests: XCTestCase {
    func testMockGatewayBasicResponse() async throws {
        let gateway = MockIntentGateway()
        let request = IntentRequest(
            text: "open google",
            screenshotBase64: nil,
            platform: "iPhone / iOS",
            availableActions: []
        )
        
        let decision = try await gateway.decide(request: request)
        XCTAssertEqual(decision.decision, .guide)
        XCTAssert(decision.response.contains("Mock mode"))
    }
    
    func testActionExecutorURLOpen() async throws {
        let executor = ActionExecutor()
        let params = ["url": "https://google.com"]
        
        // Test that it doesn't throw
        try await executor.execute(name: "open_url", parameters: params)
    }
    
    func testActionExecutorInvalidAction() async throws {
        let executor = ActionExecutor()
        
        do {
            try await executor.execute(name: "invalid_action", parameters: [:])
            XCTFail("Should have thrown unsupportedAction")
        } catch IntentOSError.unsupportedAction {
            // Expected
        }
    }
    
    func testImageCompressionJPEG() {
        // Create a simple test image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let testImage = renderer.image { _ in
            UIColor.blue.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 100, height: 100)).fill()
        }
        
        let base64 = testImage.intentOSJPEGBase64()
        XCTAssertNotNil(base64)
        XCTAssert(base64!.count > 0)
    }
}
