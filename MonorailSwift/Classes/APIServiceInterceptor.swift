import Foundation

protocol APIServiceInterceptor {
    func shouldSkip(_ request: URLRequest) -> Bool
    func intercept(_ request: URLRequest) -> (interceptResponse: Bool, URLResponse?, Data?, Error?, TimeInterval?)
    
    func log(_ error: Error, request: URLRequest, timeElapsed: TimeInterval?, id: String?)
    func log(_ request: URLRequest) -> String?
    func log(_ response: URLResponse, data: Data?, request: URLRequest, timeElapsed: TimeInterval?, id: String?)
    
    var cacheStoragePolicy: URLCache.StoragePolicy { get }
    var bypassSslCheck: Bool { get }
}

extension APIServiceInterceptor {
    func shouldSkip(_ request: URLRequest) -> Bool { return false }
    var cacheStoragePolicy: URLCache.StoragePolicy { return .allowed }
    var bypassSslCheck: Bool { return true }
}

class URLInterceptor: URLProtocol, URLSessionDelegate {
    fileprivate static var interceptor: APIServiceInterceptor?
    
    static func enable(interceptor: APIServiceInterceptor) {
        self.interceptor = interceptor
        URLSessionConfiguration.enableInterceptor()
    }
    
    private static let requestHandledKey = "requestHandledKey"
    private static let requestTimeKey = "requestTimeKey"
    
    private var newRequest: NSMutableURLRequest?
    
    public override class func canInit(with request: URLRequest) -> Bool {
        guard let interceptor = interceptor,
            self.property(forKey: requestHandledKey, in: request) == nil,
            !interceptor.shouldSkip(request)
            else {
            return false
        }
        return true
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to: b)
    }
    
    public override func startLoading() {
        guard let interceptor = URLInterceptor.interceptor else { return }
        
        let id = interceptor.log(request)
        let startTime = Date()
        if case (true, let response, let data, let error, let delay) = interceptor.intercept(request) {
            guard let response = response else {
                let error = error ?? MonorailError.noResponseFound
                interceptor.log(error, request: self.request, timeElapsed: startTime.timeElapsedSinceNow, id: id)
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + (delay ?? 0)) {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: interceptor.cacheStoragePolicy)
                if let data = data {
                    self.client?.urlProtocol(self, didLoad: data)
                }
                interceptor.log(response, data: data, request: self.request, timeElapsed: startTime.timeElapsedSinceNow, id: id)
                self.client?.urlProtocolDidFinishLoading(self)
                return
            }
        } else {
            guard let req = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest, newRequest == nil else { return }
            newRequest = req
            URLProtocol.setProperty(true, forKey: URLInterceptor.requestHandledKey, in: newRequest!)
            URLProtocol.setProperty(Date(), forKey: URLInterceptor.requestTimeKey, in: newRequest!)
            
            let session = Foundation.URLSession(configuration: URLSessionConfiguration.defaultSessionConf(), delegate: self, delegateQueue: nil)
            
            session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                if let error = error {
                    interceptor.log(error, request: self.request, timeElapsed: startTime.timeElapsedSinceNow, id: id)
                    self.client?.urlProtocol(self, didFailWithError: error)
                    return
                }
                
                guard let response = response else { return }
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: interceptor.cacheStoragePolicy)
                if let data = data {
                    self.client?.urlProtocol(self, didLoad: data)
                }
                
                interceptor.log(response, data: data, request: self.request, timeElapsed: startTime.timeElapsedSinceNow, id: id)
                self.client?.urlProtocolDidFinishLoading(self)
            }) .resume()
        }
    }
    
    public override func stopLoading() {
    }
    
    func URLSession(
        _ session: Foundation.URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: (URLRequest?) -> Void) {
        
        self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if let interceptor = URLInterceptor.interceptor, interceptor.bypassSslCheck {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
        else {
            completionHandler(.performDefaultHandling, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
    }
}

private let swizzling: (AnyClass, Selector, Selector) -> Bool = { forClass, originalSelector, swizzledSelector in
    guard
        let originalMethod = class_getClassMethod(forClass, originalSelector),
        let swizzledMethod = class_getClassMethod(forClass, swizzledSelector) else { return false }
 
    method_exchangeImplementations(originalMethod, swizzledMethod)
    
    return true
}

private var defaultSessionConfSwizzled: Bool = false
private var ephemeralSessionConfSwizzled: Bool = false

extension URLSessionConfiguration {
    fileprivate static func enableInterceptor() {
        let originalDefault = #selector(getter: URLSessionConfiguration.self.default)
        let swizzledDefault = #selector(getter: swizzled_default)
        
        let originalEphemeral = #selector(getter: URLSessionConfiguration.self.ephemeral)
        let swizzledEphemeral = #selector(getter: swizzled_ephemeral)
        
        defaultSessionConfSwizzled = swizzling(URLSessionConfiguration.self, originalDefault, swizzledDefault)
        ephemeralSessionConfSwizzled = swizzling(URLSessionConfiguration.self, originalEphemeral, swizzledEphemeral)
        
        URLProtocol.registerClass(URLInterceptor.self)
    }
    
    fileprivate static func defaultSessionConf() -> URLSessionConfiguration {
        return defaultSessionConfSwizzled ? self.swizzled_default : self.default
    }
    
    private static func enableInterceptor(forConfiguration config: URLSessionConfiguration) -> URLSessionConfiguration {
        if let protocolClasses = config.protocolClasses, !(protocolClasses.contains(where: { $0 is URLInterceptor.Type })) {
            config.protocolClasses?.insert(URLInterceptor.self, at: 0)
        }
        return config
    }
    
    @objc dynamic fileprivate class var swizzled_default: URLSessionConfiguration {
        get {
            return enableInterceptor(forConfiguration: self.swizzled_default)
        }
    }
    
    @objc dynamic fileprivate class var swizzled_ephemeral: URLSessionConfiguration {
        get {
            return enableInterceptor(forConfiguration: self.swizzled_ephemeral)
        }
    }
}

extension Date {
    public var timeElapsedSinceNow: TimeInterval { return -timeIntervalSinceNow.threeDecimal }
}

extension TimeInterval {
    var threeDecimal: TimeInterval {
        return (self*1000).rounded()/1000
    }
}
