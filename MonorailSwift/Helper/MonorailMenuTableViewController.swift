import UIKit
import MonorailSwift

public extension MonorailHelper {
    
    enum MenuItemType {
        case action(subtitle: () -> String?, action: (UIViewController) -> Void)
        case toggle(isOn: () -> Bool, toggleAction: (UIViewController, Bool) -> Void)
        case menu(subtitle: () -> String?, openMenu: (UIViewController) -> Void)
        case info
        
        var tableViewCellAccessoryType: UITableViewCell.AccessoryType {
            switch self {
            case let .toggle(isOn, _):
                return isOn() ? .checkmark : .none
            case .menu:
                return .disclosureIndicator
            default:
                return .none
            }
            
        }
    }
    
    struct MenuItem {
        let name: String
        let type: MenuItemType
        let accessibilityIdentifer: String? = nil
        
        func didSelect(vc: UIViewController) {
            switch type {
            case let .menu(_, action), let .action(_, action):
                action(vc)
            case let .toggle(isOn, toggleAction):
                toggleAction(vc, isOn())
            default:
                break
            }
        }
        
        var subtitle: String? {
            switch type {
            case let .menu(getSubtitle, _), let .action(getSubtitle, _):
                return getSubtitle()
            default:
                return nil
            }
        }
    }
    
    class ActionMenuTableViewController: UITableViewController {
        typealias TapBtnFunc = () -> Void
        var doneTapped: TapBtnFunc?
        var actions: [MenuItem]
        
        init(actions: [MenuItem], doneTapped: TapBtnFunc? = nil) {
            self.actions = actions
            self.doneTapped = doneTapped
            super.init(style: .plain)
        }
        
        public required init?(coder aDecoder: NSCoder) {
            fatalError("Never happen!")
        }
        
        override open func viewDidLoad() {
            super.viewDidLoad()
            
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(didTapDone))
            
            navigationItem.rightBarButtonItems = [doneButton]
        }
        
        // MARK: - Table view data source
        override open func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }
        
        override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return actions.count
        }
        
        override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = "\(actions[indexPath.row].name)"
            cell.accessibilityIdentifier = actions[indexPath.row].accessibilityIdentifer
            cell.accessoryType =  actions[indexPath.row].type.tableViewCellAccessoryType
            cell.detailTextLabel?.text = actions[indexPath.row].subtitle
            
            return cell
        }
        
        override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            actions[indexPath.row].didSelect(vc: self)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        @objc func didTapDone(sender: AnyObject) {
            doneTapped?()
        }
    }

    struct MonorailFile: Codable {
        enum FileType: Int, Codable {
            case stubsMonorail
            case documentMonorail
            case uitest
            case demo
            
            var fileList: [URL] {
                if let path = path, let urls = try? FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil) {
                    return urls.filter({ !$0.lastPathComponent.starts(with: "-") })
                } else {
                    return []
                }
            }
            
            var name: String {
                switch self {
                case .stubsMonorail:
                    return "Buildin - bundle stubs folder"
                case .documentMonorail:
                    return "Documents - local"
                case .uitest:
                    return "UITest"
                case .demo:
                    return "Demo"
                }
            }
            
            var path: URL? {
                switch self {
                case .stubsMonorail:
                    return APIServiceWriter.monorailCacheDirectory
                case .documentMonorail:
                    return APIServiceWriter.monorailDocumentDirectory
                case .uitest:
                    return StubManager.folder("UITest")
                case .demo:
                    return StubManager.folder("Demo")
                }
            }
            
            static var allType: [FileType] {
                return [.stubsMonorail, .documentMonorail, .uitest, .demo]
            }
            
            static func getTypeFrom(url: URL) -> FileType? {
                let urlString = url.standardized.relativePath
                return allType.filter {
                    if let typePath = $0.path?.standardized.relativePath {
                        return urlString.range(of: typePath) != nil
                    } else {
                        return false
                    }
                    }.last
            }
        }
        
        let type: FileType
        let name: String
        
        var url: URL? {
            return type.path?.appendingPathComponent(name)
        }
        
        static func from(url: URL) -> MonorailFile? {
            guard let type = MonorailFile.FileType.getTypeFrom(url: url) else {
                return nil
            }
            
            return MonorailFile(type: type, name: url.lastPathComponent)
        }
    }

}
