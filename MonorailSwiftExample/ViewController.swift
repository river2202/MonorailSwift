import UIKit
import MonorailSwift

class ViewController: UITableViewController {

    let questionListApi = "https://api.stackexchange.com/2.2/search?order=desc&sort=activity&intitle=swift&site=stackoverflow&filter=!9Z(-wwK4f"
    var questionTask: URLSessionDataTask!
    var questionResponse: QuestionResponse? = nil
    
    var pageIndex: UInt = 0
    let pageSize: UInt = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "StackOverflow"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(didTapRefresh))
        
        loadQuestions(pageIndex: pageIndex, pageSize: pageSize)
    }
    
    private func loadQuestions(pageIndex: UInt, pageSize: UInt) {
        questionTask?.cancel()
        
        let resource = Resource<QuestionResponse>(url: URL(string: questionListApi)!)
        questionTask = URLSession.shared.load(resource, completion: { result in
            if case .success(let questionResponse) = result {
                self.questionResponse = questionResponse
                self.tableView.reloadData()
            }
        })
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questionResponse?.items.count ?? 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = questionResponse?.items[indexPath.row].title
        return cell
    }
    
    @objc func didTapRefresh(sender: AnyObject) {
        pageIndex = 0
        loadQuestions(pageIndex: pageIndex, pageSize: pageSize)
    }
}

