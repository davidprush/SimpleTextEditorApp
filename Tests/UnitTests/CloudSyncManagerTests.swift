import XCTest
@testable import SimpleTextEditor

class CloudSyncManagerTests: XCTestCase {
    func testiCloudAvailability() {
        let manager = CloudSyncManager()
        // Mock FileManager to simulate iCloud container presence
        XCTAssertFalse(manager.iCloudAvailable) // Adjust based on test environment
    }
}