import UIKit

protocol UIViewControllerCreator  {
    static func create(storyboard: String, bundle: Bundle?, initialViewController: Bool) -> Self
}

extension UIViewControllerCreator where Self: UIViewController {
    static func create(storyboard: String, bundle: Bundle? = nil, initialViewController: Bool = false) -> Self{
        if initialViewController {
            return UIStoryboard(name: storyboard, bundle: bundle ?? Bundle(for: self)).instantiateInitialViewController() as! Self
        } else {
            return UIStoryboard(name: storyboard, bundle: Bundle(for: self)).instantiateViewController(withIdentifier: String(describing: self)) as! Self
        }
    }
}
