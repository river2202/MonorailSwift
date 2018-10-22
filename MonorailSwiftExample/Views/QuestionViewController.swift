import UIKit

class QuestionViewController: UIViewController {
    
    static func create(_ questionId: Int?) -> QuestionViewController {
        let vc = UIStoryboard(name: "QuestionView", bundle: nil).instantiateInitialViewController() as! QuestionViewController
        
        vc.questionId = questionId
        
        return vc
    }

    @IBOutlet weak var qTitle: UILabel!
    @IBOutlet weak var qFavorite: UIButton!
    @IBOutlet weak var qBody: UILabel!
    
    private var questionId: Int?
    private var questionTask: URLSessionDataTask!

    
    private var questionDetailApi: URL? {
        if let questionId = questionId {
            return URL(string:"https://api.stackexchange.com/2.2/questions/\(questionId)?order=desc&sort=activity&site=stackoverflow&filter=!9Z(-wwYGT")
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resource = Resource<QuestionResponse>(url: questionDetailApi!)
        questionTask = URLSession.shared.load(resource, completion: { result in
            if case .success(let questionResponse) = result {
                self.updateQuestion(questionResponse.items.first)
            }
        })
    }
    
    private func updateQuestion(_ question: Item?) {
        qTitle.text = question?.title
        qFavorite.backgroundColor = (question?.favorited ?? false) ? UIColor.yellow : UIColor.gray
        
        qBody.attributedText = question?.body?.htmlToAttributedString
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
