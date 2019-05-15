import UIKit
import MonorailSwift

open class ApiServiceFileListTableViewController: UITableViewController {
    
    typealias FileListSection = (title: String, fileUrls: [URL])
    typealias OnFileSelectedFunc = ([URL], ApiServiceFileListTableViewController) -> Void
    
    private var sections = [FileListSection]()
    private var current = [URL]()

    init(sections: [FileListSection]) {
        super.init(style: .plain)
        self.sections = sections
//        self.current = current
//        self.onFileSelected = onFileSelected
//        self.onEdit = onEdit
//        self.editButtonTitle = editButtonTitle
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Never happen!")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
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
        cell.accessoryType = fileSelected ? .checkmark : .detailDisclosureButton
        
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        header.textLabel?.text = "\(sections[section].title)"
        return header
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileUrl = sections[indexPath.section].fileUrls[indexPath.row]
        onFileSelected(fileUrl: fileUrl)
    }
    
    open override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let fileUrl = sections[indexPath.section].fileUrls[indexPath.row]
        onFileSelected(fileUrl: fileUrl)
    }
   
    func didTapView(fileUrl: URL) {
        navigationController?.pushViewController(MonorailFileViewer(fileUrl), animated: true)
    }
    
    @objc func didTapShare(fileUrl: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        present(activityViewController, animated: true, completion: nil)
    }
    
    func didTapUse(fileUrl: URL) {
        Monorail.enableReader(from: [fileUrl])
        alert(message: "Reader enabled") {
            self.navigationController?.popViewController(animated: true)
            MonorailHelper.updateMonorailActionVc()
        }
    }
    
    func onFileSelected(fileUrl: URL) {
        let menu = UIAlertController(title: nil, message: fileUrl.absoluteString, preferredStyle: .actionSheet)
        
        let viewAction = UIAlertAction(title: "View", style: .default) { _ in self.didTapView(fileUrl: fileUrl) }
        let shareAction = UIAlertAction(title: "Share", style: .default) { _ in self.didTapShare(fileUrl: fileUrl) }
        let useAction = UIAlertAction(title: "Use as Mock", style: .default) { _ in self.didTapUse(fileUrl: fileUrl) }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        menu.addAction(viewAction)
        menu.addAction(shareAction)
        menu.addAction(useAction)
        menu.addAction(cancelAction)
        
        self.present(menu, animated: true, completion: nil)
    }
}
