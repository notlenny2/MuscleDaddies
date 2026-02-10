import Foundation
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

@MainActor
class AuthService: NSObject, ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var error: String?

    private var currentNonce: String?
    private lazy var db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    var isDemoMode: Bool { !AppDelegate.firebaseConfigured }

    override init() {
        super.init()
        if isDemoMode {
            // Demo mode — show app with fake data
            self.currentUser = AppUser(
                id: "demo",
                displayName: "Demo Daddy",
                groupId: "demo-group",
                stats: UserStats(strength: 42, speed: 35, endurance: 55, intelligence: 28, level: 12,
                                 xpCurrent: 420, xpToNext: 1200, totalXP: 15420,
                                 hpCurrent: 76, hpMax: 100, xpMultiplier: 1.12),
                currentStreak: 4,
                longestStreak: 14,
                selectedTheme: .pixel,
                classTheme: .fantasy,
                selectedClass: .warrior
            )
            self.isAuthenticated = true
            self.isLoading = false
        } else {
            listenForAuthChanges()
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func listenForAuthChanges() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                guard let self else { return }
                if let firebaseUser {
                    await self.fetchOrCreateUser(firebaseUser: firebaseUser)
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
                self.isLoading = false
            }
        }
    }

    private func fetchOrCreateUser(firebaseUser: FirebaseAuth.User) async {
        let uid = firebaseUser.uid
        do {
            let doc = try await db.collection(Constants.Firestore.users).document(uid).getDocument()
            if doc.exists {
                self.currentUser = try doc.data(as: AppUser.self)
            }
            // If doc doesn't exist, user needs onboarding - don't create yet
            self.isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func completeOnboarding(
        displayName: String,
        classTheme: Constants.ClassTheme,
        selectedClass: Constants.MuscleClass,
        priorityPrimary: Constants.PriorityStat,
        prioritySecondary: Constants.PriorityStat,
        heightCm: Double?,
        weightKg: Double?,
        heightCategory: Constants.HeightCategory?,
        bodyType: Constants.BodyType?,
        goals: UserGoals?
    ) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let user = AppUser(
            id: uid,
            displayName: displayName,
            selectedTheme: classTheme.cardTheme,
            classTheme: classTheme,
            selectedClass: selectedClass,
            priorityPrimary: priorityPrimary,
            prioritySecondary: prioritySecondary,
            heightCm: heightCm,
            weightKg: weightKg,
            heightCategory: heightCategory,
            bodyType: bodyType,
            goals: goals
        )
        do {
            try db.collection(Constants.Firestore.users).document(uid).setData(from: user)
            self.currentUser = user
        } catch {
            self.error = error.localizedDescription
        }
    }

    func applyOnboardingUpdates(
        displayName: String,
        classTheme: Constants.ClassTheme,
        selectedClass: Constants.MuscleClass,
        priorityPrimary: Constants.PriorityStat,
        prioritySecondary: Constants.PriorityStat,
        heightCm: Double?,
        weightKg: Double?,
        heightCategory: Constants.HeightCategory?,
        bodyType: Constants.BodyType?,
        goals: UserGoals?
    ) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        var user = currentUser ?? AppUser(
            id: uid,
            displayName: displayName,
            selectedTheme: classTheme.cardTheme,
            classTheme: classTheme,
            selectedClass: selectedClass
        )

        user.displayName = displayName
        user.classTheme = classTheme
        user.selectedTheme = classTheme.cardTheme
        user.selectedClass = selectedClass
        user.priorityPrimary = priorityPrimary
        user.prioritySecondary = prioritySecondary
        user.heightCm = heightCm
        user.weightKg = weightKg
        user.heightCategory = heightCategory
        user.bodyType = bodyType
        user.goals = goals

        do {
            try db.collection(Constants.Firestore.users).document(uid).setData(from: user, merge: true)
            self.currentUser = user
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Sign in with Apple

    func handleSignInWithApple() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }

    func handleSignInWithAppleCompletion(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                self.error = "Failed to get Apple ID credentials"
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            do {
                let result = try await Auth.auth().signIn(with: credential)
                await fetchOrCreateUser(firebaseUser: result.user)
            } catch {
                self.error = error.localizedDescription
            }

        case .failure(let error):
            self.error = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            self.error = error.localizedDescription
        }
    }

    func signInAsDemo() {
        currentUser = AppUser(
            id: "demo",
            displayName: "Demo Daddy",
            groupId: "demo-group",
            stats: UserStats(
                strength: 42,
                speed: 35,
                endurance: 55,
                intelligence: 28,
                level: 12,
                xpCurrent: 420,
                xpToNext: 1200,
                totalXP: 15420,
                hpCurrent: 76,
                hpMax: 100,
                xpMultiplier: 1.12
            ),
            currentStreak: 4,
            longestStreak: 14,
            selectedTheme: .pixel,
            classTheme: .fantasy,
            selectedClass: .warrior
        )
        isAuthenticated = true
        isLoading = false
        error = nil
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
