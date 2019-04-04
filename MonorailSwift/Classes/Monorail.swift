import Foundation

public protocol MonorailDebugOutput: class {
    func log(_ message: String)
}

public enum MonorailInteractionFilter {
    case whitelist([String])
    case blacklist([String])
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
    
    public static func writeLog(to fileName: String? = nil, directory: String? = nil, delegate: APIServiceWriterDelegate? = nil) -> URL? {
        Monorail.shared.writer = APIServiceWriter(delegate: delegate)
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
        TimeMachine.shared.travelTo(Monorail.shared.reader?.startTime)
    }
    
    public static func disableReader() {
        Monorail.shared.reader = nil
    }
    
    public static func readerReader() {
        Monorail.shared.reader?.resetInteractionsConsumedFlag()
    }
    
    public static let shared = Monorail()
}

extension Monorail: MonorailDebugOutput {}

extension Monorail: APIServiceInterceptor {
    func shouldSkip(_ request: URLRequest) -> Bool {
        return false
    }
    
    func intercept(_ request: URLRequest) -> (interceptResponse: Bool, URLResponse?, Data?) {
        if let reader = reader {
            if let (response, data, _) = reader.getResponseObject(for: request) {
                return (true, response, data)
            } else {
                return (true, nil, nil)
            }
        } else {
            return (false, nil, nil)
        }
    }
    
    func log(_ error: Error, request: URLRequest) {
        if isNotFiltered(request: request) {
            logger?.log(error)
        }
    }

    func log(_ request: URLRequest) {
        if isNotFiltered(request: request) {
            logger?.log(request)
        }
    }

    func log(_ response: URLResponse, data: Data?, request: URLRequest) {
        if isNotFiltered(request: request) {
            logger?.log(response, data: data)
        }
        
        writer?.log(request: request, response: response, data: data)
    }
    
    private func isNotFiltered(request: URLRequest) -> Bool {
        guard let urlString = request.url?.absoluteString else {
            return true
        }
        
        if case let .whitelist(whitelist)? = loggerFilter {
            return whitelist.first { urlString.hasPrefix($0) } != nil
        } else if case let .blacklist(blacklist)? = loggerFilter {
            return blacklist.first { urlString.hasPrefix($0) } == nil
        } else {
            return true
        }
    }
}


