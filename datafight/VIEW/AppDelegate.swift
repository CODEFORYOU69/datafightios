import UIKit
import FirebaseCore
import Firebase
import FirebaseAuth
import FirebaseStorage

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
#if DEBUG
let isRunningTests = ProcessInfo.processInfo.environment["IS_TESTING"] == "YES"
#else
let isRunningTests = false
#endif

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        print("Firebase App configured")

        if isRunningTests {
            // Configuration de l'émulateur pour les tests
            configureEmulators()
        } else {
            // Configuration normale pour le développement et la production
            configureFirebaseForProduction()
        }
        
        return true
    }

    func configureEmulators() {
        // Initialize Firestore emulator settings
        let settings = FirestoreSettings()
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        
        Firestore.firestore().settings = settings
        print("Firestore emulator settings applied")

        // Configure Authentication emulator
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        print("Auth emulator configured")

        // Configure Storage emulator
        Storage.storage().useEmulator(withHost: "localhost", port: 9199)
        print("Storage emulator configured")

        print("All Firebase Emulators configured for testing")

        // Test Firestore connection
        testFirestoreConnection()
    }

    func configureFirebaseForProduction() {
        // Ici, vous pouvez ajouter toute configuration spécifique à la production si nécessaire
        print("Firebase configured for production")
        
        // Test Firestore connection
        testFirestoreConnection()
    }

    func testFirestoreConnection() {
        Firestore.firestore().collection("test").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Firestore connection failed: \(error.localizedDescription)")
            } else {
                print("Firestore connection successful. Documents count: \(querySnapshot?.documents.count ?? 0)")
            }
        }
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
