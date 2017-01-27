//
//  GameViewController.swift
//  ARDefenderTutorial
//
//  Created by STEFAN JOSTEN on 24/11/2016.
//  Copyright © 2016 Stefan. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import AVFoundation
import CoreLocation


class GameViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var scnView: SCNView!
    
    let leftDirectionArrow = UILabel()
    let rightDirectionArrow = UILabel()
    let cameraNode = SCNNode()
    var shipNode: SCNNode?
    var preview: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        shipNode = scene.rootNode.childNode(withName: "ship", recursively: true)!
        shipNode!.position = SCNVector3(x: 20, y: 0, z: -20)
        
        // set the scene to the view
        scnView.scene = scene
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.clear
        
        initializeDirectionArrows()
        initializeCompass()
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // create a capture session for the camera input
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto  
        
        // Choose the back camera as input device
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let cameraError as NSError {
            error = cameraError
            input = nil
        }
        
        // check if the camera input is available
        if error == nil && captureSession.canAddInput(input) {
            // ad camera input to the capture session
            captureSession.addInput(input)
            let photoImageOutput = AVCapturePhotoOutput()
            
            // Create an UIlayer with the capture session output
            photoImageOutput.photoSettingsForSceneMonitoring = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
            if captureSession.canAddOutput(photoImageOutput) {
                captureSession.addOutput(photoImageOutput)
                
                preview = AVCaptureVideoPreviewLayer(session: captureSession)
                preview?.videoGravity = AVLayerVideoGravityResizeAspectFill
                preview?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                preview?.frame = cameraView.frame
                cameraView.layer.addSublayer(preview!)
                captureSession.startRunning()
            }
        }
        
    }
    
    // Initialize the direction labels
    func initializeDirectionArrows() {
        leftDirectionArrow.text = "⬅️"
        rightDirectionArrow.text = "➡️"
        rightDirectionArrow.font = UIFont.boldSystemFont(ofSize: 45)
        leftDirectionArrow.font = UIFont.boldSystemFont(ofSize: 45)
        leftDirectionArrow.frame.size = CGSize(width: 50, height: 50)
        leftDirectionArrow.textAlignment = .center
        rightDirectionArrow.textAlignment = .center
        rightDirectionArrow.frame.size = CGSize(width: 50, height: 50)
        leftDirectionArrow.frame.origin = CGPoint(x: 10, y: self.view.frame.height / 2)
        rightDirectionArrow.frame.origin = CGPoint(x: self.view.frame.width - 10 - rightDirectionArrow.frame.size.width, y: self.view.frame.height / 2)
    }
    
    // Initialize compass
    func initializeCompass() {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
    }
    
    // Delegate method to handle location changes
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        // Rotate camera aroud the y axis:
        let angleInRad = CGFloat((M_PI * -newHeading.magneticHeading)/180) // Convert to Rad
        cameraNode.runAction(SCNAction.rotateTo(x: 0.0, y: angleInRad, z: 0.0, duration: 0.05, usesShortestUnitArc: true))
        
        // Hide the direction arrows in cas the ship is visible
        if scnView.isNode(shipNode!, insideFrustumOf: cameraNode) {
            if rightDirectionArrow.superview != nil {
                rightDirectionArrow.removeFromSuperview()
            }
            if leftDirectionArrow.superview != nil {
                leftDirectionArrow.removeFromSuperview()
            }
            
        } else {
            
            // Calculate the rotation angle between ship and camera view direction
            var angleOfShipToWorldInDegrees = Double(atan2((shipNode?.position.z)!, (shipNode?.position.x)!) * 180.0) / M_PI
            if angleOfShipToWorldInDegrees < 0 {
                angleOfShipToWorldInDegrees = 360 + angleOfShipToWorldInDegrees
            }
            
            let angleOfCameraToWorldInDegrees = (Double(cameraNode.rotation.w) * 180.0) / M_PI
            let angleDelta = angleOfCameraToWorldInDegrees - angleOfShipToWorldInDegrees
            
            // Show direction arrows
            if angleDelta < 0 && angleDelta > -180 {
                if leftDirectionArrow.superview == nil {
                    self.view.addSubview(leftDirectionArrow)
                }
                if rightDirectionArrow.superview != nil {
                    rightDirectionArrow.removeFromSuperview()
                }
            } else {
                if rightDirectionArrow.superview == nil {
                    self.view.addSubview(rightDirectionArrow)
                }
                if leftDirectionArrow.superview != nil {
                    leftDirectionArrow.removeFromSuperview()
                }
            }
            
        }
        
        
    }

}
