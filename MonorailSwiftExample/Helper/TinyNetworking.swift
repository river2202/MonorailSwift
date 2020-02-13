// Thanks: http://chris.eidhof.nl/post/tiny-networking-in-swift/

import Foundation

enum ContentType: String {
    case formUrlEncoded = "application/x-www-form-urlencoded"
}

struct Resource<A: Decodable, E: Error> {
    enum Method: String {
        case get = "GET"
        case post = "POST"
    }
    var method: Method = Method.get
    var body: Data? = nil
    let url: URL
    let contentType: ContentType?
    
    let parseResult: (Data) -> Result<A, E>
}


enum RestApiResourceError: Error {
    case parseError
    case network(error: Error)
}

typealias RestApiResource<A: Decodable> = Resource<A, RestApiResourceError>
typealias RestApiResourceResult<A: Decodable> = Result<A, RestApiResourceError>

extension Data {
    func decode<T: Decodable>(_ type: T.Type) -> T? {
        return try? JSONDecoder().decode(T.self, from: self)
    }
    
    func restApiResourceDecodeResult<T: Decodable>() -> RestApiResourceResult<T> {
        return Result(decode(T.self), or: .parseError)
    }
}

extension RestApiResourceResult where Failure == RestApiResourceError {
    init(_ value: Success?, or: @autoclosure () -> RestApiResourceError) {
        if let x = value { self = .success(x) }
        else { self = .failure(or()) }
    }
}

extension RestApiResource where E == RestApiResourceError {
    init(url: URL, postJSON json: Any?) {
        self.url = url
        self.method = Method.post
        self.body = json.map { try! JSONSerialization.data(withJSONObject: $0, options: []) }
        self.parseResult = { return $0.restApiResourceDecodeResult() }
        
        self.contentType = nil
    }
    
    init(url: URL) {
        self.url = url
        self.parseResult = { return $0.restApiResourceDecodeResult() }
        self.contentType = nil
    }
    
    init(url: URL, formParameters: String) {
        self.url = url
        self.method = Method.post
        self.parseResult = { return $0.restApiResourceDecodeResult() }
        self.body = formParameters.data(using: .utf8)
        self.contentType = .formUrlEncoded
    }
    
    var request: URLRequest {
        var result = URLRequest(url: url)
        result.httpMethod = method.rawValue
        if method == Method.post {
            result.httpBody = body
        }
        
        if let contentType = contentType {
            result.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        }
        return result
    }
}

extension URLSession {
    @discardableResult
    func load<A>(_ resource: RestApiResource<A>, completion: @escaping (RestApiResourceResult<A>) -> ()) -> URLSessionDataTask {
        let t = dataTask(with: resource.request) { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(RestApiResourceResult<A>.failure(.network(error: error)))
                } else if let d = data {
                    completion(resource.parseResult(d))
                }
            }
        }
        t.resume()
        return t
    }
}
