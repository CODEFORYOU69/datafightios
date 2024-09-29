import Firebase
import FirebaseFirestore
import FirebaseStorage
import UIKit
import FirebaseAuth
import Network

class FirebaseService {
    static let shared = FirebaseService()
    let db: Firestore
    let storage: StorageReference
    let monitor = NWPathMonitor()
    var isConnected = true

    static func configure() {
        if ProcessInfo.processInfo.environment["IS_TESTING"] == "YES" {
            print("Configuring Firebase for testing environment")
            let settings = FirestoreSettings()
            settings.host = "localhost:8080"
            settings.cacheSettings = MemoryCacheSettings()
            settings.isSSLEnabled = false
            
            Firestore.firestore().settings = settings
            
            Auth.auth().useEmulator(withHost: "localhost", port: 9099)
            Storage.storage().useEmulator(withHost: "localhost", port: 9199)
        } else {
            print("Configuring Firebase for production environment")
        }
        
        FirebaseApp.configure()
    }

    private init() {
        self.db = Firestore.firestore()
        self.storage = Storage.storage().reference()
        setupNetworkMonitoring()
    }

    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            print("Network connection status: \(self.isConnected ? "Connected" : "Disconnected")")
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    func getCurrentUserID() -> Result<String, Error> {
        if let uid = Auth.auth().currentUser?.uid {
            return .success(uid)
        } else {
            return .failure(NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
        }
    }
}

// Extensions pour l'encodage/décodage des objets
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "FirebaseService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to convert object to dictionary"])
        }
        return dictionary
    }
}
