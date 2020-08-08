import UIKit
import MonorailSwift

class InteractionViewer: UIViewController {
    
    var interaction: Interaction!
    public init(_ interaction: Interaction) {
        self.interaction = interaction
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Never happen!")
    }
    
    override func viewDidLoad() {
        let textView = UITextView(frame: view.frame)
        view.addSubview(textView)
        textView.isEditable = false
        
        if let pretty = try? JSONSerialization.data(withJSONObject: interaction.payload(), options: [.prettyPrinted]),
            let content = String(data: pretty, encoding: .utf8) {
            textView.text = content
        } else {
            textView.text = "N/A"
        }
        
        if let path = interaction.path {
            title = URL(string: path)?.lastPathComponent
        } else {
            title = interaction.path
        }
    }
}
