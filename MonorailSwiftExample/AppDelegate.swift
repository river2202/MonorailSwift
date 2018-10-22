import UIKit
import MonorailSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Monorail.enableLogger()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let rootVc = UINavigationController()
        window?.rootViewController = rootVc
        window?.makeKeyAndVisible()
        rootVc.pushViewController(ViewController(), animated: false)
        return true
    }
}

