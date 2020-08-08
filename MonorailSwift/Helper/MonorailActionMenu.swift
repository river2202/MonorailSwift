import UIKit
import MonorailSwift

//#if DEBUG
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            MonorailHelper.presentActionMenu()
        }
    }
}
//#endif

open class MonorailHelper {
    
    private static var toolWindowLayer: UIWindow = {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        window.windowLevel = UIWindow.Level(rawValue: 999)
        window.rootViewController = UIViewController()
        
        return window
    }()
    
    private static var naviVc = UINavigationController()
    
    public static func getMonorailFileSelectorVc(done: @escaping () -> Void) -> ApiServiceFileListTableViewController {
        
        let sections = MonorailFile.FileType.allType.map { ($0.name, $0.fileList) }
        
        return ApiServiceFileListTableViewController(sections: sections, done: done)
    }
    
    public static var monorailToolMenuActons: [MenuItem] {
        var menu: [MenuItem] = []
        
        menu.append(contentsOf: [
            MenuItem(
                name: "Browser all log files",
                type: .menu(
                    subtitle: {
                        return Monorail.shared.reader?.fileName
                },
                    openMenu: { vc in
                        vc.navigationController?.pushViewController(getMonorailFileSelectorVc(done: {
                            vc.updateMonorailAction(items: monorailToolMenuActons)
                        }), animated: true)
                }
                )
            ),
            ])
        
        menu.append(contentsOf: [
            MenuItem(name: "Enable Logger", type: .toggle(isOn: { () -> Bool in
                return Monorail.shared.logger != nil
            }, subtitle: { nil },  toggleAction: { _, enabled in
                if enabled {
                    Monorail.disableLogger()
                } else {
                    Monorail.enableLogger()
                }
            }))
            ])
        
        menu.append(contentsOf: [
            MenuItem(name: Monorail.isWriterEnabled ? "Disable Writter" : "Enable Writter", type: .toggle(isOn: {
                return Monorail.shared.writer != nil
            }, subtitle: { nil }, toggleAction: { vc, enabled in
                if enabled {
                    Monorail.stopWriteLog()
                    print("Stop writer")
                } else {
                    let fileUrl = Monorail.writeLog()
                    print("Begin writing to file: \(fileUrl?.absoluteString ?? "nil")")
                }
                vc.updateMonorailAction(items: monorailToolMenuActons)
            }))
            ])
        
        if Monorail.isWriterEnabled {
            menu.append(contentsOf: [
                MenuItem(name: "Show Log File", type: .action(subtitle: {nil}, action: { vc in
                    
                    if let logFile = Monorail.getLogFileUrl() {
                        vc.navigationController?.pushViewController(
                            MonorailFileViewer.init(logFile),
                            animated: true
                        )
                    } else {
                        vc.alert(message: "Log file not found")
                    }
                })),
                
                MenuItem(name: "Save to Documents/Monorail", type: .action(subtitle: {return nil}, action: { vc in
                    
                    if let _ = Monorail.getLogFileUrl() {
                        vc.showInputDialog(title: "Input file name",
                                           actionTitle: "Save",
                                           cancelTitle: "Cancel",
                                           inputInitText: "") { (input: String?) in
                                            
                                            guard let fileName = input else {
                                                return
                                            }
                                            
                                            Monorail.shared.writer?.saveToDocumentDirectory(fileName: fileName)
                                            vc.alert(message: "Select it from Reader file list", title: "Saved")
                                            
                        }
                    } else {
                        vc.alert(message: "Log file not found")
                    }
                })),
                
                MenuItem(
                    name: "Share Log File",
                    type: .action(
                        subtitle: {nil},
                        action: { vc in
                            if let logFile = Monorail.getLogFileUrl() {
                                let activityViewController = UIActivityViewController(activityItems: [ logFile ], applicationActivities: nil)
                                activityViewController.popoverPresentationController?.sourceView = vc.view
                                vc.present(activityViewController, animated: true, completion: nil)
                            } else {
                                vc.alert(message: "Log file not found")
                            }
                    }
                    )
                    )
                ]
            )
        }
        
        if Monorail.isReaderEnabled {
            menu.append(contentsOf: [
                MenuItem(name: "Disable Reader", type: .action(subtitle: {
                    return Monorail.shared.reader?.fileName
                }, action: { vc in
                    Monorail.disableReader()
                    vc.updateMonorailAction(items: monorailToolMenuActons)
                })),
                MenuItem(
                    name: "Reset Reader sequence",
                    type: .action(subtitle: {nil}) { vc in
                        Monorail.resetReader()
                        vc.alert(message: "Reader resetted")
                    }
                )
                ])
        }
        
        return menu
    }
    
    public static func presentActionMenu() {
        presentActionMenu(title: "Monorail Tools", items: monorailToolMenuActons)
    }
    
    public static func presentActionMenu(title: String, items: [MonorailHelper.MenuItem]) {
        if toolWindowLayer.isHidden {
            let monorailActionsVc = ActionMenuTableViewController(actions: items)
            toolWindowLayer.makeKeyAndVisible()
            monorailActionsVc.title = title
            monorailActionsVc.doneTapped = {
                toolWindowLayer.rootViewController?.dismiss(animated: true) {
                    toolWindowLayer.isHidden = true
                }
            }
            
            naviVc.viewControllers = [monorailActionsVc]
            toolWindowLayer.rootViewController?.present(naviVc, animated: true) {
                naviVc.presentationController?.presentedView?.gestureRecognizers?[0].isEnabled = false
            }
        } else {
            toolWindowLayer.rootViewController?.dismiss(animated: true) {
                toolWindowLayer.isHidden = true
            }
        }
    }
}

public extension UIViewController {
    func alert(message: String, title: String = "", handler: (() -> Void)? = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: { _ in handler?() })
        
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showInputDialog(title: String? = nil,
                         subtitle: String? = nil,
                         actionTitle: String? = "Add",
                         cancelTitle: String? = "Cancel",
                         inputInitText: String? = nil,
                         inputPlaceholder: String? = nil,
                         inputKeyboardType: UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField: UITextField) in
            textField.text = inputInitText
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .destructive, handler: { (_: UIAlertAction) in
            guard let textField = alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler))
        
        present(alert, animated: true, completion: nil)
    }
}
