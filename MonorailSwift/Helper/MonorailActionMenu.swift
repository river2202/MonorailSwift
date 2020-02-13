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
    
//    public static func getMonorailReaderFileSelectorVc() -> ApiServiceFileListTableViewController {
//
//        let sections = MonorailFile.FileType.allType.map { ($0.name, $0.fileList) }
//
//        return ApiServiceFileListTableViewController(sections: sections, current: [], onFileSelected: { files, vc in
//
//            vc.alert(message: "Reader enabled") {
//                vc.navigationController?.popViewController(animated: true)
//                updateMonorailActionVc()
//            }
//        })
//    }
    
    public static func getMonorailFileSelectorVc() -> ApiServiceFileListTableViewController {
        
        let sections = MonorailFile.FileType.allType.map { ($0.name, $0.fileList) }
        
        return ApiServiceFileListTableViewController(sections: sections)
    }
    
    public static var monorailActionsVc: ActionMenuTableViewController = {
        return ActionMenuTableViewController(actions: monorailToolMenuActons)
    }()
    
    static func updateMonorailActionVc() {
        DispatchQueue.main.async {
            monorailActionsVc.actions = monorailToolMenuActons
            monorailActionsVc.tableView.reloadData()
        }
    }
    
    static var monorailToolMenuActons: [MenuItem] {
        var menu: [MenuItem] = []
        
        menu.append(contentsOf: [
            MenuItem(
                name: "Browser all log files",
                type: .menu(
                    subtitle: {
                        return Monorail.shared.reader?.fileName
                },
                    openMenu: { vc in
                        vc.navigationController?.pushViewController(getMonorailFileSelectorVc(), animated: true)
                }
                )
            ),
            ])
        
        menu.append(contentsOf: [
            MenuItem(name: "Enable Logger", type: .toggle(isOn: { () -> Bool in
                return Monorail.shared.logger != nil
            }, toggleAction: { _, enabled in
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
            }, toggleAction: { _, enabled in
                if enabled {
                    Monorail.stopWriteLog()
                    print("Stop writer")
                } else {
                    let fileUrl = Monorail.writeLog()
                    print("Begin writing to file: \(fileUrl?.absoluteString ?? "nil")")
                }
                updateMonorailActionVc()
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
                    updateMonorailActionVc()
//                    vc.alert(message: "Reader disabled")

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
        if toolWindowLayer.isHidden {
            toolWindowLayer.makeKeyAndVisible()
            monorailActionsVc.title = "Monorail Tools"
            monorailActionsVc.doneTapped = {
                toolWindowLayer.rootViewController?.dismiss(animated: true) {
                    toolWindowLayer.isHidden = true
                }
            }
            
            naviVc.viewControllers = [monorailActionsVc]
            toolWindowLayer.rootViewController?.present(naviVc, animated: true, completion: nil)
        } else {
            toolWindowLayer.rootViewController?.dismiss(animated: true) {
                toolWindowLayer.isHidden = true
            }
        }
    }
}

extension UIViewController {
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
