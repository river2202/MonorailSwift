import UIKit
import MonorailSwiftTools

class AppCoordinator {
    var rootViewControler: UINavigationController {
        let rootVc = UINavigationController()
        rootVc.pushViewController(mainViewControler(), animated: false)
        return rootVc
    }
    
    func mainViewControler() -> UIViewController {
        return ViewController()
    }
}
