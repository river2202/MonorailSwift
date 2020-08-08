import UIKit
import MonorailSwift

public extension MonorailHelper {
    
    public enum MenuItemType {
        case action(subtitle: () -> String?, action: (ActionMenuTableViewController) -> Void)
        case toggle(isOn: () -> Bool, subtitle: () -> String?, toggleAction: (ActionMenuTableViewController, Bool) -> Void)
        case menu(subtitle: () -> String?, openMenu: (ActionMenuTableViewController) -> Void)
        case info
        
        var tableViewCellAccessoryType: UITableViewCell.AccessoryType {
            switch self {
            case let .toggle(isOn, _, _):
                return isOn() ? .checkmark : .none
            case .menu:
                return .disclosureIndicator
            default:
                return .none
            }
            
        }
    }
    
    struct MenuItem {
        public init(name: String, type: MonorailHelper.MenuItemType) {
            self.name = name
            self.type = type
        }
        
        let name: String
        let type: MenuItemType
        let accessibilityIdentifer: String? = nil
        
        func didSelect(vc: ActionMenuTableViewController) {
            switch type {
            case let .menu(_, action), let .action(_, action):
                action(vc)
            case let .toggle(isOn, _, toggleAction):
                toggleAction(vc, isOn())
            default:
                break
            }
        }
        
        var subtitle: String? {
            switch type {
            case let .menu(getSubtitle, _), let .action(getSubtitle, _), let .toggle(_, getSubtitle, _):
                return getSubtitle()
            default:
                return nil
            }
        }
    }
    
    public class ActionMenuTableViewController: UITableViewController {
        public typealias TapBtnFunc = () -> Void
        public var doneTapped: TapBtnFunc?
        var actions: [MenuItem]
        
        public init(actions: [MenuItem], doneTapped: TapBtnFunc? = nil) {
            self.actions = actions
            self.doneTapped = doneTapped
            super.init(style: .plain)
        }
        
        public required init?(coder aDecoder: NSCoder) {
            fatalError("Never happen!")
        }
        
        override open func viewDidLoad() {
            super.viewDidLoad()
            
            if doneTapped != nil {
                let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(didTapDone))
                navigationItem.rightBarButtonItems = [doneButton]
            }
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
        
        public func updateMonorailAction(items: [MenuItem]) {
            DispatchQueue.main.async {
                self.actions = items
                self.tableView.reloadData()
            }
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
