import UIKit

class ViewController: UITableViewController {

    private let questionListApi = "https://api.stackexchange.com/2.2/search?order=desc&sort=activity&tagged=swift&site=stackoverflow"
    private var questionTask: URLSessionDataTask!
    private var questionResponse: QuestionResponse? = nil
    
    private var pageIndex: UInt = 0
    private let pageSize: UInt = 20
    
    private var token: String?
    private var userName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "StackOverflow"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(didTapRefresh))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(didTapLogin))
        
        loadQuestions(pageIndex: pageIndex, pageSize: pageSize)
    }
    
    func updateButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(didTapRefresh))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(didTapLogin))
        loadQuestions(pageIndex: pageIndex, pageSize: pageSize)
    }
    
    private func loadQuestions(pageIndex: UInt, pageSize: UInt) {
        questionTask?.cancel()
        
        let resource = RestApiResource<QuestionResponse>(url: URL(string: questionListApi)!)
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
        cell.accessibilityIdentifier = "cell_\(indexPath.section)_\(indexPath.row)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let questionVc = QuestionViewController.create(questionResponse?.items?[indexPath.row].questionID)
        
        navigationController?.pushViewController(questionVc, animated: true)
    }
    
    @objc func didTapRefresh(sender: AnyObject) {
        pageIndex = 0
        loadQuestions(pageIndex: pageIndex, pageSize: pageSize)
    }
    
    @objc func didTapLogin(sender: AnyObject) {
        AppConfig.shared.soApi.login { err, accessToken in
            guard err == nil, let accessToken = accessToken else {
                return self.showAlert("\(err!)")
            }
            
            AppConfig.shared.soApi.loadUsername(accessToken: accessToken) { err, userName in
            
                guard err == nil, let userName = userName else {
                    return self.showAlert("\(err!)")
                }
                
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: userName, style: .plain, target: self, action: #selector(self.didTapUserName))
            }
        }
    }
    
    @objc func didTapUserName(sender: AnyObject) {
        let questionVc = MyFavoritesTableViewController()
        navigationController?.pushViewController(questionVc, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
}

extension UIViewController {
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            print("Handle Ok logic here")
        }))
        present(alert, animated: true, completion: nil)
    }
}

//
//class TimeMeasure {
//    let timeStampFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
//    var start = Date()
//    
//    func tag(_ msg: String? = nil) {
//        let now = Date()
//        
//        print("\(now.asString(timeStampFormat)) - \(msg ?? "") \(now.timeIntervalSince(start)) s")
//    }
//    
//    func reset(msg: String? = nil) {
//        self.name = name
//        start = Date()
//        
//        print("\(start.asString(timeStampFormat)) - \(msg ?? "")")
//    }
//}
