import UIKit
import MonorailSwift

open class MonorailFileViewer: UITableViewController {
    
    public init(_ jsonFile: URL) {
        reader = APIServiceReader(file: jsonFile)
        super.init(style: .plain)
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Never happen!")
    }
    
    enum Order: String {
        case ascendant = "⬆"
        case descendant = "⬇"
        
        mutating func toggle() {
            self = .ascendant == self ? .descendant : .ascendant
        }
    }
    
    private var reader: APIServiceReader!
    private var selectedIndex: Int?
    private var order: Order = .ascendant
    private var orderButton: UIBarButtonItem!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        title = reader.fileName
        
        orderButton = UIBarButtonItem(title: order.rawValue, style: .plain, target: self, action: #selector(didTapOrder))
        navigationItem.rightBarButtonItems = [orderButton]
    }

    // MARK: - Table view data source
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reader.interactions.count
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Interaction"
        let cell: UITableViewCell
        if let reuseCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = reuseCell
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        let interaction = reader.interactions[indexPath.row]

        cell.textLabel?.text = "\(interaction.path ?? "")"
        cell.accessoryType = .disclosureIndicator
        cell.detailTextLabel?.text = interaction.details
        
        return cell
    }

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let interaction = reader.interactions[indexPath.row]
        
        let vc = InteractionViewer.init(interaction)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func didTapOrder(sender: AnyObject) {
        order.toggle()
        orderButton.title = order.rawValue
        reader.interactions.reverse()
        tableView.reloadData()
    }
}

extension Interaction {
    var details: String {
        guard let (response, _, _) = responseObjects() else {
            return "-"
        }
        
        return "\(response.statusCode), \(timeStampString)"
    }
    
    var timeStampString: String {
        return timeStamp?.asString(format: "dd/MM/yyyy HH:mm:ss") ?? ""
    }
}

extension Date {
    func asString(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

