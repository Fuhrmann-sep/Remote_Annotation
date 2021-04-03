import ARKit
import SceneKit
import UIKit
import SceneKit.ModelIO

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        
        
//        // test
//        let mydata = "I like to eat food!".data(using: .utf8)
//        let mydata2 = "Tigers are a man's best friend".data(using: .utf8)
//
//        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
//        let fURL = dir.appendingPathComponent("hello.txt", isDirectory: false)
//
//        NSLog(fURL.absoluteString)
//
//        do {
//            if !FileManager.default.fileExists(atPath: fURL.absoluteString) {
//                let createdFile = FileManager.default.createFile(atPath: fURL.path, contents: mydata2!, attributes: nil)
//                NSLog("File created? \(createdFile)")
//            }
//
//
//
//        } catch {
//            NSLog(error.localizedDescription)
//        }
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the AR experience
        resetTracking()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("Look around to detect images", inSeconds: 7.5, messageType: .contentPlacement)
        
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.showsStatistics = true
        self.sceneView.session.run(configuration)
        
	}

    /// MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        let rotationAroundX = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 0, -1, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
        self.session.setWorldOrigin(relativeTransform: imageAnchor.transform * rotationAroundX)
        updateQueue.async {
            self.addNode()
        }
        
        
        // display something
        DispatchQueue.main.async {
            let imageName = referenceImage.name ?? ""
            self.statusViewController.cancelAllScheduledMessages()
            self.statusViewController.showMessage("Detected image “\(imageName)”")
        }
    }

    // fade in and fade out
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }
    
    /// MARK: - load the 3D object from URL
    
    
//    func addNode() {
//        guard let url = URL.init(string: "http://MacBook-Pro-Yanmei.local/ARKit/Jellyfish.obj") else { return}
////        let request = URLRequest(url: url!)
//        let task = URLSession.shared.dataTask(with: url) {data, response, error in
//            if error != nil {
//                self.displayErrorMessage(title: "Error", message: "error happened while build task")
//                return
//            } else {
//                guard let httpResponse = response as? HTTPURLResponse,
//                    (200...299).contains(httpResponse.statusCode) else {
//                    self.displayErrorMessage(title: "Error", message: "statusCode error happened")
//                    return
//                }
//                do {
//                   let scene = try SCNScene(url: url, options: nil)
//                   let jellyfishNode = scene.rootNode.childNode(withName: "Jellyfish", recursively: false)
//
//                   jellyfishNode?.position = SCNVector3(0, 0, 0)
//                   let scaleFactor  = 0.1
//                    jellyfishNode?.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
//                    self.sceneView.scene.rootNode.addChildNode(jellyfishNode!)
//
//                } catch {print("ERROR loading scene")}
//            }
//
//        }
//        task.resume()
//    }
    
    /// temporary answer 08.02.2021
    func addNode() {
        print("addNode start")
        guard let serverModelURL = URL.init(string: "http://MacBook-Pro-Yanmei.local/ARKit/obj_scan.obj") else { return}
        let task = URLSession.shared.downloadTask(with: serverModelURL) {tmpLocation, responds, error in
            guard let tmpLocation = tmpLocation else {
                // handler error
                return
            }
            print("task start")
            let localModelName = "Jellyfish.obj"
            let localModelURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(localModelName)

            // copy
            do {
                if FileManager.default.fileExists(atPath: localModelURL.path) {
                    try FileManager.default.removeItem(at: localModelURL)
                }

                try FileManager.default.moveItem(at: tmpLocation, to: localModelURL)
                print("Successfully Copied File \(localModelURL)")

                // load the model from local url
//                self.loadModel()
            } catch {
                // handler error
                print("Error Copying: \(error)")
            }

            let asset = MDLAsset(url: localModelURL)
            guard let object = asset.object(at: 0) as? MDLMesh else {
                fatalError("Failed to get mesh file from asset.")
            }
            let scene = SCNScene(mdlAsset: asset)
//            let jellyfishNode = scene.rootNode.childNode(withName: "Jellyfish", recursively: true)
            let jellyfishNode = SCNNode(mdlObject: object)
            jellyfishNode.position = SCNVector3(0, 0, 0)
            let scaleFactor = 0.1
            jellyfishNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
            self.sceneView.scene.rootNode.addChildNode(jellyfishNode)

        }
        task.resume()
    }
    
    




/// Downloads An SCNFile From A Remote URL

//    func addNode() {
////        let jellyFishScene = SCNScene(named: "art.scnassets/Jellyfish.scn")
////        let jellyfishNode = jellyFishScene?.rootNode.childNode(withName: "Jellyfish",
////                                                               recursively: false)
////        jellyfishNode?.position = SCNVector3(0, 0, 0)
//////        jellyfishNode?.eulerAngles.x = -.pi / 2
////        let scaleFactor  = 0.1
////        jellyfishNode!.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
////        self.sceneView.scene.rootNode.addChildNode(jellyfishNode!)
//
//        // "/Library/WebServer/Documents/ARKit/Jellyfish.scn"
//        //
//        let url = URL.init(string: "http://MacBook-Pro-Yanmei.local/ARKit/Jellyfish.obj")
//        let request = URLRequest(url: url!)
//        let downloadTask = URLSession.shared.downloadTask(with: request,
//                completionHandler: {(location:URL?, response:URLResponse?, error:Error?)
//                -> Void in
//                print("location:\(String(describing: location))")
//                let locationPath = location!.path
//                let documents:String = NSHomeDirectory() + "/Documents/Jellyfish.obj"
////                ls = NSHomeDirectory() + "/Documents"
//                let fileManager = FileManager.default
//                if (fileManager.fileExists(atPath: documents)){
//                     try! fileManager.removeItem(atPath: documents)
//                }
//                try! fileManager.moveItem(atPath: locationPath, toPath: documents)
//                print("new location:\(documents)")
////                let node = SCNNode()
//
//                do {
//                   let scene = try SCNScene(url: URL(fileURLWithPath: documents), options: nil)
//                   let jellyfishNode = scene.rootNode.childNode(withName: "Jellyfish", recursively: false)
//
//                   jellyfishNode?.position = SCNVector3(0, 0, 0)
//                   let scaleFactor  = 0.1
//                   jellyfishNode!.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
//                   self.sceneView.scene.rootNode.addChildNode(jellyfishNode!)
//
////                   node.addChildNode(jellyfishNode!)
//
//                } catch {print("ERROR loading scene")}
////                let scene = try SCNScene(url: URL(fileURLWithPath: documents), options: nil)
////                let scene =  SCNScene(named:"Jellyfish.scn", inDirectory: ls)
//
//
//
////                let nodeArray = scene!.rootNode.childNodes
////                for childNode in nodeArray {
////                    node.addChildNode(childNode as SCNNode)
////                }
////                 self.addChildNode(node)
////                 self.modelLoaded = true
//        })
//        downloadTask.resume()
//
//    }
}


