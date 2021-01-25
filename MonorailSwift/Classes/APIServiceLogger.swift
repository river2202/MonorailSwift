import Foundation

public final class APIServiceLogger {
    private weak var output: MonorailDebugOutput?
    var maxPrintoutDataCount = 1024
    private let secretKeys: [String]
    private let secretMask: MaskFunction
    private let logHeader: [String]?

    init(output: MonorailDebugOutput, secretKeys: [String], secretMask: @escaping MaskFunction, logHeader: [String]?) {
        self.output = output
        self.secretKeys = secretKeys
        self.secretMask = secretMask
        self.logHeader = logHeader
    }
    
    private let divider = "---------------------\n"
    
    public func log(_ error: Error, timeElapsed: TimeInterval? = nil, id: String? = nil) {
        var logString = divider
        defer { output?.log(logString) }
        
        let e = error as NSError
        logString += "Error: \(e.code) \(e.localizedDescription)\n"
        
        if let reason = e.localizedFailureReason {
            logString += "Reason: \(reason)\n"
        }
        
        if let suggestion = e.localizedRecoverySuggestion {
            logString += "Suggestion: \(suggestion)\n"
        }
    }
    
    public func log(_ request: URLRequest, uploadData: Data? = nil, timeElapsed: TimeInterval? = nil, id: String? = nil) {
        logRequest(url: request.url, method: request.httpMethod, header: request.allHTTPHeaderFields as [String : AnyObject]?, data: uploadData ?? request.getHttpBodyData(), id: id)
    }
    
    public func logRequest(url: URL?, method: String?, header: [String: Any]?, data: Data?, id: String? = nil) {
        var logString = divider
        defer { output?.log(logString) }
        
        let maskHeader = header?.masked(keys: secretKeys, mask: secretMask) ?? [:]
        logString += "Request: \(method ?? "?") \(url?.absoluteString ?? "nil")\n"
        logString += Self.getLog(id: id)
        logString += getHeadersString(maskHeader)
        logString += getDataString(data)
    }
    
    public func log(_ response: URLResponse?, data: Data? = nil, request: URLRequest? = nil, timeElapsed: TimeInterval? = nil, id: String? = nil) {
        var logString = divider
        defer { output?.log(logString) }

        logString += "Response: \(request?.httpMethod ?? "?") \(response?.url?.absoluteString ?? "nil")\n"
        logString += Self.getLog(id: id, timeElapsed: timeElapsed)
        
        if let httpResponse = response as? HTTPURLResponse {
            let localisedStatus = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode).capitalized
            logString += "Status: \(httpResponse.statusCode) - \(localisedStatus)\n"
        }
        
        if let headers = (response as? HTTPURLResponse)?.allHeaderFields as? [String: AnyObject] {
            logString += getHeadersString(headers)
        }
        
        logString += getDataString(data)
    }
    
    static func getLog(id: String? = nil, timeElapsed: TimeInterval? = nil) -> String {
        return [id?.add(prefix: "SequenceId: ", surfix: "\n"), timeElapsed?.description.add(prefix: "TimeElapsed: ", surfix: "s\n")].compactMap { $0 }.joined(separator: "")
    }
    
    private func getDataString(_ data: Data?) -> String {
        var logString = ""
        
        guard let data = data else {
            return logString
        }
        
        do {
            var json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            
            if let jsonDict = json as? [String: Any] {
                json = jsonDict.masked(keys: secretKeys, mask: secretMask)
            }
            
            let pretty = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            if let string = String(data: pretty, encoding:.utf8) {
                logString += "JSON: \(string)\n"
            }
        } catch {
            if data.count > 0, data.count < maxPrintoutDataCount, let string = String(data: data, encoding: .utf8), !string.isEmpty {
                logString += "UTF8: \"\(string)\"\n"
            } else if data.count > 0 {
                logString += "Data: \(data.debugDescription)\n"
            }
        }
        
        return logString
    }
    
    private func getHeadersString(_ headers: [String: Any]) -> String {
        var headerString = ""
        
        headers.forEach { key, value in
            if self.logHeader?.contains(key) ?? true {
                headerString += "  \(key) : \(value)\n"
            }
        }
        
        return headerString.isEmpty ? "" : "Headers: [\n" + headerString + "]\n"
    }
}

extension URLRequest {
    func getHttpBodyData() -> Data? {
        if let httpBody = httpBody {
            return httpBody
        } else if let req = (self as NSURLRequest).mutableCopy() as? NSMutableURLRequest, let httpBodyStream = req.httpBodyStream {
            
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            httpBodyStream.open()
            defer { httpBodyStream.close() }
            while httpBodyStream.hasBytesAvailable {
                let length = httpBodyStream.read(&buffer, maxLength: 4096)
                if length == 0 {
                    break
                } else {
                    data.append(&buffer, count: length)
                }
            }
            return data
        } else {
            return nil
        }
    }
}

extension String {
    
    func add(prefix: String? = nil, surfix: String? = nil) -> String {
        return [prefix, self, surfix].compactMap { $0 }.joined(separator: "")
    }
}
