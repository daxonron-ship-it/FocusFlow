import Foundation
import FamilyControls
import ManagedSettings
import Combine

/// Manages app blocking using FamilyControls and ManagedSettings frameworks.
/// Note: FamilyControls does NOT work in Simulator - requires physical device testing.
@MainActor
final class BlockingManager: ObservableObject {
    static let shared = BlockingManager()

    // MARK: - Published Properties

    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var activitySelection = FamilyActivitySelection()
    @Published private(set) var isBlocking: Bool = false

    // MARK: - Private Properties

    private let authorizationCenter = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()

    // MARK: - Computed Properties

    var isAuthorized: Bool {
        authorizationStatus == .approved
    }

    var hasSelectedApps: Bool {
        !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty
    }

    var selectedAppsCount: Int {
        activitySelection.applicationTokens.count
    }

    var selectedCategoriesCount: Int {
        activitySelection.categoryTokens.count
    }

    var totalBlockedCount: Int {
        selectedAppsCount + selectedCategoriesCount
    }

    var blockingDescription: String {
        if totalBlockedCount == 0 {
            return "None"
        } else if selectedCategoriesCount > 0 && selectedAppsCount > 0 {
            return "\(selectedAppsCount) apps, \(selectedCategoriesCount) categories"
        } else if selectedCategoriesCount > 0 {
            return "\(selectedCategoriesCount) \(selectedCategoriesCount == 1 ? "category" : "categories")"
        } else {
            return "\(selectedAppsCount) \(selectedAppsCount == 1 ? "app" : "apps")"
        }
    }

    // MARK: - Initialization

    private init() {
        // Check initial authorization status
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Request FamilyControls authorization. This will trigger Face ID/passcode authentication.
    func requestAuthorization() async throws {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            await checkAuthorizationStatus()
        } catch {
            await checkAuthorizationStatus()
            throw error
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let status = authorizationCenter.authorizationStatus
        await MainActor.run {
            self.authorizationStatus = status
        }
    }

    // MARK: - Blocking Control

    /// Start blocking the selected apps and categories
    func startBlocking() {
        guard isAuthorized && hasSelectedApps else { return }

        // Configure shield for selected apps
        store.shield.applications = activitySelection.applicationTokens.isEmpty ? nil : activitySelection.applicationTokens
        store.shield.applicationCategories = activitySelection.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)
        store.shield.webDomains = activitySelection.webDomainTokens.isEmpty ? nil : activitySelection.webDomainTokens
        store.shield.webDomainCategories = activitySelection.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)

        isBlocking = true
        HapticManager.shared.lightTap()
    }

    /// Stop blocking all apps
    func stopBlocking() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil

        isBlocking = false
    }

    /// Clear the current app selection
    func clearSelection() {
        activitySelection = FamilyActivitySelection()
    }

    // MARK: - Persistence

    /// Save selection to UserDefaults (tokens are Codable)
    func saveSelection() {
        if let encoded = try? JSONEncoder().encode(activitySelection) {
            UserDefaults.standard.set(encoded, forKey: "BlockingManager.activitySelection")
        }
    }

    /// Load selection from UserDefaults
    func loadSelection() {
        if let data = UserDefaults.standard.data(forKey: "BlockingManager.activitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            activitySelection = selection
        }
    }
}

// MARK: - Authorization Status Extension

extension AuthorizationStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .approved:
            return "Approved"
        @unknown default:
            return "Unknown"
        }
    }
}
