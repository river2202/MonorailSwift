import UIKit

enum CommonError: Error {
    case unknown
}
class QuestionViewController: UIViewController {
    
    static func create(_ questionId: Int?) -> QuestionViewController {
        let vc = UIStoryboard(name: "QuestionView", bundle: nil).instantiateInitialViewController() as! QuestionViewController
        
        vc.questionId = questionId
        
        return vc
    }

    @IBOutlet weak var qTitle: UILabel!
    @IBOutlet weak var qFavorite: UIButton!
    @IBOutlet weak var qBody: UILabel!
    @IBOutlet weak var qFavoriteBtnContainer: UIView!
    
    private var questionId: Int?
    private var questionTask: URLSessionDataTask!
    private var question: Question?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resource = RestApiResource<QuestionResponse>(url: AppConfig.shared.soApi.questionDetailApi(questionId: questionId)!)
        questionTask = URLSession.shared.load(resource, completion: { result in
            if case .success(let questionResponse) = result {
                self.updateQuestion(questionResponse.items?.first)
            }
        })
    }
    
    private func updateQuestion(_ question: Question?) {
        
        qFavoriteBtnContainer.isHidden = !AppConfig.shared.soApi.isUserLogined
        qTitle.text = question?.title
        qFavorite.backgroundColor = (question?.favorited ?? false) ? UIColor.yellow : UIColor.gray
        
        qBody.attributedText = question?.body?.htmlToAttributedString
        self.question = question
    }
    
    @IBAction func onFavoriteTapped(_ sender: Any) {
        
        AppConfig.shared.soApi.favorite(questionId, undo: self.question?.favorited ?? false) { result in
            
            switch result {
            case .success(let question):
                self.updateQuestion(question)
            case .failure(let error):
                self.showAlert("Error: \(error)")
            }
        }
    }
    
}

extension String {
    
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        
        return try? NSAttributedString(data: data,
                                       options: [.documentType: NSAttributedString.DocumentType.html,
                                                 .characterEncoding: String.Encoding.utf8.rawValue],
                                       documentAttributes: nil)
    }
    
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
