//
//  MyTicketViewController.swift
//  Object Decection
//
//  Created by Vu Huy on 24/04/2022.
//

import UIKit

class MyTicketViewController: UIViewController {
    
    @IBOutlet weak var QRCodeImage: UIImageView!
    
    let storage = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let qrCode = generateQRCode() {
            QRCodeImage.image = qrCode
        }
    }
    
    func generateQRCode() -> UIImage? {
        if let ticketAccessToken = storage.string(forKey: Config.ticketAccessTokenStorageKey) {
            let data = ticketAccessToken.data(using: String.Encoding.ascii)

            if let filter = CIFilter(name: "CIQRCodeGenerator") {
                filter.setValue(data, forKey: "inputMessage")
                let transform = CGAffineTransform(scaleX: 3, y: 3)

                if let output = filter.outputImage?.transformed(by: transform) {
                    return UIImage(ciImage: output)
                }
            }
        }
        
        return nil
    }
}
