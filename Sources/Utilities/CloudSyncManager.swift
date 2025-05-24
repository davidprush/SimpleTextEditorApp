/* 
    AUTHOR: David P. Rush 
    COPYRIGHT: 2025 MIT 
    DATE: 20250524
    PURPOSE: Manages iCloud synchronization, monitoring iCloud Drive for documents
    and syncing settings across devices. Ensures the app integrates seamlessly with 
    Apple’s cloud ecosystem.
*/

import Foundation
import Combine

// Manages iCloud synchronization for documents and settings, ensuring seamless cross-device access.
class CloudSyncManager: ObservableObject {
    // Indicates whether iCloud is available for the app, updated based on container access.
    @Published var iCloudAvailable: Bool = false
    // NSMetadataQuery to monitor iCloud Drive for document changes.
    private var metadataQuery: NSMetadataQuery?
    // Stores Combine subscriptions to handle notifications.
    private var cancellables = Set<AnyCancellable>()

    // Initializes the manager, setting up iCloud checks and synchronization.
    init() {
        // Checks if the iCloud container is accessible.
        checkiCloudAvailability()
        // Configures document synchronization with iCloud Drive.
        setupiCloudSync()
        // Sets up settings synchronization via NSUbiquitousKeyValueStore.
        setupSettingsSync()
    }

    // Verifies iCloud availability by checking the app's ubiquitous container.
    private func checkiCloudAvailability() {
        // Attempts to access the iCloud container for the app.
        if FileManager.default.ubiquitousContainerURL(forKey: "iCloud.com.yourcompany.SimpleTextEditor") != nil {
            // Sets iCloudAvailable to true if the container exists.
            iCloudAvailable = true
        }
    }

    // Configures NSMetadataQuery to monitor iCloud Drive for supported document types.
    private func setupiCloudSync() {
        // Creates a metadata query to search iCloud Drive.
        metadataQuery = NSMetadataQuery()
        // Limits the search to the iCloud Documents scope.
        metadataQuery?.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        // Defines a predicate to match supported file extensions (.txt, .md, .sh, .swift, .py).
        metadataQuery?.predicate = NSPredicate(format: "NSMetadataItemFSNameKey LIKE '*.txt' OR NSMetadataItemFSNameKey LIKE '*.md' OR NSMetadataItemFSNameKey LIKE '*.sh' OR NSMetadataItemFSNameKey LIKE '*.swift' OR NSMetadataItemFSNameKey LIKE '*.py'")

        // Subscribes to the query's initial results notification.
        NotificationCenter.default.publisher(for: NSMetadataQuery.didFinishGatheringNotification, object: metadataQuery)
            .sink { [weak self] _ in
                // Handles the initial set of documents found in iCloud.
                self?.handleQueryResults()
            }
            .store(in: &cancellables)

        // Subscribes to updates when iCloud documents change.
        NotificationCenter.default.publisher(for: NSMetadataQuery.didUpdateNotification, object: metadataQuery)
            .sink { [weak self] _ in
                // Handles updates to iCloud documents (e.g., new files, modifications).
                self?.handleQueryResults()
            }
            .store(in: &cancellables)

        // Starts the metadata query to begin monitoring iCloud Drive.
        metadataQuery?.start()
    }

    // Processes query results, updating the app's recent documents list.
    private func handleQueryResults() {
        // Retrieves the query results as NSMetadataItem objects.
        guard let items = metadataQuery?.results as? [NSMetadataItem] else { return }
        for item in items {
            // Extracts the URL of each document.
            if let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL {
                // Adds the document to the recent documents list for easy access.
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
            }
        }
    }

    // Sets up synchronization for settings (autosave, theme, iCloud sync) using NSUbiquitousKeyValueStore.
    private func setupSettingsSync() {
        // Forces an initial sync of the iCloud key-value store.
        NSUbiquitousKeyValueStore.default.synchronize()
        // Subscribes to external changes in the iCloud key-value store.
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber,
                      // Only processes server-initiated changes (e.g., from another device).
                      reason.intValue == NSUbiquitousKeyValueStoreServerChange else { return }

                let store = NSUbiquitousKeyValueStore.default
                // Updates autosave setting if changed in iCloud.
                if let autosave = store.object(forKey: TextDocument.autosaveKey) as? Bool {
                    UserDefaults.standard.set(autosave, forKey: TextDocument.autosaveKey)
                }
                // Updates theme setting and notifies the editor to refresh highlighting.
                if let theme = store.string(forKey: TextDocument.themeKey) {
                    UserDefaults.standard.set(theme, forKey: TextDocument.themeKey)
                    NotificationCenter.default.post(name: .NSThemeChanged, object: nil)
                }
                // Updates iCloud sync setting.
                if let iCloudSync = store.object(forKey: TextDocument.iCloudSyncKey) as? Bool {
                    UserDefaults.standard.set(iCloudSync, forKey: TextDocument.iCloudSyncKey)
                }
            }
            .store(in: &cancellables)
    }
}
