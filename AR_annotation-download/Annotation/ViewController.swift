import UIKit
import RealityKit
import SceneKit
import ARKit
import Alamofire
import SceneKit.ModelIO

extension String {
    func color() -> UIColor? {
        switch(self){
        case "red":
            return UIColor.red
        case "blue":
            return UIColor.blue
        case "green":
            return UIColor.green
        case "black":
            return UIColor.black
        case "yellow":
            return UIColor.yellow
        default:
            return nil
        }
    }
}

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var statusText: UILabel!
    

    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    
    
    var session: ARSession {
        return sceneView.session
    }
    
    var color = UIColor.red
    var colorName = "red"
    var anno_on = true
    
    
    
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
            if let data = text.data(using: .utf8) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
                    return json
                } catch {
                    print("Something went wrong")
                }
            }
            return nil
        }
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
//        // Hook up status view controller callback(s).
//        statusViewController.restartExperienceHandler = { [unowned self] in
//            self.restartExperience()
//        }
        
        setupARview()
        
        // Setup Tap Recognizer
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let panToDrawGesture = UIPanGestureRecognizer(target: self, action: #selector(createNodesfromPan))
        self.sceneView.addGestureRecognizer(panToDrawGesture)
        

        /// set a timer
        var downTimer: Timer?
        downTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(downloadAnno), userInfo: nil, repeats: true)
    }
    
    let dictURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    @objc func downloadAnno() -> Void{
        let toDownloadName = String(Int(currentTimeStamp())!-1) + ".json"
        print("to Download: "+toDownloadName)
//        let fileURL = dictURL.appendingPathComponent(toDownloadName, isDirectory: false)
        let fileURL = dictURL.appendingPathComponent(toDownloadName, isDirectory: false)
        let destination: DownloadRequest.Destination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
            
        
        AF.download("http://192.168.1.72:8000/media/documents/2021/02/15/"+toDownloadName, to: destination).response { response in
//                debugPrint(response)
        }
//        sleep(0.25)
        let seconds = 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            // Put your code which should be executed with a delay here
            if !FileManager.default.fileExists(atPath: fileURL.path) {
    //                    let createdFile = FileManager.default.createFile(atPath: fileURL.path, contents: content, attributes: nil)
    //                    NSLog("File created? \(createdFile)")
                        print("didnot download")
                    }
            
            let data_ = FileManager.default.contents(atPath: fileURL.path)
            do {
//                let dictionary = try JSONSerialization.jsonObject(with: data_!)
//                let updateHandle = FileHandle.init(forUpdatingAtPath: fileURL.path)
                
                let dictionary = try! String.init(contentsOfFile: fileURL.path)
//                updateHandle?.seekToEndOfFile()
//                updateHandle!.write(constent)
                
//                print("downloaded file: ")
//                print(dictionary)
                
                let pointList = dictionary.components(separatedBy: "}{")
                        let maxIndex = pointList.count - 1
                        var pointString: String
                        
                self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                    if node.name == "annotation" {
                        node.removeFromParentNode()
                    }
                })
                self.statusText.text = "Annotation cleared"
                
                        for (offset, point) in pointList.enumerated(){
                            switch offset {
                            case 0:
                                pointString = point+"}"
                            case maxIndex:
                                pointString = "{" + point
                            default:
                                pointString = "{" + point + "}"
                            }
                            
//                            print(pointString)
                            let pointDict = self.convertStringToDictionary(text: pointString)
//                            print(result?["z"])
//                            print(pointDict)
                            if (pointDict != nil) {
                                print("start drawing")
                                let node = SCNNode(geometry: SCNSphere(radius: 0.0005))
                                node.name = "annotation"
                                let color = pointDict!["color"] as! String
                                node.geometry?.firstMaterial?.diffuse.contents = color.color()
////                                var anno_x = hitTestResults.first?.worldCoordinates.x ?? 0.0
//                                let x = CGFloat.init(pointDict!["x"])
//                                var y = CGFloat(pointDict!["y"])
//                                var z = CGFloat(pointDict!["z"] )
//                                print("x: ")
//                                node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                                let x = pointDict!["x"] as! String
                                let y = pointDict!["y"] as! String
                                let z = pointDict!["z"] as! String
                                print(x)
//
                                node.position = SCNVector3(Double(x)!, Double(y)!, Double(z)!)
                                
                                self.sceneView.scene.rootNode.addChildNode(node)
                            }
                            
                        }
            } catch {
                print(error)
            }
        }
    }
    
    

    
    // MARK: Setup Methods
    func setupARview(){
      
        // set up AR view, can disable the DebugOptions
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical] // both plane detection
        configuration.environmentTexturing = .automatic // make it more realistic
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        sceneView.session.run(configuration)
        
    }
    
    func addObject() {

        // Add the object at the given 3D position
        guard let ObjectScene = SCNScene(named: "art.scnassets/mesh_colored2.scn"),
            let ObjectNode = ObjectScene.rootNode.childNode(withName: "700_chair_0", recursively: false)
        else {
            self.statusText.text = "Cannot load model"
            return
        }
        ObjectNode.position = SCNVector3(0, 0, 0)
        let scaleFactor  = 0.3
        ObjectNode.eulerAngles.y = .pi
        ObjectNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        
        ObjectNode.name = "model"
        
        self.statusText.text = "Model loaded"
        sceneView.scene.rootNode.addChildNode(ObjectNode)
    }
    
    struct Point: Codable {
        let color: String
        let position: [Float]
    }
    
    func addAnno(x: Float = 0, y: Float = 0, z: Float = 0) {
        // Add annotation point at given position and given color, the label is "annotation"
        let node = SCNNode(geometry: SCNSphere(radius: 0.0005))
        node.name = "annotation"
        node.geometry?.firstMaterial?.diffuse.contents = color
        node.position = SCNVector3(x,y,z)
        self.sceneView.scene.rootNode.addChildNode(node)

        
        let array = ["color": colorName,
                     "x": x.description,
                     "y": y.description,
                     "z": z.description]
//        print(array)
        
        // json to Data
        let constent = try! JSONSerialization.data(withJSONObject: array,
                                               options: JSONSerialization.WritingOptions.prettyPrinted)
        
//        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = dictURL.appendingPathComponent("annatation_file.json", isDirectory: false)
        let updateHandle = FileHandle.init(forUpdatingAtPath: fileURL.path)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let createdFile = FileManager.default.createFile(atPath: fileURL.path, contents: constent, attributes: nil)
            NSLog("File created? \(createdFile)")
        } else {
            updateHandle?.seekToEndOfFile()
            updateHandle!.write(constent)
        }
    }
    
    func uploadFromURL(fromURLString urlString: String) -> Void {
        print("upload from URL is called")
        let dictURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        let fileURL = dictURL.appendingPathComponent("annatation_file.json", isDirectory: false) // name 固定
        if FileManager.default.fileExists(atPath: fileURL.path) {
            print("did exist")
            let jsonFile = FileManager.default.contents(atPath: fileURL.path)!
            let headers: HTTPHeaders = [
                    /* "Authorization": "your_access_token",  in case you need authorization header */
                    "Content-type": "multipart/form-data"
                ]

            AF.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(jsonFile, withName: "docfile" , fileName: self.currentTimeStamp()+".json") // name 变化
            },
                to: "http://192.168.1.72:8000/", method: .post , headers: headers)
                .response { resp in
                    print(resp)
            }
        }
    
    }
    
    func currentTimeStamp() -> String {
        let date = Date()
        let time = date.timeIntervalSince1970
        let result = String(format: "%.0f", time)
        print("result:" + result)
        return result
    }

    
  
    
    
    
    
    @IBAction func annoOrWipe(_ sender: UISegmentedControl) {
        // Add annotation or wipe annotation
        if sender.selectedSegmentIndex == 0{
            anno_on = true
        }else if sender.selectedSegmentIndex == 1{
            anno_on = false
        }
    }
    @IBAction func annoOrNot(_ sender: UISegmentedControl) {
        // wrong name: actually it is color switch
        // Select color
        if sender.selectedSegmentIndex == 0{
            color = UIColor.red
            colorName = "red"
        }else if sender.selectedSegmentIndex == 1{
            color = UIColor.green
            colorName = "green"
        }else if sender.selectedSegmentIndex == 2{
            color = UIColor.black
            colorName = "black"
        }else if sender.selectedSegmentIndex == 3{
            color = UIColor.yellow
            colorName = "yellow"
        }else if sender.selectedSegmentIndex == 4{
            color = UIColor.blue
            colorName = "blue"
        }
        
    }
    @IBAction func placeObject(_ sender: Any) {
        addObject()
    }
    
    @IBAction func clearContent(_ sender: Any) {
        // Clear nodes with label "annotation"
        self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
            if node.name == "annotation" {
                node.removeFromParentNode()
            }
        })
        self.statusText.text = "Annotation cleared"
        
        
        
        // delete file
        let dictURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        let fileURL = dictURL.appendingPathComponent("anno.json", isDirectory: false)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let writeHandle = FileHandle.init(forWritingAtPath: fileURL.path)
            writeHandle?.truncateFile(atOffset: 0)
            print("delete successfully")
            let string = try! String.init(contentsOfFile: fileURL.path)
            print(string)
        }
    }

    
    
    @objc func createNodesfromPan(_gesture: UIPanGestureRecognizer){
        
        // 2D position of screen, generate a ray
        let currentPosition = _gesture.location(in: self.sceneView)
        let hitTestResults = self.sceneView.hitTest(currentPosition, options: nil)

        // if the ray hit the model, then add annotation node.
        if hitTestResults .isEmpty{
            self.statusText.text = "No hit result"
            return
        }else{
            
            if anno_on == true {
                self.statusText.text = "Annotating"
                
                let tappednode = hitTestResults.first?.node
                
                if tappednode?.name == "model" {
                    
                    var anno_x = hitTestResults.first?.worldCoordinates.x ?? 0.0
                    var anno_y = hitTestResults.first?.worldCoordinates.y ?? 0.0
                    var anno_z = hitTestResults.first?.worldCoordinates.z ?? 0.0
                    
                    addAnno(x: anno_x, y: anno_y, z: anno_z)
                }else{
                    self.statusText.text = "Annotate not on model"
                }
                
            } else if anno_on == false{
                
                let tappednode = hitTestResults.first?.node
                
                self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                    if node == tappednode && node.name == "annotation" {
                        node.removeFromParentNode()
                    }
                })
                self.statusText.text = "Annotation cleared"
            }
        }
        
    }
    
    
    @objc func didTap(withGestureRecognizer recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation)
        
        if hitTestResults .isEmpty{
            self.statusText.text = "No hit result"
            return
        }else{
            
            if anno_on == true {
                self.statusText.text = "Annotating"
                
                let tappednode = hitTestResults.first?.node
                
                if tappednode?.name == "model" {
                    
                    var anno_x = hitTestResults.first?.worldCoordinates.x ?? 0.0
                    var anno_y = hitTestResults.first?.worldCoordinates.y ?? 0.0
                    var anno_z = hitTestResults.first?.worldCoordinates.z ?? 0.0
                    
                    addAnno(x: anno_x, y: anno_y, z: anno_z)
                }else{
                    self.statusText.text = "Annotate not on model"
                }
                
            } else if anno_on == false{
                
                let tappednode = hitTestResults.first?.node
                
                self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                    if node == tappednode && node.name == "annotation" {
                        node.removeFromParentNode()
                    }
                })
                self.statusText.text = "Annotation cleared"
            }
        }
        
    }

}

