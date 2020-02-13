import Foundation

public final class APIServiceLogger {
    private weak var output: MonorailDebugOutput?
    var maxPrintoutDataCount = 1024
    
    init(output: MonorailDebugOutput) {
        self.output = output
    }
    
    private let divider = "---------------------\n"
    
    public func log(_ error: Error) {
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
    
    public func log(_ request: URLRequest, uploadData: Data? = nil) {
        logRequest(url: request.url, method: request.httpMethod, header: request.allHTTPHeaderFields as [String : AnyObject]?, data: uploadData ?? request.getHttpBodyData())
    }
    
    public func logRequest(url: URL?, method: String?, header: [String: AnyObject]?, data: Data? ) {
        var logString = divider
        defer { output?.log(logString) }
        
        logString += "Request: \(method ?? "?") \(url?.absoluteString ?? "nil")\n"
        logString += getHeadersString(header ?? [:])
        logString += getDataString(data)
    }
    
    public func log(_ response: URLResponse?, data: Data? = nil) {
        var logString = divider
        defer { output?.log(logString) }

        logString += "Response: \(response?.url?.absoluteString ?? "nil")\n"
        
        if let httpResponse = response as? HTTPURLResponse {
            let localisedStatus = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode).capitalized
            logString += "Status: \(httpResponse.statusCode) - \(localisedStatus)\n"
        }
        
        if let headers = (response as? HTTPURLResponse)?.allHeaderFields as? [String: AnyObject] {
            logString += getHeadersString(headers)
        }
        
        logString += getDataString(data)
    }
    
    private func getDataString(_ data: Data?) -> String {
        var logString = ""
        
        guard let data = data else {
            return logString
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
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
    
    private func getHeadersString(_ headers: [String: AnyObject]) -> String {
        var logString = "Headers: [\n"
        for (key, value) in headers {
            logString += "  \(key) : \(value)\n"
        }
        logString += "]\n"
        return logString
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

