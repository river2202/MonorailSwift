
import UIKit

class MyFavoritesTableViewController: UITableViewController {
    
    private var questions: [Question] = [Question]()
    
    private var pageIndex: UInt = 0
    private let pageSize: UInt = 20
    
    private var token: String?
    private var userName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Favorites"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(didTapRefresh))
        
        loadQuestions(pageIndex: pageIndex, pageSize: pageSize)
    }
    
    private func loadQuestions(pageIndex: UInt, pageSize: UInt) {
        
        AppConfig.shared.soApi.myFavorites() { result in
            
            switch result {
            case .success(let questions):
                self.questions = questions
                self.tableView.reloadData()
            case .failure(let error):
                self.showAlert("Error: \(error)")
            }
        }
        
        
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = questions[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let questionVc = QuestionViewController.create(questions[indexPath.row].questionID)
        
        navigationController?.pushViewController(questionVc, animated: true)
    }
    
    @objc func didTapRefresh(sender: AnyObject) {
        pageIndex = 0
        loadQuestions(pageIndex: pageIndex, pageSize: pageSize)
    }
}
