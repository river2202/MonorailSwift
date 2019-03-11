import UIKit
import MonorailSwift
import MonorailSwiftTools

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Monorail.enableLogger()
        setupUITest()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let rootVc = UINavigationController()
        window?.rootViewController = rootVc
        window?.makeKeyAndVisible()
        rootVc.pushViewController(ViewController(), animated: false)
        return true
    }
}

