import UIKit
import MonorailSwift

open class MonorailFileViewer: UITableViewController, UISearchResultsUpdating {
    
    public init(_ jsonFile: URL) {
        reader = APIServiceReader(file: jsonFile)
        super.init(style: .plain)
    }
    
    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Never happen!")
    }
    
    enum Order: String {
        case ascendant = "⇡"
        case descendant = "⇣"
        
        mutating func toggle() {
            self = .ascendant == self ? .descendant : .ascendant
        }
    }
    
    private var reader: APIServiceReader!
    private var selectedIndex: Int?
    private var order: Order = .ascendant
    private var orderButton: UIBarButtonItem!
    private var searchText: String?
    private let searchController = UISearchController(searchResultsController: nil)
    
    private var interactions: [Interaction] = []
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        title = reader.fileName
        interactions = reader.interactions
        
        orderButton = UIBarButtonItem(title: order.rawValue, style: .plain, target: self, action: #selector(didTapOrder))
        let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.search, target: self, action: #selector(didTapSearch))
        
        navigationItem.rightBarButtonItems = [orderButton, searchButton]
        
        searchController.searchResultsUpdater = self
        if #available(iOS 9.1, *) {
            searchController.obscuresBackgroundDuringPresentation = false
        }
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            navigationItem.titleView = searchController.searchBar
        }
        definesPresentationContext = true
    }

    // MARK: - Table view data source
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return interactions.count
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Interaction"
        let cell: UITableViewCell
        if let reuseCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = reuseCell
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        let interaction = interactions[indexPath.row]

        cell.textLabel?.text = "\(interaction.path ?? "")"
        cell.accessoryType = .disclosureIndicator
        cell.detailTextLabel?.text = interaction.details
        
        return cell
    }

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let interaction = interactions[indexPath.row]
        
        let vc = InteractionViewer.init(interaction)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func didTapOrder(sender: AnyObject) {
        order.toggle()
        updateInteractions()
    }
    
    @objc func didTapSearch(sender: AnyObject) {
        searchController.searchBar.becomeFirstResponder()
    }
    
    func updateInteractions() {
        orderButton.title = order.rawValue
        interactions = reader.interactions
        
        if let searchText = searchText, !searchText.isEmpty {
            interactions = reader.interactions.filter() {
                $0.path?.range(of: searchText, options: .caseInsensitive) != nil ? true : false
            }
        }
        
        if case Order.descendant = order {
            interactions.reverse()
        }
        tableView.reloadData()
    }
    
    public func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text
        updateInteractions()
    }
}

extension Interaction {
    var details: String {
        guard let response = responseObjects().0 else {
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

