import LocalAuthentication

/// Service for handling device authentication (passcode/biometrics)
/// Used for emergency bypass and secure strict mode disable
final class AuthenticationService {
    static let shared = AuthenticationService()

    private init() {}

    /// Request device authentication (passcode, Face ID, or Touch ID)
    /// - Parameters:
    ///   - reason: The reason string shown to the user
    ///   - completion: Callback with success/failure result
    func requestAuthentication(
        reason: String,
        completion: @escaping (Bool) -> Void
    ) {
        let context = LAContext()
        var error: NSError?

        // Check if device supports authentication
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Device doesn't support authentication - allow bypass
            // This handles simulator and devices without passcode
            DispatchQueue.main.async {
                completion(true)
            }
            return
        }

        // Request authentication
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    /// Request authentication with async/await
    /// - Parameter reason: The reason string shown to the user
    /// - Returns: Whether authentication succeeded
    @MainActor
    func requestAuthentication(reason: String) async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthentication(reason: reason) { success in
                continuation.resume(returning: success)
            }
        }
    }
}
