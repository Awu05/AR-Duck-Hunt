//
//  ViewController.swift
//  AR-Duck-Hunt
//
//  Created by Andy Wu on 2/16/19.
//  Copyright © 2019 Andy Wu. All rights reserved.
//

import UIKit
import ARKit
import Each
import CoreData

enum BitMaskCategory: Int {
    case bullet = 2
    case target = 3
}

class ViewController: UIViewController, SCNPhysicsContactDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var startProp: UIButton!
    @IBOutlet weak var textLbl: UILabel!
    @IBOutlet weak var numLbl: UILabel!
    @IBOutlet weak var saveScoreProp: UIBarButtonItem!
    
    
    let configuration = ARWorldTrackingConfiguration()
    var power: Float = 50
    var target: SCNNode?
    var timer = Each(1).seconds
    var countDown = 10
    var score = 0
    var showMenu = false
    var highScoreList = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(gestureRecognizer)
        self.sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        moreActionsBtn(self)
    }
    
    @IBAction func saveScoreBtn(_ sender: Any) {
        let alertController = UIAlertController(title: "Save Your SCore", message: "Please enter your name:", preferredStyle: .alert)
        alertController.addTextField { (_ textField:UITextField) -> Void in
            textField.placeholder = "Enter your name"
            textField.textAlignment = .center
            textField.textColor = UIColor.blue
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            if let name = alertController.textFields?.first?.text {
                print(alertController.textFields?.first?.text ?? "Could not read name!")
                self.saveScore(name: name, score: self.score)
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        self.present(alertController, animated: true, completion: nil)
        self.saveScoreProp.isEnabled = false
    }
    
    func saveScore(name: String, score: Int) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "HighScore", in: managedContext)!
        
        let highScore = NSManagedObject(entity: entity, insertInto: managedContext)
        
        highScore.setValue(name, forKey: "name")
        highScore.setValue(score, forKey: "score")
        
        do {
            try managedContext.save()
            highScoreList.append(highScore)
            print("Saved successfully!")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    @IBAction func moreActionsBtn(_ sender: Any) {
        self.showMenu = !self.showMenu
        
        if showMenu {
            self.leadingConstraint.constant = 0
        } else {
            self.leadingConstraint.constant = -140
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: { self.view.layoutIfNeeded() } )
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
        
        if (self.showMenu) {
            moreActionsBtn(self)
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue {
            self.target = nodeA
            self.spawnDuck()
            self.confetti(contact: contact)
            self.score += 1
        } else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeA.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue {
            self.target = nodeB
            self.spawnDuck()
            self.confetti(contact: contact)
            self.score += 1
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
        setTimer()
    }
    
    func startGame() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.restoreTimer()
        self.placeGrass()
        self.placeDucks()
        self.saveScoreProp.isEnabled = false
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
    
    func setTimer() {
        self.timer.perform{ () -> NextStep in
            self.countDown -= 1
            self.numLbl.text = String(self.countDown)
            if self.countDown == 0 {
                self.navigationController?.setNavigationBarHidden(false, animated: false)
                self.textLbl.text = "Your Score:"
                self.numLbl.text = String(self.score)
                self.reset()
                self.saveScoreProp.isEnabled = true
                return .stop
            }
            return .continue
        }
    }
    
    func restoreTimer() {
        self.textLbl.text = "Time Left:"
        self.countDown = 10
        self.numLbl.text = String(self.countDown)
    }
    
    func reset() {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        self.startProp.isHidden = false
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}
