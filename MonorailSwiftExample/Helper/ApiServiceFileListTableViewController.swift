import UIKit

open class ApiServiceFileListTableViewController: UITableViewController {
    
    typealias FileListSection = (title: String, fileUrls: [URL])
    typealias OnFileSelectedFunc = ([URL], ApiServiceFileListTableViewController) -> Void
    
    private var sections = [FileListSection]()
    private var current = [URL]()
    private var onFileSelected: OnFileSelectedFunc?
    private var onEdit: OnFileSelectedFunc?
    private var editButtonTitle: String?
    
    init(sections: [FileListSection], current: [URL], onFileSelected: OnFileSelectedFunc?, editButtonTitle: String? = nil, onEdit: OnFileSelectedFunc? = nil) {
        super.init(style: .plain)
        self.sections = sections
        self.current = current
        self.onFileSelected = onFileSelected
        self.onEdit = onEdit
        self.editButtonTitle = editButtonTitle
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Never happen!")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let shareButton = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(didTapShare))
        if onEdit != nil {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(title: editButtonTitle, style: .plain, target: self, action: #selector(didTapEditButton)), shareButton]
        } else {
            navigationItem.rightBarButtonItems = [shareButton]
        }
    }

    // MARK: - Table view data source
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].fileUrls.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let fileUrl = sections[indexPath.section].fileUrls[indexPath.row]
        let fileSelected = current.contains { (currentFile) -> Bool in
            return fileUrl.standardized.relativePath.range(of: currentFile.standardized.relativePath) != nil
        }
        
        cell.textLabel?.text = "\(fileUrl.lastPathComponent)"
        cell.accessoryType = fileSelected ? .checkmark : .none
        
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        header.textLabel?.text = "\(sections[section].title)"
        return header
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileUrl = sections[indexPath.section].fileUrls[indexPath.row]
        current = [fileUrl]
        tableView.reloadData()
        onFileSelected?(current, self)
    }
    
    @objc func didTapEditButton(sender: AnyObject) {
        onEdit?(current, self)
    }
    
    @objc func didTapShare(sender: AnyObject) {
        let activityViewController = UIActivityViewController(activityItems: current, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        present(activityViewController, animated: true, completion: nil)
    }
}
