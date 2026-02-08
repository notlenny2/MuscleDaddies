import SwiftUI
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    static var firebaseConfigured = false

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Force demo mode for preview — flip to false when ready for real Firebase
        let forceDemo = true

        if !forceDemo,
           let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let appId = plist["GOOGLE_APP_ID"] as? String,
           !appId.contains("YOUR_") {
            FirebaseApp.configure()
            AppDelegate.firebaseConfigured = true
            Messaging.messaging().delegate = self
        } else {
            print("⚠️ Running in demo mode")
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM token: \(token)")
        // Token gets saved to user doc via NotificationService.getFCMToken()
    }
}

@main
struct MuscleDaddiesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService()
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(firestoreService)
                .environmentObject(healthKitService)
                .environmentObject(notificationService)
                .preferredColorScheme(.dark)
        }
    }
}
