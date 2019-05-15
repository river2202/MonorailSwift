import UIKit
import MonorailSwift
import MonorailSwiftTools

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Monorail.enableLogger()
        Monorail.writeLog()
        setupUITest()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = AppCoordinator().rootViewControler
        window?.makeKeyAndVisible()
        return true
    }
}

