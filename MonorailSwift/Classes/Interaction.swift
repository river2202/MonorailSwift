import Foundation

private let fileRefKey = "fileReference"
let timeStampFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
public typealias MaskFunction = (_ key: String, _ value: String) -> String
public func defaultMaskFunction(_: String, _: String) -> String {"****"}

open class Interaction {
    private let requestKey = "request"
    private let responseKey = "response"
    private let errorKey = "error"
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
    private(set) var error: NSError?
    
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
    
    private var delay: TimeInterval? {
        return timeElapsedEnabled ? timeElapsed : nil
    }
    
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
        self.error = template.error
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
        loadErrorJson(json[errorKey] as? [String: Any])
        
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
    
    init(request: URLRequest?,
         uploadData: Data? = nil,
         response: URLResponse? = nil,
         data: Data? = nil,
         error: NSError? = nil,
         baseUrl: String? = nil,
         timeStamp: Date? = nil,
         timeElapsed: TimeInterval? = nil,
         timeElapsedEnabled: Bool = false,
         id: String? = nil
    ) {
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
        
        self.error = error
        self.id = id
    }
    
    var requestHeader: [String: Any]? {
        return request[headersKey] as? [String: Any]
    }
    
    var requestBody: Any? {
        return request[bodyKey]
    }
    var responseBody: Any? {
        return response[bodyKey]
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
    
    private func loadErrorJson(_ json: [String: Any]?) {
        self.error = NSError.loadJson(json ?? nil)
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
    
    public func responseObjects() -> (HTTPURLResponse?, Data?, Error?, TimeInterval?) {
        guard let path = path, let url = URL(string: path), let statusCode = response[responseStatusKey] as? Int else {
            return (nil, nil, error, nil)
        }
        
        guard let httpURLResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: response[headersKey] as? [String: String]) else {
            return (nil, nil, error, delay)
        }
        
        var data: Data? = nil
        
        if let jsonObject = response[bodyKey] {
            data = data ?? (jsonObject as? String)?.data(using: .utf8)
            data = data ?? (try? JSONSerialization.data(withJSONObject: jsonObject, options: []))
        }
        
        data = data ?? (response[dataKey] as? String)?.fromBase64ToData()
        
        return (httpURLResponse, data, nil, delay)
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
        
        if let body = body {
            if let bodyContent = getBodyContent(body: body) {
                requestJson[bodyKey] = bodyContent
            } else {
                requestJson[dataKey] = body.base64EncodedString()
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
        
        if let body = body {
            if let bodyContent = getBodyContent(body: body) {
                response[bodyKey] = bodyContent
            } else {
                response[dataKey] = body.base64EncodedString()
            }
        }
    }
    
    private func getBodyContent(body: Data) -> Any? {
        return (try? JSONSerialization.jsonObject(with: body, options: .mutableContainers)) ?? String(data: body, encoding: .utf8)
    }
    
    public func payload() -> [String: Any] {
        var payload: [String: Any] = [
            requestKey: request
        ]
        
        if let id = id {
            payload[idKey] = id
        }
        
        if !response.isEmpty {
            payload[responseKey] = response
        }
        
        if let errorPayload = error?.payload() {
            payload[errorKey] = errorPayload
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
    
    func maskSecrets(secretKeys: [String], mask: MaskFunction) -> Void {
        request.maskSecrets(keys: secretKeys, mask: mask)
        response.maskSecrets(keys: secretKeys, mask: mask)
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
                return currentDict as! Value
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
    
    mutating func maskSecrets(keys: [String], mask: MaskFunction) -> Void {
        for (key, value) in self {
            if keys.contains(key), let value = value as? String {
                self[key] = mask(key, value)
            } else if var value = value as? [String: Any] {
                value.maskSecrets(keys: keys, mask: mask)
                self[key] = value
            }
        }
    }
    
    func masked(keys: [String], mask: MaskFunction) -> Dictionary {
        var maskedDictionary = self
        maskedDictionary.maskSecrets(keys: keys, mask: mask)
        return maskedDictionary
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

private let errorCodeKey = "code"
private let errorDomainKey = "domain"
private let errorUserInfoKey = "userinfo"
extension NSError {
    func payload() -> [String: Any] {
        return [
            errorCodeKey: code,
            errorDomainKey: domain,
//            errorUserInfoKey: userInfo
        ]
    }
    
    static func loadJson(_ json: [String: Any]?) -> NSError? {
        guard let json = json,
            let code = json[errorCodeKey] as? Int,
            let domain = json[errorDomainKey] as? String else {
                return nil
        }
        
        return NSError(domain: domain, code: code, userInfo: json[errorUserInfoKey] as? [String : Any])
    }
}


