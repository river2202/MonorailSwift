// http://chris.eidhof.nl/post/tiny-networking-in-swift/

import Foundation

enum ContentType: String {
    case formUrlEncoded = "application/x-www-form-urlencoded"
}

struct Resource<A: Decodable> {
	var method: String = "GET"
	var body: Data? = nil
	let url: URL
    let contentType: ContentType?
	
	let parseResult: (Data) -> Result<A>
}

struct ParseError: Error {}

extension Data {
    func decode<T: Decodable>(_ type: T.Type) -> T? {
        return try? JSONDecoder().decode(T.self, from: self)
    }
}

extension Resource {
	init(url: URL, postJSON json: Any?) {
		self.url = url
		self.method = "POST"
		self.body = json.map { try! JSONSerialization.data(withJSONObject: $0, options: []) }
		self.parseResult = { data in
			return Result(data.decode(A.self), or: ParseError())
		}
        
        self.contentType = nil
	}
    
    init(url: URL) {
        self.url = url
        self.parseResult = { data in
            return Result(data.decode(A.self), or: ParseError())
        }
        self.contentType = nil
    }
    
    init(url: URL, formParameters: String) {
        self.url = url
        self.method = "POST"
        self.parseResult = { data in
            return Result(data.decode(A.self), or: ParseError())
        }
        self.body = formParameters.data(using: .utf8)
        self.contentType = .formUrlEncoded
        print("formParameters=\(formParameters)")
    }
}

extension Resource {
	var request: URLRequest {
		var result = URLRequest(url: url)
		result.httpMethod = method
		if method == "POST" {
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
	func load<A>(_ resource: Resource<A>, completion: @escaping (Result<A>) -> ()) -> URLSessionDataTask {
		let t = dataTask(with: resource.request) { (data, response, error) in
			DispatchQueue.main.async {
				if let e = error {
					completion(.error(e))
				} else if let d = data {
					completion(resource.parseResult(d))
				}
			}
		}
		t.resume()
		return t
	}
}
