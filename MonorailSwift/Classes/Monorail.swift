import Foundation

public protocol MonorailDebugOutput: class {
    func log(_ message: String)
}

public enum MonorailInteractionFilter {
    case whitelist([String])
    case blacklist([String])
    
    func isFiltered(_ value: String?) -> Bool {
        guard let value = value else {
            return false
        }
        
        switch self {
        case .whitelist(let whitelist):
            return whitelist.first { value.contains(wildcardString: $0) } == nil
        case .blacklist(let blacklist):
            return blacklist.first { value.contains(wildcardString: $0) } != nil
        }
    }
}

extension String {
    func contains(regexString: String) -> Bool {
        if let _ = self.range(of: regexString,
            options: .regularExpression) {
            return true
        } else {
            return contains(regexString)
        }
    }
    
    func wildcard(pattern: String) -> Bool {
        let pred = NSPredicate(format: "self LIKE %@", pattern)
        return !NSArray(object: self).filtered(using: pred).isEmpty
    }
    
    func contains(wildcardString: String) -> Bool {
        if wildcard(pattern: wildcardString) {
            return true
        } else {
            return contains(wildcardString)
        }
    }
}

extension MonorailDebugOutput {
    public func log(_ message: String) { print(message) }
}

public enum MonorailError: String, Error {
    case noResponseFound
}

extension MonorailError : LocalizedError {
    public var errorDescription: String? {
        return "\(self)"
    }
}

open class Monorail {
    open private(set) var logger: APIServiceLogger?
    open private(set) var writer: APIServiceWriter?
    open private(set) var reader: APIServiceReader?
    open var bypassSslCheck: Bool = true
    var loggerFilter: MonorailInteractionFilter?
    
    init() {
        URLInterceptor.enable(interceptor: self)
    }
    
    public static func enableLogger(output: MonorailDebugOutput = Monorail.shared, filter: MonorailInteractionFilter? = nil) {
        Monorail.shared.logger = APIServiceLogger(output: output)
        Monorail.shared.loggerFilter = filter
    }
    
    public static func disableLogger() {
        Monorail.shared.logger = nil
    }
    
    @discardableResult
    public static func writeLog(to fileName: String? = nil, directory: String? = nil, delegate: APIServiceWriterDelegate? = nil, secretKeys: [String] = secretsKeys, secretMask: @escaping MaskFunction = {(_, _) in "****"}) -> URL? {
        Monorail.shared.writer = APIServiceWriter(delegate: delegate, secretKeys: secretKeys, secretMask: secretMask)
        Monorail.shared.writer?.startLogging(to: fileName, directory: directory)
        return Monorail.shared.writer?.logFilePath
    }
    
    public static func getLogFileUrl() -> URL? {
        return Monorail.shared.writer?.logFilePath
    }
    
    public static func stopWriteLog() {
        Monorail.shared.writer = nil
    }
    
    public static func enableReader(from filePath: URL, externalFileRootPath: String? = nil, delegate: APIServiceReaderDelegate? = nil, output: MonorailDebugOutput = Monorail.shared) {
        enableReader(from: [filePath], externalFileRootPath: externalFileRootPath, delegate: delegate, output: output)
    }
    
    public static func enableReader(from files: [URL], externalFileRootPath: String? = nil, delegate: APIServiceReaderDelegate? = nil, output: MonorailDebugOutput = Monorail.shared) {
        Monorail.shared.reader = APIServiceReader(files: files, delegate: delegate, output: output)
        TimeMachine.shared.travel(to: Monorail.shared.reader?.startTime)
    }
    
    public static func disableReader() {
        Monorail.shared.reader = nil
    }
    
    public static func resetReader() {
        Monorail.shared.reader?.resetInteractionsConsumedFlag()
    }
    
    public static let shared = Monorail()
    public static var secretsKeys = ["Authorization"]
}

extension Monorail: MonorailDebugOutput {}

extension Monorail: APIServiceInterceptor {
    func shouldSkip(_ request: URLRequest) -> Bool {
        return false
    }
    
    func intercept(_ request: URLRequest) -> (interceptResponse: Bool, URLResponse?, Data?, Error?, TimeInterval?) {
        if let reader = reader {
            if let (response, data, error, delay) = reader.getResponseObject(for: request) {
                return (true, response, data, error, delay)
            } else {
                return (true, nil, nil, nil, nil)
            }
        } else {
            return (false, nil, nil, nil, nil)
        }
    }
    
    func log(_ error: Error, request: URLRequest) {
        if !request.filtered(by: loggerFilter) {
            logger?.log(error)
        }
        
        writer?.log(request: request, error: error as NSError)
    }

    func log(_ request: URLRequest) {
        if !request.filtered(by: loggerFilter) {
            logger?.log(request)
        }
    }

    func log(_ response: URLResponse, data: Data?, request: URLRequest) {
        if !request.filtered(by: loggerFilter) {
            logger?.log(response, data: data)
        }
        
        writer?.log(request: request, response: response, data: data)
    }
    
}

extension URLRequest {
    func filtered(by filter: MonorailInteractionFilter?) -> Bool {
        return filter?.isFiltered(url?.absoluteString) ?? false
    }
}

extension Monorail {
    public static var isReaderEnabled: Bool {
        return shared.reader != nil
    }
    
    public static var isWriterEnabled: Bool {
        return shared.writer != nil
    }
}

