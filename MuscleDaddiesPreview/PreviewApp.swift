import SwiftUI

@main
struct MuscleDaddiesPreviewApp: App {
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
