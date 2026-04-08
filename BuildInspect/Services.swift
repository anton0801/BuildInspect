import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UserNotifications
import Supabase

protocol StorageService {
    func saveTracking(_ data: [String: String])
    func saveNavigation(_ data: [String: String])
    func saveEndpoint(_ url: String)
    func saveMode(_ mode: String)
    func savePermissions(_ permission: RequestContext.PermissionData)
    func markLaunched()
    func loadState() -> StoredState
}

struct StoredState {
    var tracking: [String: String]
    var navigation: [String: String]
    var endpoint: String?
    var mode: String?
    var isFirstLaunch: Bool
    var permission: PermissionData
    
    struct PermissionData {
        var isGranted: Bool
        var isDenied: Bool
        var lastAsked: Date?
    }
}

protocol ValidationService {
    func validate() async throws -> Bool
}

final class SupabaseValidationService: ValidationService {
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://zhzcrgyzwmlramyrtkak.supabase.co")!,
            supabaseKey: "sb_publishable_u-DMM7q3zEs91LRBjKe1wQ_X4hRs_UE"
        )
    }
    
    func validate() async throws -> Bool {
        do {
            let response: [ValidationRow] = try await client
                .from("validation")
                .select()
                .limit(1)
                .execute()
                .value
            
            guard let firstRow = response.first else {
                return false
            }
            
            return firstRow.isValid
        } catch {
            print("🏗️ [BuildInspect] Validation error: \(error)")
            throw error
        }
    }
}

struct ValidationRow: Codable {
    let id: Int?
    let isValid: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isValid = "is_valid"
        case createdAt = "created_at"
    }
}

protocol NetworkService {
    func fetchAttribution(deviceID: String) async throws -> [String: Any]
    func fetchEndpoint(tracking: [String: Any]) async throws -> String
}

final class HTTPNetworkService: NetworkService {
    private let client: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.client = URLSession(configuration: config)
    }
    
    func fetchAttribution(deviceID: String) async throws -> [String: Any] {
        var builder = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(BuildInspectConfig.appID)")
        builder?.queryItems = [
            URLQueryItem(name: "devkey", value: BuildInspectConfig.devKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = builder?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await client.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NetworkError.decodingFailed
        }
        
        return json
    }
    
    private var userAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func fetchEndpoint(tracking: [String: Any]) async throws -> String {
        guard let url = URL(string: "https://builldinspect.com/config.php") else {
            throw NetworkError.invalidURL
        }
        
        var payload: [String: Any] = tracking
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(BuildInspectConfig.appID)"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        var lastError: Error?
        let retries: [Double] = [26.0, 52.0, 104.0]
        
        for (index, delay) in retries.enumerated() {
            do {
                let (data, response) = try await client.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.requestFailed
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let success = json["ok"] as? Bool, success,
                          let endpoint = json["url"] as? String else {
                        throw NetworkError.decodingFailed
                    }
                    return endpoint
                } else if httpResponse.statusCode == 429 {
                    try await Task.sleep(nanoseconds: UInt64(delay * Double(index + 1) * 1_000_000_000))
                    continue
                } else {
                    throw NetworkError.requestFailed
                }
            } catch {
                lastError = error
                if index < retries.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NetworkError.requestFailed
    }
}


protocol NotificationService {
    func requestPermission(completion: @escaping (Bool) -> Void)
    func registerForPush()
}


enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
}
