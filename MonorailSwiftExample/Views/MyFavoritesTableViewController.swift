
import UIKit

class MyFavoritesTableViewController: UITableViewController {
    
    
    private let questionListApi = "https://api.stackexchange.com/2.2/search?order=desc&sort=activity&intitle=swift&site=stackoverflow"
    private var questionTask: URLSessionDataTask!
    private var questionResponse: QuestionResponse? = nil
    
    private var pageIndex: UInt = 0
    private let pageSize: UInt = 20
    
    private var token: String?
    private var userName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Favorites"
        
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
        return questionResponse?.items?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = questionResponse?.items?[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let questionVc = QuestionViewController.create(questionResponse?.items?[indexPath.row].questionID)
        
        navigationController?.pushViewController(questionVc, animated: true)
    }
}
