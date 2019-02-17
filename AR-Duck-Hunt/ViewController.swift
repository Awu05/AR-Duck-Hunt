//
//  ViewController.swift
//  AR-Duck-Hunt
//
//  Created by Andy Wu on 2/16/19.
//  Copyright © 2019 Andy Wu. All rights reserved.
//

import UIKit
import ARKit

enum BitMaskCategory: Int {
    case bullet = 2
    case target = 3
}

class ViewController: UIViewController, SCNPhysicsContactDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var startProp: UIButton!
    let configuration = ARWorldTrackingConfiguration()
    var power: Float = 50
    var target: SCNNode?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(gestureRecognizer)
        self.sceneView.scene.physicsWorld.contactDelegate = self
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42 - 0.5, transform.m43)
        let position = orientation + location
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.1))
        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        bullet.position = position
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: bullet, options: nil))
        body.isAffectedByGravity = false
        bullet.physicsBody = body
        bullet.physicsBody?.applyForce(SCNVector3(orientation.x*power, orientation.y*power, orientation.z*power), asImpulse: true)
        bullet.physicsBody?.categoryBitMask = BitMaskCategory.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
        self.sceneView.scene.rootNode.addChildNode(bullet)
        bullet.runAction(SCNAction.sequence([SCNAction.wait(duration: 2.0), SCNAction.removeFromParentNode()]))
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue {
            self.target = nodeA
            self.spawnDuck()
            self.confetti(contact: contact)
        } else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeA.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue {
            self.target = nodeB
            self.spawnDuck()
            self.confetti(contact: contact)
        }
        
        self.target?.removeFromParentNode()
    }
    
    func confetti (contact: SCNPhysicsContact) {
        let confetti = SCNParticleSystem(named: "Media.scnassets/Confetti.scnp", inDirectory: nil)
        confetti?.loops = false
        confetti?.particleLifeSpan = 2
        confetti?.emitterShape = target?.geometry
        let confettiNode = SCNNode()
        confettiNode.addParticleSystem(confetti!)
        confettiNode.position = contact.contactPoint
        self.sceneView.scene.rootNode.addChildNode(confettiNode)
    }
    
    @IBAction func startBtn(_ sender: Any) {
        startGame()
    }
    
    func startGame() {
        self.placeGrass()
        self.placeDucks()
        self.startProp.isHidden = true

    }
    
    func placeGrass() {
        self.displayGrass(x: -11.5, y: -10, z: -40)
        self.displayGrass(x: -11, y: -10, z: -70)
        self.displayGrass(x: 0, y: -10, z: -40)
        self.displayGrass(x: 11, y: -10, z: -70)
        self.displayGrass(x: 11.5, y: -10, z: -40)
    }
    
    func placeDucks() {
        var i = 0
        
        while i < 10 {
            self.spawnDuck()
            
            i += 1
        }
    }
    
    func randomPosition() -> SCNVector3 {
        let x = Float.random(in: -11 ... 11)
        let y = Float.random(in: -10 ... 0)
        let z: Float = -50
        
        return SCNVector3(x,y,z)
    }
    
    func displayGrass(x: Float, y: Float, z: Float) {
        let grassScene = SCNScene(named: "Media.scnassets/grass.scn")
        let grassNode = (grassScene?.rootNode.childNode(withName: "grass", recursively: false))!
        grassNode.position = SCNVector3(x,y,z)
        self.sceneView.scene.rootNode.addChildNode(grassNode)
    }
    
    func spawnDuck() {
        let position = randomPosition()
        let x = position.x
        let y = position.y
        let z = position.z
        let duckScene = SCNScene(named: "Media.scnassets/duck.scn")
        let duckNode = (duckScene?.rootNode.childNode(withName: "duck", recursively: false))!
        duckNode.position = SCNVector3(x,y,z)
        duckNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: duckNode, options: nil))
        duckNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        duckNode.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
        self.randomMovement(node: duckNode)
        self.sceneView.scene.rootNode.addChildNode(duckNode)
    }
    
    func randomMovement(node: SCNNode) {
        let randNum = Int.random(in: 0 ... 3)
        
        switch randNum {
        case 0:
            // Move in X direction
            self.moveInXaxis(node: node, direction: 1)
            break;
        case 1:
            // Move in Y direction
            self.moveInYaxis(node: node, direction: 1)
            break;
        default:
            // Move in X & Y direction
            self.moveInXaxis(node: node, direction: 1)
            self.moveInYaxis(node: node, direction: 1)
            break;
        }
    }
    
    func moveInXaxis(node: SCNNode, direction: Int) {
        let moveAction = SCNAction.move(by: SCNVector3(20 * direction, 0, 0), duration: 10)
        node.runAction(moveAction, completionHandler: {
            self.moveInXaxis(node: node, direction: direction * -1)
        })
    }
    
    func moveInYaxis(node: SCNNode, direction: Int) {
        let moveAction = SCNAction.move(by: SCNVector3(0, 20 * direction, 0), duration: 10)
        node.runAction(moveAction, completionHandler: {
            self.moveInYaxis(node: node, direction: direction * -1)

        })
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}
