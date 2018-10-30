import Foundation

enum Result<A> {
	case error(Error)
	case success(A)
	
	init(_ value: A?, or: @autoclosure () -> Error) {
		if let x = value { self = .success(x) }
		else { self = .error(or()) }
	}
    
    var error: Error? {
        if case .error(let e) = self {
            return e
        }
        return nil
    }
}
