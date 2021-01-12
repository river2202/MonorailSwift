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
    var sequence = 0
    
    private init() {
        URLInterceptor.enable(interceptor: self)
    }
    
    public static func enableLogger(output: MonorailDebugOutput = Monorail.shared, filter: MonorailInteractionFilter? = nil, resetSequence: Bool = true, secretKeys: [String] = secretsKeys, secretMask: @escaping MaskFunction = defaultMaskFunction) {
        Monorail.shared.logger = APIServiceLogger(output: output, secretKeys: secretKeys, secretMask: secretMask)
        Monorail.shared.loggerFilter = filter
        if resetSequence {
            Monorail.shared.resetSequenceId()
        }
    }
    
    public static func disableLogger() {
        Monorail.shared.logger = nil
    }
    
    @discardableResult
    public static func writeLog(to fileName: String? = nil, directory: String? = nil, delegate: APIServiceWriterDelegate? = nil, secretKeys: [String] = secretsKeys, secretMask: @escaping MaskFunction = defaultMaskFunction) -> URL? {
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
    
    public static func enableReader(from filePath: URL, externalFileRootPath: String? = nil, delegate: APIServiceReaderDelegate? = nil, output: MonorailDebugOutput = Monorail.shared, mode: APIServiceReader.Mode = .all) {
        enableReader(from: [filePath], externalFileRootPath: externalFileRootPath, delegate: delegate, output: output, mode: mode)
    }
    
    public static func enableReader(from files: [URL], externalFileRootPath: String? = nil, delegate: APIServiceReaderDelegate? = nil, output: MonorailDebugOutput = Monorail.shared, mode: APIServiceReader.Mode = .all) {
        Monorail.shared.reader = APIServiceReader(files: files, delegate: delegate, output: output, mode: mode)
        TimeMachine.shared.travel(to: Monorail.shared.reader?.startTime)
    }
    
    public static func disableReader() {
        Monorail.shared.reader = nil
    }
    
    public static func resetReader() {
        Monorail.shared.reader?.resetInteractionsConsumedFlag()
    }
    
    public func resetSequenceId() {
        sequence = 0
    }
    
    public static let shared = Monorail()
    public static var secretsKeys = ["Authorization"]
}

extension Monorail: MonorailDebugOutput {}

extension Monorail: APIServiceInterceptor {
    public func shouldSkip(_ request: URLRequest) -> Bool {
        return false
    }
    
    public func intercept(_ request: URLRequest) -> (interceptResponse: Bool, URLResponse?, Data?, Error?, TimeInterval?) {
        return reader?.getResponseObject(for: request) ?? (false, nil, nil, nil, nil)
    }
    
    public func log(_ error: Error, request: URLRequest, timeElapsed: TimeInterval? = nil, id: String? = nil) {
        if !request.filtered(by: loggerFilter) {
            logger?.log(error, timeElapsed: timeElapsed, id: id)
        }
        
        writer?.log(request: request, error: error as NSError)
    }

    public func log(_ request: URLRequest) -> String? {
        if !request.filtered(by: loggerFilter) {
            sequence += 1
            let id = "\(sequence)"
            logger?.log(request, id: id)
            return id
        }
        
        return nil
    }

    public func log(_ response: URLResponse, data: Data?, request: URLRequest, timeElapsed: TimeInterval? = nil, id: String? = nil) {
        if !request.filtered(by: loggerFilter) {
            logger?.log(response, data: data, request: request, timeElapsed: timeElapsed, id: id)
        }
        
        writer?.log(request: request, response: response, data: data,  id: id, timeElapsed: timeElapsed)
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

