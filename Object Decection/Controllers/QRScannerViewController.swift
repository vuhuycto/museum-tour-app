import UIKit
import AVFoundation
import MercariQRScanner
import Braintree
import Alamofire
import JWTDecode

class QRScannerViewController: UIViewController {
    
    var qrScannerView: QRScannerView!
    let detectionSegueIdentifier = "goToDetection"
    var braintreeClient: BTAPIClient!
    let baseURL = "\(Config.baseURL)/tickets"
    let storage = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let ticketAccessToken = storage.string(forKey: Config.ticketAccessTokenStorageKey) {
            guard let jwt = try? decode(jwt: ticketAccessToken) else {
                self.setupQRScanner()
                return
            }
            
            let timestamp = NSDate().timeIntervalSince1970
            if timestamp - (jwt.body["iat"] as! Double) > 86400 {
                storage.removeObject(forKey: Config.ticketAccessTokenStorageKey)
                self.setupQRScanner()
                return
            }
            
            self.performSegue(withIdentifier: "goToDetection", sender: self)
        } else {
            setupQRScanner()
        }
    }

    private func setupQRScanner() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                setupQRScannerView()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    if granted {
                        DispatchQueue.main.async { [weak self] in
                            self?.setupQRScannerView()
                        }
                    }
                }
            default:
                showAlert()
        }
    }
    
    private func resumeQRScanner() {
        qrScannerView.startRunning()
    }
    
    private func stopQRScanner() {
        qrScannerView.stopRunning()
    }

    private func setupQRScannerView() {
        qrScannerView = QRScannerView(frame: view.bounds)
        view.addSubview(qrScannerView)
        qrScannerView.configure(delegate: self, input: .init(isBlurEffectEnabled: true))
        qrScannerView.startRunning()
    }

    private func showAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let alert = UIAlertController(title: "Error", message: "Camera is required to use in this application", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
}

extension QRScannerViewController: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        print(error)
        resumeQRScanner()
    }

    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        stopQRScanner()
        
        guard let saleData = try? JSONDecoder().decode(SaleData.self, from: code.data(using: .utf8)!) else { return }
        
        braintreeClient = BTAPIClient(authorization: Config.braintreeSanboxAuth)!
        _ = BTPayPalDriver(apiClient: braintreeClient)
        let payPalDriver = BTPayPalDriver(apiClient: braintreeClient)
        let dataCollector = BTDataCollector(apiClient: braintreeClient)

        let request = BTPayPalCheckoutRequest(amount: saleData.price)
        request.currencyCode = "USD"
        
        payPalDriver.tokenizePayPalAccount(with: request) { (tokenizedPayPalAccount, error) in
            if let error = error {
                print(error)
                return
            }
            
            if let tokenizedPayPalAccount = tokenizedPayPalAccount {
                dataCollector.collectDeviceData() { deviceData in
                    guard let deviceData = try? JSONDecoder().decode(DeviceData.self, from: deviceData.data(using: .utf8)!) else { return }

                    AF.request(
                        self.baseURL,
                        method: .post,
                        parameters: [
                            "amount": saleData.price,
                            "nonce": tokenizedPayPalAccount.nonce,
                            "device_data": deviceData.correlation_id
                        ],
                        encoder: .json
                    ).responseDecodable(of: TicketData.self) { response in
                        if let ticket = response.value {
                            print(ticket.access_token)
                            self.storage.set(ticket.access_token, forKey: Config.ticketAccessTokenStorageKey)
                            self.performSegue(withIdentifier: self.detectionSegueIdentifier, sender: self)
                        }
                    }
                }
            }
        }
    }
}
