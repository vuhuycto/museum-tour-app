import UIKit
import WebKit

class DetailsViewController: UIViewController {
    
    let webView = WKWebView()
    var descriptionURL: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(webView)
        
        let urlRequest = URLRequest(url: URL(string: descriptionURL!)!)
        webView.load(urlRequest)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        webView.frame = view.bounds
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        webView.loadHTMLString("", baseURL: nil)
    }
}
