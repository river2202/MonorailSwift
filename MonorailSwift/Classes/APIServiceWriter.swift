import Foundation

public protocol APIServiceWriterDelegate: class {
    func savingCosumerVariables(_ interaction: Interaction, writer: APIServiceWriter)
    func getInteractionId(path: String?, existingIds: [String]) -> String?
}

extension APIServiceWriterDelegate {
    func getInteractionId(path: String?, existingIds: [String]) -> String? {
        guard let path = path else {
            return nil
        }
        return URL(string: path)?.lastPathComponent
    }
}

let apiServiceBaseUrlKey = "baseUrl"
let apiServiceInteractionsKey = "interactions"
let apiServiceStartTimeKey = "startTime"
let apiServiceConsumerKey = "consumer"
let apiServiceProviderKey = "provider"
let apiServiceConsumerNotificationsKey = "notifications"

open class APIServiceWriter: APIServiceReader {

    private(set) var logFilePath: URL?
    private weak var delegate: APIServiceWriterDelegate?
    let defaultMonorailFileName = "Monorail"
    
    init(delegate: APIServiceWriterDelegate?) {
        super.init()
        self.delegate = delegate
    }
    
    
    func log(request: URLRequest?, uploadData: Data? = nil, response: URLResponse?, data: Data? = nil) {
        guard let request = request, logFilePath != nil else {
            return
        }
        
        let interaction = Interaction(request: request, uploadData: uploadData, response: response, data: data, baseUrl: consumerVariables[apiServiceBaseUrlKey] as? String, timeStamp: Date())
        
        delegate?.savingCosumerVariables(interaction, writer: self)
        interactions.append(interaction)
        save()
    }
    
    func log(request: URLRequest?, uploadData: Data? = nil, error: NSError?) {
        guard let request = request, logFilePath != nil else {
            return
        }
        
        let interaction = Interaction(request: request, uploadData: uploadData, error: error, baseUrl: consumerVariables[apiServiceBaseUrlKey] as? String, timeStamp: Date())
        
        delegate?.savingCosumerVariables(interaction, writer: self)
        interactions.append(interaction)
        save()
    }
    
    open func saveBaseUrl(_ baseUrl: String) {
        saveConsumerVariables(key: apiServiceBaseUrlKey, value: baseUrl)
    }
    
    open func saveProviderVariable(key: String, value: Any) {
        providerVariables[key] = value
    }
    
    open func saveConsumerVariables(key: String, value: Any) {
        consumerVariables[key] = value
    }
    
    open func saveNotification(userInfo: [AnyHashable: Any]) {
        guard let notification = userInfo as? [String: AnyObject] else {
            return
        }
        notifications.append(notification)
    }
    
    func startLogging(to fileName: String? = nil, directory: String? = nil) {
        reset()
        
        let monorailCacheDirectory: URL
        if let directory = directory {
           monorailCacheDirectory =  URL(fileURLWithPath: directory)
        } else {
            monorailCacheDirectory =  APIServiceWriter.monorailCacheDirectory
        }
        
        try? FileManager.default.createDirectory(at: monorailCacheDirectory, withIntermediateDirectories: true, attributes: nil)
        
        logFilePath = monorailCacheDirectory.appendingPathComponent("\(fileName ?? defaultMonorailFileName).json")
        startTime = Date()
    }
    
    func reset() {
        startTime = nil
        logFilePath = nil
        interactions.removeAll()
        notifications.removeAll()
        consumerVariables.removeAll()
        providerVariables.removeAll()
    }
    
    open func saveToDocumentDirectory(fileName: String) {
        let monorailDocumentDirectory: URL = APIServiceWriter.monorailDocumentDirectory
        try? FileManager.default.createDirectory(at: monorailDocumentDirectory, withIntermediateDirectories: true, attributes: nil)
        
        save(to: monorailDocumentDirectory.appendingPathComponent("\(fileName).json"))
    }
    
    open func save(to filePath: URL? = nil) {
        guard let logFilePath = filePath ?? logFilePath else {
            return
        }
        
        var payload: [String: Any] = [
            apiServiceInteractionsKey: interactions.map { $0.payload() }
        ]
        
        if let startTime = startTime {
            payload[apiServiceStartTimeKey] = startTime.asString(format: timeStampFormat)
        }
        
        if !notifications.isEmpty {
            consumerVariables[apiServiceConsumerNotificationsKey] = notifications
        }
        
        if !consumerVariables.isEmpty {
            payload[apiServiceConsumerKey] = consumerVariables
        }
        
        if !providerVariables.isEmpty {
            payload[apiServiceProviderKey] = providerVariables
        }
        
        updateInteractionId(updateOnlyNil: true)
        if let pretty = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
            let content = String(data: pretty, encoding: .utf8) {
            do {
                try content.write(to: logFilePath, atomically: true, encoding: .utf8)
            } catch {
                print("Unexpected error: \(error).")
            }
        }
    }
    
    private func updateInteractionId(updateOnlyNil: Bool = false) {
        var ids: [String] = []
        var missingId = interactions
        
        if updateOnlyNil {
            ids = interactions.compactMap({ $0.id })
            missingId = interactions.filter({ $0.id == nil })
        }
        
        for interaction in missingId {
            let id = getInteractionId(path: interaction.path, existingIds: ids)
            ids.append(id)
            interaction.id = id
        }
    }
    
    private func getInteractionId(path: String?, existingIds: [String]) -> String {
        if let candidateId = delegate?.getInteractionId(path: path, existingIds: existingIds), !candidateId.isEmpty {
            var index = 0
            var nextCandidateId = ""
            repeat {
                index += 1
                nextCandidateId = String(format: "%@_%02d", candidateId, index)
            } while existingIds.contains(nextCandidateId) && index < 100
            
            return nextCandidateId
        } else {
            return "\(existingIds.count + 1)"
        }
    }
}

extension APIServiceWriter {
    public static var monorailCacheDirectory: URL {
        let cacheDirectory: URL
        #if arch(i386) || arch(x86_64)
            if let simulatorHostHome = ProcessInfo().environment["SIMULATOR_HOST_HOME"] {
                cacheDirectory = URL(fileURLWithPath: simulatorHostHome).appendingPathComponent("Library/Caches/tools.monorail")
            } else {
                cacheDirectory = temporaryDirectory
            }
        #else
            cacheDirectory = temporaryDirectory
        #endif
        
        return cacheDirectory.appendingPathComponent("Monorail", isDirectory: true)
    }
    
    static private var temporaryDirectory: URL {
        if #available(iOS 10.0, *) {
            return FileManager.default.temporaryDirectory
        } else {
            return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        }
    }
    
    public static var monorailDocumentDirectory: URL = {
        var documentDirectory: URL
        
        if let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            documentDirectory = documentsPathURL
        } else {
            documentDirectory = temporaryDirectory
        }
        
        documentDirectory.appendPathComponent("Monorail")
        return documentDirectory
    }()
}
