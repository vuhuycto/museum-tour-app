//
//  PaymentViewController.swift
//  Object Decection
//
//  Created by Vu Huy on 21/04/2022.
//

import UIKit
import Braintree

class PaymentViewController: UIViewController {
    
    var braintreeClient: BTAPIClient!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func proceedPressed(_ sender: UIButton) {
        braintreeClient = BTAPIClient(authorization: "sandbox_9qb7b4sy_wgr3f2sckjzb6h8h")!
        _ = BTPayPalDriver(apiClient: braintreeClient)
        let payPalDriver = BTPayPalDriver(apiClient: braintreeClient)
        let dataCollector = BTDataCollector(apiClient: braintreeClient)

        let request = BTPayPalCheckoutRequest(amount: "2.32")
        request.currencyCode = "USD"
        
        payPalDriver.tokenizePayPalAccount(with: request) { (tokenizedPayPalAccount, error) in
            if let tokenizedPayPalAccount = tokenizedPayPalAccount {
                print(tokenizedPayPalAccount.nonce)
                dataCollector.collectDeviceData() { deviceData in
                    print(deviceData)
                }
            } else if let error = error {
                // Handle error here...
            } else {
                // Buyer canceled payment approval
            }
        }
        performSegue(withIdentifier: "goToDetection", sender: self)
    }
}
