//
//  ViewController.swift
//  ARShots
//
//  Created by Mark Meretzky on 1/18/19.
//  Copyright © 2019 New York University School of Professional Studies. All rights reserved.
//

import UIKit;
import SceneKit;
import ARKit;

class ViewController: UIViewController, ARSCNViewDelegate {
    var hoopAdded: Bool = false; //p. 489: 1st tap creates hoop, subsequent taps create balls
    @IBOutlet var sceneView: ARSCNView!;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // Set the view's delegate.
        sceneView.delegate = self;
        
        // Show statistics such as fps and timing information.
        sceneView.showsStatistics = true;
        
        sceneView.debugOptions = [
            .showWorldOrigin      //red, green, blue axes, p. 457
        ];
        
        // Create a new scene containing an omni light.
        guard let scene: SCNScene = SCNScene(named: "art.scnassets/empty.scn") else {
            fatalError("couldn't find art.scnassets/hoop.scn");
        }
        
        // Set the scene to the view.
        sceneView.scene = scene;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        // Create a session configuration.
        let configuration: ARWorldTrackingConfiguration = ARWorldTrackingConfiguration();
        configuration.planeDetection = [.vertical];   //p. 484

        // Run the view's session.
        sceneView.session.run(configuration);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        
        // Pause the view's session.
        sceneView.session.pause();
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node: SCNScene = SCNNode();
        return node;
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {   //pp. 485-486, 488
        if hoopAdded {
            createBasketball();   //pp. 489-490
        } else {
            let touchLocation: CGPoint = sender.location(in: sceneView);
            let hitTestResult: [ARHitTestResult] = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent]);
            
            if let result: ARHitTestResult = hitTestResult.first {
                print("Ray intersected a discovered plane.");
                addHoop(result: result);
                hoopAdded = true;
            }
        }
    }
    
    func addHoop(result: ARHitTestResult) {   //pp. 486-487, 493
        // Retrieve the scene file and locate the "Hoop" node
        guard let hoopScene: SCNScene = SCNScene(named: "art.scnassets/hoop.scn") else {
           fatalError("couldn't find art.scnassets/hoop.scn");
        }

        guard let hoopNode: SCNNode = hoopScene.rootNode.childNode(withName: "Hoop", recursively: false) else {
            fatalError("couldn't find node Hoop in art.scnassets/hoop.scn");
        }

        guard let anchor: ARAnchor = result.anchor else {
            fatalError("ARHitTestResult had no anchor.");
        }
        
        // Place the hoopNode in the correct position and orientation.
        
        hoopNode.transform = SCNMatrix4(anchor.transform);
        hoopNode.eulerAngles.x -= Float.pi / 2;
        let position: simd_float4 = result.worldTransform.columns.3;
        hoopNode.position = SCNVector3(position.x, position.y, position.z);
        
        //Apply the correct physics body, p. 493.
        
        let options: [SCNPhysicsShape.Option: Any] = [
            SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron
        ];
        let shape: SCNPhysicsShape = SCNPhysicsShape(node: hoopNode, options: options);
        hoopNode.physicsBody = SCNPhysicsBody(type: .static, shape: shape);

        // Add the node to the scene.
        // The scaling in the Node Inspector, and the diffuse in the Material Inspector,
        // didn't work here.
        hoopNode.scale = SCNVector3(0.25, 0.25, 0.25); //small enough for Manhattan apartment
        sceneView.scene.rootNode.addChildNode(hoopNode);
    }
    
    func createBasketball() {   //pp. 488-489
        guard let currentFrame: ARFrame = sceneView.session.currentFrame else {
            fatalError("could not get current frame");
        }
        
        let geometry: SCNSphere = SCNSphere(radius: 0.25 * 0.25); //to match the small hoop
        if let firstMaterial: SCNMaterial = geometry.firstMaterial {
            firstMaterial.diffuse.contents = UIColor.orange;
        } else {
            fatalError("geometry.firstMaterial == nil");
        }

        let ball = SCNNode(geometry: geometry);
        let cameraTransform: SCNMatrix4 = SCNMatrix4(currentFrame.camera.transform);
        ball.transform = cameraTransform;
        let options: [SCNPhysicsShape.Option: Any] = [   //p. 493
            SCNPhysicsShape.Option.collisionMargin: 0.01
        ];
        ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball, options: options));
        let power: Float = 10.0;

        let force: SCNVector3 = SCNVector3(
            -cameraTransform.m31 * power,
            -cameraTransform.m32 * power,
            -cameraTransform.m33 * power
        );
    
        ball.physicsBody!.applyForce(force, asImpulse: true);
        sceneView.scene.rootNode.addChildNode(ball);
    }

}
