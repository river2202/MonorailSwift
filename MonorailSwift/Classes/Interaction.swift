import Foundation

private let fileRefKey = "fileReference"
let timeStampFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

open class Interaction {
    private let requestKey = "request"
    private let responseKey = "response"
    private let headersKey = "headers"
    private let bodyKey = "body"
    private let dataKey = "data"
    private let methodKey = "method"
    private let pathKey = "path"
    
    private let responseStatusKey = "status"
    private let idKey = "id"
    static let idRefKey = "idReference"
    private let timeStampKey = "timeStamp"
    private let timeElapsedKey = "timeElapsed"
    private let timeElapsedEnabledKey = "timeElapsedEnabled"
    
    private(set) var request: [String: Any] = [:]
    private(set) var response: [String: Any] = [:]
    
    public var baseUrl: String?
    public var path: String?
    public var method: String?
    
    public var fileName: String?
    public var id: String?
    
    private(set) var consumerVariables: [String: Any] = [:]
    private(set) var providerVariables: [String: Any] = [:]
    
    public private(set) var timeStamp: Date?
    private(set) var timeElapsed: TimeInterval?
    private(set) var timeElapsedEnabled: Bool = false
    
    // temp variables
    var consumed = false
    
    func saveProviderVariable(key: String, value: Any) {
        providerVariables[key] = value
    }
    
    func getProviderVariable(key: String) -> Any? {
        return providerVariables[key]
    }
    
    func saveConsumerVariables(key: String, value: Any) {
        consumerVariables[key] = value
    }
    
    func getConsumerVariables(key: String) -> Any? {
        return consumerVariables[key]
    }
    
    init(template: Interaction) {
        self.request = template.request
        self.response = template.response
        self.baseUrl = template.baseUrl
        self.path = template.path
        self.method = template.method
        self.fileName = template.fileName
        self.id = template.id
        self.consumerVariables = template.consumerVariables
        self.providerVariables = template.providerVariables
        self.timeStamp = template.timeStamp
        self.timeElapsed = template.timeElapsed
        self.timeElapsedEnabled = template.timeElapsedEnabled
    }
    
    init(json: [String: Any], baseUrl: String? = nil, fileName: String? = nil, externalFileRootPath: String? = nil) {
        self.baseUrl = baseUrl
        self.fileName = fileName
        
        loadJson(json, externalFileRootPath: externalFileRootPath)
    }
    
    func loadJson(_ json: [String: Any], externalFileRootPath: String? = nil) {
        
        if let externalFilePath = json[fileRefKey] as? String,
            let externalJson = loadJsonFromFile(externalFilePath, externalFileRootPath: externalFileRootPath) {
            loadJson(externalJson, externalFileRootPath: externalFileRootPath)
        }
        
        loadRequestJson(json[requestKey] as? [String: Any])
        loadResponseJson(json[responseKey] as? [String: Any], externalFileRootPath: externalFileRootPath)
        
        if let consumerVariables = json[apiServiceConsumerKey] as? [String: Any] {
            self.consumerVariables.deepMerge(consumerVariables)
        }
        
        if let providerVariables = json[apiServiceProviderKey] as? [String: Any] {
            self.providerVariables.deepMerge(providerVariables)
        }
        
        id = json[idKey] as? String
        if let timeStamp = (json[timeStampKey] as? String)?.date(timeStampFormat) {
            self.timeStamp = timeStamp
        }
        timeElapsed = json[timeElapsedKey] as? TimeInterval
        timeElapsedEnabled = (json[timeElapsedEnabledKey] as? Bool) ?? timeElapsedEnabled
    }
    
    init(request: URLRequest?, uploadData: Data? = nil, response: URLResponse?, data: Data? = nil, baseUrl: String? = nil, timeStamp: Date? = nil, timeElapsed: TimeInterval? = nil, timeElapsedEnabled: Bool = false) {
        self.baseUrl = baseUrl
        self.timeStamp = timeStamp
        self.timeElapsed = timeElapsed
        self.timeElapsedEnabled = timeElapsedEnabled
        if let request = request, let url = request.url?.absoluteString {
            setRequest(method: request.httpMethod ?? "GET", path: url, headers: request.allHTTPHeaderFields, body: request.getHttpBodyData(), uploadData: uploadData)
        }
        
        if let response = response as? HTTPURLResponse {
            setRespondWith(status: response.statusCode, headers: response.allHeaderFields as? [String: Any], body: data)
        }
    }
    
    var requestHeader: [String: Any]? {
        return request[headersKey] as? [String: Any]
    }
    
    var requestBody: [String: Any]? {
        return request[bodyKey] as? [String: Any]
    }
    var responseBody: [String: Any]? {
        return response[bodyKey] as? [String: Any]
    }
    
    var responseHeader: [String: Any]? {
        return response[headersKey] as? [String: Any]
    }
    
    private func loadRequestJson(_ json: [String: Any]?) {
        if let request = json {
            self.request.deepMerge(request)
            path = request[pathKey] as? String
            if let path = path {
                if let baseUrl = baseUrl, path.hasPrefix(baseUrl) {
                    self.path = String(path[baseUrl.endIndex...])
                    self.request[pathKey] = path
                } else {
                    let url = URL(string: path)
                    if let host = url?.host, let hostRange = path.range(of: host) {
                        self.baseUrl = String(path[path.startIndex..<hostRange.upperBound])
                        self.path = String(path[hostRange.upperBound...])
                        self.request[pathKey] = path
                    } else {
                        self.path = path
                        self.request[pathKey] = path
                    }
                }
            }
            method = request[methodKey] as? String
        }
    }
    
