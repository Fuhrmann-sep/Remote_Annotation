import UIKit
import RealityKit
import ARKit
import Alamofire
import Foundation


class ViewController: UIViewController {
    
    var color = UIColor.red
    var colorName = "red"
    var anno_on = true
    
    @IBOutlet weak var statusText: UILabel!
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupARview()
        
        // Setup Tap Recognizer
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let panToDrawGesture = UIPanGestureRecognizer(target: self, action: #selector(createNodesfromPan))
        self.sceneView.addGestureRecognizer(panToDrawGesture)
        

        /// set a timer
        
        var upTimer: Timer?
        upTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(uploadAnno), userInfo: nil, repeats: true)
        
//        var downTimer: Timer?
//        downTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(downloadAnno), userInfo: nil, repeats: true)

    }
    
    let dictURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    let fileURL = dictURL.appendingPathComponent("annatation_file.json", isDirectory: false)
    
//    var fileName: String
//    let fileName = "Anno" + "-" + self.currentTimeStamp()+".json"
        
    @objc func uploadAnno(){
        print("upload")
//        let fileName = "Anno" + "-" + currentTimeStamp()+".json"
//        print(fileName)
        let fileURL = dictURL.appendingPathComponent("annatation_file.json", isDirectory: false)
        let string = try! String.init(contentsOfFile: fileURL.path)
        print("待检查： "+string)
        uploadFromURL(fromURLString: fileURL.path)
        
    }
    
    @objc func downloadAnno() -> Void{
        let toDownloadName = String(Int(currentTimeStamp())!-1) + ".json"
        print("to Download: "+toDownloadName)
//        let fileURL = dictURL.appendingPathComponent(toDownloadName, isDirectory: false)
        let fileURL = dictURL.appendingPathComponent(toDownloadName, isDirectory: false)
        let destination: DownloadRequest.Destination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
            
   
        AF.download("http://192.168.1.72:8000/media/documents/2021/02/11/"+toDownloadName, to: destination).response { response in
//                debugPrint(response)
        }
//        sleep(0.25)
        let seconds = 4.0
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
                
//                let pointList = dictionary.components(separatedBy: "}{")

//                print("downloaded file: ")
//                print(dictionary)
            } catch {
                print(error)
            }
        }
        
//        let data_ = FileManager.default.contents(atPath: fileURL.path)
//        do {
//            let dictionary = try JSONSerialization.jsonObject(with: data_!)
//            print("downloaded file: ")
//            print(dictionary)
//        } catch {
//            print(error)
//        }
        
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
    
    func addObject(x: Float = 0, y: Float = 0, z: Float = 0) {

        // Add the object at the given 3D position
        guard let ObjectScene = SCNScene(named: "art.scnassets/mesh_colored2.scn"),
            let ObjectNode = ObjectScene.rootNode.childNode(withName: "700_chair_0", recursively: false)
        else {
            self.statusText.text = "Cannot load model"
            return
        }
        ObjectNode.position = SCNVector3(x,y,z)
        ObjectNode.eulerAngles.y = .pi
        let scaleFactor  = 0.3
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
        
        
        /// write to file from url
//        print("start writing")
//        let fileURL = URL.init(string: "http://MacBook-Pro-Yanmei.local/ARKit/annotation.txt")!
//        let writeHandle = try! FileHandle.init(forWritingTo: fileURL)
//        writeHandle.seekToEndOfFile()
//        let content = Data("test".utf8)
//        writeHandle.write(content)
//        print("writing successfully")
        
        
//        print("start writing")
//
////        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//        let name = "annotation"
//        let input = colorName + "," + x.description
//        let array = input.components(separatedBy: ",")
//        print(array)
//        let content = Data("test".utf8)
//        let content2 = Data(input.utf8)
//
//        let dictURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
//        let fileURL = dictURL.appendingPathComponent("annotation.txt", isDirectory: false)
//
//        if !FileManager.default.fileExists(atPath: fileURL.path) {
//            let createdFile = FileManager.default.createFile(atPath: fileURL.path, contents: content, attributes: nil)
//            NSLog("File created? \(createdFile)")
//        }
//
//
//        let writeHandle = FileHandle.init(forUpdatingAtPath: fileURL.path)
////        writeHandle?.seekToEndOfFile()
////        writeHandle!.write(content)
//        writeHandle?.seekToEndOfFile()
//        writeHandle!.write(content2)
//        print("writing successfully")
//
//        let string = try! String.init(contentsOfFile: fileURL.path)
//        print(string)
//
//        writeHandle?.seek(toFileOffset: 0)
////        let data1 = writeHandle?.readData(ofLength: 1)
////        let readStr1 = String.init(data: data1!, encoding: String.Encoding.utf8)
////        print(readStr1!)
//        let out1 = writeHandle?.readDataToEndOfFile()
//        let readStr2 = String.init(data: out1!, encoding: String.Encoding.utf8)
//        print(readStr2!)
        
        let array = ["color": colorName,
                     "x": x.description,
                     "y": y.description,
                     "z": z.description]
//        print(array)
//
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
        
//        // output
//        let string = try! String.init(contentsOfFile: fileURL.path)
//        print(string)
        
//        let dictURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
//        let fileURL = dictURL.appendingPathComponent("annotation.json", isDirectory: false)
//        if !FileManager.default.fileExists(atPath: fileURL.path) {
//            let createdFile = FileManager.default.createFile(atPath: fileURL.path, contents: content, attributes: nil)
//            NSLog("File created? \(createdFile)")
//        }
//        try! constent.write(to: fileURL, options: .atomic)
        
        
        
            

    }
    
    func uploadFromURL(fromURLString urlString: String) -> Void {
        print("upload from URL is called")
//        let dictURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
//        let fileURL = dictURL.appendingPathComponent("annatation_file.json", isDirectory: false) // name 固定
        if FileManager.default.fileExists(atPath: urlString) {
            print("did exist")
            let string = try! String.init(contentsOfFile: urlString)
            print(string)
            let jsonFile = FileManager.default.contents(atPath: urlString)!
            let headers: HTTPHeaders = [
                    /* "Authorization": "your_access_token",  in case you need authorization header */
                    "Content-type": "multipart/form-data"
                ]
//            print("check: upload name: ")
//            print(self.currentTimeStamp()+".json")
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
        let fileURL = dictURL.appendingPathComponent("annatation_file.json", isDirectory: false)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let writeHandle = FileHandle.init(forUpdatingAtPath: fileURL.path)
            writeHandle?.truncateFile(atOffset: 0)
            let input = " "
            let input_data = Data(input.utf8)
            writeHandle!.write(input_data)
            
            print("delete successfully")
            let string = try! String.init(contentsOfFile: fileURL.path)
//            print(string)
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

