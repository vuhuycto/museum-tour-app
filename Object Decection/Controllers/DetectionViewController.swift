import UIKit
import SceneKit
import SpriteKit
import ARKit
import Alamofire

struct InfoNode {
    let node: SCNNode
    let descriptionURL: String
}

class DetectionViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var infoNodes: [InfoNode] = []
    var currentDescriptionURL: String? = nil
    let detailsSegueIdentifier = "goToDetails"
    let baseURL = "\(Config.baseURL)/objects"
    let storage = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        guard let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "gallery", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        configuration.detectionObjects = referenceObjects
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    @IBAction func qrCodePressed(_ sender: UIButton) {
        performSegue(withIdentifier: "goToMyTicket", sender: self)
    }
    
    func isSpecifiedAnchorName(_ name: String) -> Bool {
        return name == "Scan_11-12-38" || name == "Scan_11-20-18"
    }
    
    func drawText(content: String, position: SCNVector3, color: UIColor, fontSize: Float) -> SCNNode {
        let text = SCNText(string: content, extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 1.0)
        text.flatness = 0
        text.firstMaterial?.diffuse.contents = color
        let textNode = SCNNode(geometry: text)
        textNode.name = content
        textNode.position = position
        let fontSize = Float(fontSize)
        textNode.eulerAngles.y = Float.pi / 2
        textNode.scale = SCNVector3(x: fontSize, y: fontSize, z: fontSize)
        return textNode
    }
    
    func drawInfoButton(name: String, position: SCNVector3, size: Float) -> SCNNode {
        let infoIcon = SKTexture(imageNamed: "info")
        let infoPlane = SCNPlane(width: infoIcon.size().width, height: infoIcon.size().height)
        infoPlane.cornerRadius = infoPlane.width / 2
        let material = SCNMaterial()
        material.diffuse.contents = infoIcon
        infoPlane.materials = [material]
        let infoNode = SCNNode(geometry: infoPlane)
        infoNode.name = name
        infoNode.position = position
        infoNode.eulerAngles.y = Float.pi / 2
        let infoIconSize = Float(size)
        infoNode.scale = SCNVector3(x: infoIconSize, y: infoIconSize, z: infoIconSize)
        return infoNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let objectAnchor = anchor as? ARObjectAnchor {
            guard let objAnchorIdentifier = objectAnchor.referenceObject.name else { return }
            
            if isSpecifiedAnchorName(objAnchorIdentifier) {
                if let ticketAccessToken = storage.string(forKey: Config.ticketAccessTokenStorageKey) {
                    AF.request(
                        "\(baseURL)/\(objAnchorIdentifier)",
                        method: .get,
                        headers: [
                            .authorization("Bearer \(ticketAccessToken)"),
                            .contentType("application/json")
                        ]
                    ).responseDecodable(of: DetailsData.self) { response in
                        if response.response?.statusCode == 401 {
                            self.storage.removeObject(forKey: Config.ticketAccessTokenStorageKey)
                            self.dismiss(animated: true)
                        }
                        
                        if let details = response.value {
                            let nameNode = self.drawText(
                                content: details.name,
                                position: SCNVector3Make(
                                    objectAnchor.referenceObject.center.x,
                                    objectAnchor.referenceObject.center.y + 0.05,
                                    objectAnchor.referenceObject.center.z + 0.05
                                ),
                                color: .white,
                                fontSize: 0.01
                            )
                            
                            let infoNode = self.drawInfoButton(
                                name: details.name,
                                position: SCNVector3Make(
                                    objectAnchor.referenceObject.center.x,
                                    objectAnchor.referenceObject.center.y,
                                    objectAnchor.referenceObject.center.z - 0.05
                                ),
                                size: 0.0005
                            )
                            
                            self.infoNodes.append(
                                InfoNode(
                                    node: infoNode,
                                    descriptionURL: details.description_url
                                )
                            )
                            node.addChildNode(nameNode)
                            node.addChildNode(infoNode)
                        }
                    }
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.view == self.sceneView {
                let viewTouchLocation: CGPoint = touch.location(in: sceneView)
                guard let result = sceneView.hitTest(viewTouchLocation, options: nil).first else {
                    return
                }
                
                if let currentNode = infoNodes.filter({ infoNode in
                    return result.node.name == infoNode.node.name
                }).first {
                    currentDescriptionURL = currentNode.descriptionURL
                    performSegue(withIdentifier: detailsSegueIdentifier, sender: self)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == detailsSegueIdentifier {
            let detailsVC = segue.destination as! DetailsViewController
            detailsVC.descriptionURL = currentDescriptionURL
        }
    }
}