    private func loadResponseJson(_ json: [String: Any]?, externalFileRootPath: String? = nil) {
        guard let json = json else {
            return
        }
        
        if let externalFilePath = json[fileRefKey] as? String,
            let externalJson = loadJsonFromFile(externalFilePath, externalFileRootPath: externalFileRootPath) {
            response.deepMerge(externalJson)
        }
        
        response.deepMerge(json)
    }
    
    func matchReqest(_ urlRequest: URLRequest) -> Bool {
        guard let method = method, let path = path, let requestUrl = urlRequest.url?.absoluteString else {
            return false
        }
        
        return method == urlRequest.httpMethod && requestUrl.hasSuffix(path)
    }
    
    func matchReqest(_ method: String?, path: String?) -> Bool {
        guard let path = path, let pactPath = self.path else {
            return false
        }
        
        return method == self.method && path.hasSuffix(pactPath)
    }
    
    public func responseObjects() -> (HTTPURLResponse, Data?, Error?)? {
        guard let path = path, let url = URL(string: path), let statusCode = response[responseStatusKey] as? Int else {
            return nil
        }
        
        guard let httpURLResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: response[headersKey] as? [String: String]) else {
            return nil
        }
        
        let jsonObject = response[bodyKey] as? [String: Any]
        var data: Data? = nil
        do {
            if let jsonObject = jsonObject {
                data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            }
        } catch {
            data = nil
        }
        
        if data == nil {
            data = (response[dataKey] as? String)?.fromBase64ToData()
        }
        
        return (httpURLResponse, data, nil)
    }
    
    private func setRequest(method: String,
                            path: String,
                            headers: [String: String]? = nil,
                            body: Data? = nil,
                            uploadData: Data? = nil) {
        var requestJson: [String: Any] = [methodKey: method, pathKey: path]
        if let headersValue = headers, !headersValue.isEmpty {
            requestJson[headersKey] = headersValue
        }
        if let bodyValue = body {
            do {
                let json = try JSONSerialization.jsonObject(with: bodyValue, options: .mutableContainers)
                requestJson[bodyKey] = json
            } catch {
                requestJson[bodyKey] = bodyValue.base64EncodedString()
            }
        }
        
        if let uploadData = uploadData {
            requestJson[dataKey] = uploadData.base64EncodedString()
        }
        
        loadRequestJson(requestJson)
    }
    
    private func setRespondWith(status: Int,
                                headers: [String: Any]? = nil,
                                body: Data? = nil) {
        response = [responseStatusKey: status]
        if let headersValue = headers {
            response[headersKey] = headersValue
        }
        
        if let bodyValue = body {
            do {
                let json = try JSONSerialization.jsonObject(with: bodyValue, options: .mutableContainers)
                response[bodyKey] = json
            } catch {
                response[dataKey] = bodyValue.base64EncodedString()
            }
        }
    }
    
    public func payload() -> [String: Any] {
        var payload: [String: Any] = [requestKey: request, responseKey: response]
        
        if let id = id {
            payload[idKey] = id
        }
        
        if !consumerVariables.isEmpty {
            payload[apiServiceConsumerKey] = consumerVariables
        }
        
        if !providerVariables.isEmpty {
            payload[apiServiceProviderKey] = providerVariables
        }
        
        if let timeStamp = timeStamp {
            payload[timeStampKey] = timeStamp.asString(format: timeStampFormat)
        }
        
        if let timeElapsed = timeElapsed {
            payload[timeElapsedKey] = timeElapsed
        }
        
        return payload
    }
}

private func loadJsonFromFile(_ filePath: String?, externalFileRootPath: String? = nil) -> [String: Any]? {
    if let filePath = filePath,
        let externalFileRootPath = externalFileRootPath,
        let data = try? Data(contentsOf: URL(fileURLWithPath: externalFileRootPath).appendingPathComponent(filePath)),
        let externalJson = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
        return externalJson
    }
    
    return nil
}

extension Dictionary {
    mutating func deepMerge(_ dict: Dictionary) {
        merge(dict) { (current, new) in
            if var currentDict = current as? Dictionary, let newDict = new as? Dictionary {
                currentDict.deepMerge(newDict)
                return current
            }
            return new
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    func loadFileRef(externalFileRootPath: String? = nil) -> Dictionary {
        if let externalFilePath = self[fileRefKey] as? String,
            var externalJson = loadJsonFromFile(externalFilePath, externalFileRootPath: externalFileRootPath) {
            externalJson.deepMerge(self)
            return externalJson
        }

        return self
    }
}

extension String {
    func fromBase64ToData() -> Data? {
        let rem = self.count % 4
        
        var ending = ""
        if rem > 0 {
            let amount = 4 - rem
            ending = String(repeating: "=", count: amount)
        }
        
        let base64 = self.replacingOccurrences(of: "-", with: "+", options: NSString.CompareOptions(rawValue: 0), range: nil)
            .replacingOccurrences(of: "_", with: "/", options: NSString.CompareOptions(rawValue: 0), range: nil) + ending
        
        return Data(base64Encoded: base64, options: NSData.Base64DecodingOptions(rawValue: 0))
    }

    func date(_ format: String, altFormat: String? = "") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        if let date = dateFormatter.date(from: self) {
            return date
        } else {
            dateFormatter.dateFormat = altFormat
            return dateFormatter.date(from: self)
        }
    }
}

extension Date {
    func asString(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
