import Foundation
import Combine

class CloudSyncManager: ObservableObject {
    @Published var iCloudAvailable: Bool = false
    private var metadataQuery: NSMetadataQuery?
    private var cancellables = Set<AnyCancellable>()

    init() {
        checkiCloudAvailability()
        setupiCloudSync()
        setupSettingsSync()
    }

    private func checkiCloudAvailability() {
        if FileManager.default.ubiquitousContainerURL(forKey: "iCloud.com.yourcompany.SimpleTextEditor") != nil {
            iCloudAvailable = true
        }
    }

    private func setupiCloudSync() {
        metadataQuery = NSMetadataQuery()
        metadataQuery?.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        metadataQuery?.predicate = NSPredicate(format: "NSMetadataItemFSNameKey LIKE '*.txt' OR NSMetadataItemFSNameKey LIKE '*.md' OR NSMetadataItemFSNameKey LIKE '*.sh' OR NSMetadataItemFSNameKey LIKE '*.swift' OR NSMetadataItemFSNameKey LIKE '*.py'")

        NotificationCenter.default.publisher(for: NSMetadataQuery.didFinishGatheringNotification, object: metadataQuery)
            .sink { [weak self] _ in
                self?.handleQueryResults()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSMetadataQuery.didUpdateNotification, object: metadataQuery)
            .sink { [weak self] _ in
                self?.handleQueryResults()
            }
            .store(in: &cancellables)

        metadataQuery?.start()
    }

    private func handleQueryResults() {
        guard let items = metadataQuery?.results as? [NSMetadataItem] else { return }
        for item in items {
            if let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL {
                // Ensure documents are accessible
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
            }
        }
    }

    private func setupSettingsSync() {
        NSUbiquitousKeyValueStore.default.synchronize()
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber,
                      reason.intValue == NSUbiquitousKeyValueStoreServerChange else { return }

                let store = NSUbiquitousKeyValueStore.default
                if let autosave = store.object(forKey: TextDocument.autosaveKey) as? Bool {
                    UserDefaults.standard.set(autosave, forKey: TextDocument.autosaveKey)
                }
                if let theme = store.string(forKey: TextDocument.themeKey) {
                    UserDefaults.standard.set(theme, forKey: TextDocument.themeKey)
                    NotificationCenter.default.post(name: .NSThemeChanged, object: nil)
                }
                if let iCloudSync = store.object(forKey: TextDocument.iCloudSyncKey) as? Bool {
                    UserDefaults.standard.set(iCloudSync, forKey: TextDocument.iCloudSyncKey)
                }
            }
            .store(in: &cancellables)
    }
}
