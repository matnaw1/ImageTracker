//
//  ViewController.swift
//  ImageTracker
//
//  Created by Mati MacBook on 26/05/2021.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var queenNode: SCNNode?
    var kingNode: SCNNode?
    var imageNodes = [SCNNode]()
    var isJumping = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        let queenScene = SCNScene(named: "art.scnassets/queen.scn")
        let kingScene = SCNScene(named: "art.scnassets/king.scn")
        queenNode = queenScene?.rootNode
        kingNode = kingScene?.rootNode
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARImageTrackingConfiguration()
        
        if let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Playing Cards", bundle: Bundle.main) {
            configuration.trackingImages = trackingImages
            configuration.maximumNumberOfTrackedImages = 2
        }
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor {
            let size = imageAnchor.referenceImage.physicalSize
            let plane = SCNPlane(width: size.width, height: size.height)
            plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
            plane.cornerRadius = 0.005
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi/2
            node.addChildNode(planeNode)
            
            var shapeNode: SCNNode?
            
            switch imageAnchor.referenceImage.name {
            case CardType.king.rawValue:
                shapeNode = kingNode
            case CardType.queen.rawValue:
                shapeNode = queenNode
            default:
                break
            }
            
            let shapeSpin = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 10)
            let repeatSpin = SCNAction.repeatForever(shapeSpin)
            shapeNode?.runAction(repeatSpin)
            
            guard let shape = shapeNode else { return nil }
            node.addChildNode(shape)
            imageNodes.append(node)
            return node
        }
        
        return nil
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if imageNodes.count == 2 {
            let positionOne = SCNVector3ToGLKVector3(imageNodes[0].position)
            let positionTwo = SCNVector3ToGLKVector3(imageNodes[1].position)
            let distance = GLKVector3Distance(positionOne, positionTwo)
            
            if distance < 0.10 {
                spinJump(node: imageNodes[0])
                spinJump(node: imageNodes[1])
                isJumping = true
            } else {
                isJumping = false
            }
        }
    }
    
    func spinJump(node: SCNNode) {
        if isJumping { return }
        let shapeNode = node.childNodes[1]
        let shapeSpin = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 1)
        shapeSpin.timingMode = .easeInEaseOut
        
        let shapeUp = SCNAction.moveBy(x: 0, y: 0.03, z: 0, duration: 0.5)
        shapeUp.timingMode = .easeInEaseOut
        let shapeDown = shapeUp.reversed()
        
        let upDown = SCNAction.sequence([shapeUp, shapeDown])
        
        shapeNode.runAction(shapeSpin)
        shapeNode.runAction(upDown)
    }
    
    
    enum CardType: String {
        case king = "King"
        case queen = "Queen"
    }

}
