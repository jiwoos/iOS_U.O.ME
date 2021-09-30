//
//  ReceiptViewController.swift
//  U.O.ME
//
//  Created by Owen Ricketts on 7/20/20.
//  Copyright © 2020 Christie Chen. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseStorage

class ReceiptViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imgPickerCtrl:UIImagePickerController = UIImagePickerController()
    var imageSelected:UIImage? = nil
    var receiptCount:Int? = nil
    let ref = Database.database().reference()
    var date = ""
    var merchant = ""
    var subtotal = 0.0
    var tax = 0.0
    var total = 0.0
    var state = "add"
    var editReceipt = ""
    
   
    @IBOutlet weak var dateLabel: UITextField!
    @IBOutlet weak var merchantLabel: UITextField!
    @IBOutlet weak var subtotalLabel: UITextField!
    
    @IBOutlet weak var totalLabel: UITextField!
    
    
    @IBOutlet weak var taxLabel: UITextField!
    @IBOutlet weak var receiptImage: UIImageView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var submittedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        spinner.hidesWhenStopped = true
        submittedLabel.isHidden = true
        submitButton.layer.cornerRadius = 15
    }
    override func viewDidAppear(_ animated: Bool) {
        submittedLabel.isHidden = true
        if(state == "edit"){
            guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else {
                       return
                   }
            let userReceipts = self.ref.child("/users/").child(uid).child("/receipts/").child(editReceipt)
            userReceipts.observeSingleEvent(of: .value, with: { (snapshot) in
                let data = snapshot.value as? [String : Any]
                self.date = data?["Date"] as? String ?? ""
                self.merchant = data?["Merchant"] as? String ?? ""
                self.subtotal = data?["Subtotal"] as? Double ?? 0.0
                self.tax = data?["Tax"] as? Double ?? 0.0
                self.total = data?["Total"] as? Double ?? 0.0
                let imgURL = data?["imageURL"] as? String ?? ""
                let fileURL = URL(string: imgURL)
                let placeholderImg = UIImage(named: "loading")
                self.receiptImage.sd_setImage(with: fileURL, placeholderImage: placeholderImg)
                if imgURL == "" {
                    self.receiptImage.image = UIImage(named: "noPhoto")
                }
                DispatchQueue.main.async{
                    self.loadTextFields()
                }
            })
        }
    }
    
    
    @IBAction func submitReceipt(_ sender: Any) {
        spinner.startAnimating()
        let d = dateLabel.text ?? ""
        let m = merchantLabel.text ?? ""
        let s = Double(self.subtotalLabel.text ?? "") ?? 0
        let ta = Double(self.taxLabel.text ?? "") ?? 0
        let to = Double(self.totalLabel.text ?? "") ?? 0
        DispatchQueue.global(qos: .userInitiated).async {
            self.addToDatabase(d, m, s, ta, to)
            DispatchQueue.main.async {
                self.submitButton.isHidden = true
                self.submittedLabel.isHidden = false
                self.spinner.stopAnimating()
                
            }
        }
    }
    
    @IBAction func buttonClick(_ sender: Any) {
        
        imgPickerCtrl.delegate = self
        let actionSheet = UIAlertController(title: "Photo source", message:"Choose a source", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "camera", style: .default, handler: {(actions:UIAlertAction) in
            if(UIImagePickerController.isSourceTypeAvailable(.camera)){
                self.imgPickerCtrl.sourceType = .camera
                self.present(self.imgPickerCtrl, animated: true, completion: nil)
            }
            else{
                print("cam not available")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "photo library", style: .default, handler: {(actions:UIAlertAction) in
            self.imgPickerCtrl.sourceType = .photoLibrary
            self.present(self.imgPickerCtrl, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else{
            return self.imagePickerControllerDidCancel(imgPickerCtrl)
        }
        receiptImage.image = image
        imageSelected = image
        picker.dismiss(animated: true)
        var textData:String?
        var textArray:[String]?
        spinner.startAnimating()
        callOCRSpace(image:image, userCompletionHandler: {text, error in
            if let text = text{
                textData = text
                textData = textData?.replacingOccurrences(of: "\r", with: "")
                textArray = textData?.components(separatedBy: "\n")
                self.setupView(textArray: textArray!, text: textData!)
                DispatchQueue.main.async{
                    self.spinner.stopAnimating()
                    self.loadTextFields()
                }
            }
            
        })
       
        
    }
    
    func loadTextFields(){
        dateLabel.text = date
        merchantLabel.text = merchant
        subtotalLabel.text = String(subtotal)
        taxLabel.text = String(tax)
        totalLabel.text = String(total)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    
    func callOCRSpace(image: UIImage, userCompletionHandler: @escaping (String?, Error?) -> Void){
        // Create URL request
        let url = URL(string: "https://api.ocr.space/Parse/Image")
        var request: URLRequest? = nil
        if let url = url {
            request = URLRequest(url: url)
        }
        request?.httpMethod = "POST"
        let boundary = "randomString"
        request?.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        
        // Image file and parameters
        let imageData = image.jpegData(compressionQuality: 0.6)
        let parametersDictionary = ["apikey" : "cf0b372b1188957", "isOverlayRequired" : "True", "language" : "eng"]
        
        // Create multipart form body
        let data = createBody(withBoundary: boundary, parameters: parametersDictionary, imageData: imageData, filename: "receipt.jpg")
        
        request?.httpBody = data
        
        // Start data session
        var text:[[String:Any]] = []
        var str:String?
        var task: URLSessionDataTask? = nil
        if let request = request {
            task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                var result: [AnyHashable : Any]? = nil
                do {
                    if let data = data {
                        result = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable : Any]
                    }
                } catch let myError {
                    print(myError)
                    
                }
                if(result!["IsErroredOnProcessing"]! as! Int == 1){
                    print(result!["ErrorMessage"]!)
                    userCompletionHandler(nil,nil)
                }else{
                    text = result!["ParsedResults"] as! [[String:Any]]
                    str = text[0]["ParsedText"] as! String?
                    userCompletionHandler(str, nil)
                }
            })
            
        }
        task?.resume()
    }
    
    func createBody(withBoundary boundary: String?, parameters: [AnyHashable : Any]?, imageData data: Data?, filename: String?) -> Data? {
        var body = Data()
        if data != nil {
            if let data1 = "--\(boundary ?? "")\r\n".data(using: .utf8) {
                body.append(data1)
            }
            if let data1 = "Content-Disposition: form-data; name=\"\("file")\"; filename=\"\(filename ?? "")\"\r\n".data(using: .utf8) {
                body.append(data1)
            }
            if let data1 = "Content-Type: image/jpeg\r\n\r\n".data(using: .utf8) {
                body.append(data1)
            }
            if let data = data {
                body.append(data)
            }
            if let data1 = "\r\n".data(using: .utf8) {
                body.append(data1)
            }
        }
        
        for key in parameters!.keys {
            if let data1 = "--\(boundary ?? "")\r\n".data(using: .utf8) {
                body.append(data1)
            }
            if let data1 = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8) {
                body.append(data1)
            }
            if let parameter = parameters?[key], let data1 = "\(parameter)\r\n".data(using: .utf8) {
                body.append(data1)
            }
        }
        
        if let data1 = "--\(boundary ?? "")--\r\n".data(using: .utf8) {
            body.append(data1)
        }
        
        return body
    }
    
    
    
    
    func setupView(textArray: [String], text: String){
        var numbers:[Double] = []
        var merchant2 = ""
        if(text.count > 0){
            merchant2 = textArray[0]
        }
        else{
            return
        }
        
        do{
            let str = text as NSString
            let numRegex = try NSRegularExpression(pattern: "\\d+\\.\\d{1,2}")
            let dateRegex = try NSRegularExpression(pattern:"[0-9]{1,2}\\/[0-9]{1,2}\\/[0-9]{2,4}")
            
            let range = NSRange(location: 0, length: str.length)
            let results = numRegex.matches(in: text, options: [], range: range)
            let dateResults = dateRegex.matches(in:text, options: [], range:range)
            let dateArray = dateResults.map {str.substring(with: $0.range)}
            var date2 = ""
            if(dateArray.count > 0){
                date2 = dateArray[0]
            }
            let resultsArray = results.map {str.substring(with: $0.range)}
            for result in resultsArray{
                let num = Double(result)
                numbers.append(num!)
            }
            let total2 = numbers.max()
            let maxIndex = numbers.firstIndex(of: total2!)
            var subTotal = 0.0
            var tax2 = 0.0
            numbers.remove(at: maxIndex!)
            
            for i in 0..<numbers.count{
                for j in i+1..<numbers.count{
                    if(round((numbers[i]+numbers[j])*100)/100 == total2!){
                        subTotal = max(numbers[i],numbers[j])
                        tax2 = min(numbers[i], numbers[j])
                    }
                }
            }
            date = date2
            merchant = merchant2
            subtotal = subTotal
            tax = tax2
            total = total2!
        }
        catch{
            print(error)
        }
        
        
    }
    
    
    
    func addToDatabase(_ date: String, _ merchant: String, _ subtotal: Double, _ tax: Double, _ total: Double){
        guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else {
            return
        }
        
        let userReceipts = self.ref.child("/users/").child(uid).child("/receipts/")
       
        count(completion: {count in
            var values = ["Date": date, "Merchant": merchant, "Subtotal":subtotal, "Tax":tax, "Total" : total, "imageURL" : "", "deleted" : false] as [String : Any]
            
            
            var receiptPathName:String = ""
            if(self.state == "add"){
                receiptPathName = "receipt\(count+1)"
            }
            if(self.state == "edit"){
                receiptPathName = self.editReceipt
            }
            userReceipts.child(receiptPathName).updateChildValues(values, withCompletionBlock: { error, ref in
                if error != nil{
                    print("ERROR")
                }
            })
            
           
            guard let imageData = self.imageSelected?.jpegData(compressionQuality: 0.5) else { return }
            let storageRef = Storage.storage().reference(forURL: "gs://final-project-591d1.appspot.com")
            let storageProfileRef = storageRef.child("/personalReceipt/").child(uid).child(receiptPathName)
            
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"
            
            storageProfileRef.putData(imageData, metadata: metaData, completion:
                { (StorageMetadata, error ) in
                    if error != nil {
                        print("error")
                        return
                    }
                    storageProfileRef.downloadURL(completion: { (url, error) in
                        if let metaImageURL = url?.absoluteString {
                            values["imageURL"] = metaImageURL
                            print(metaImageURL)
            
                            userReceipts.child(receiptPathName).updateChildValues(values, withCompletionBlock: { error, ref in
                                if error != nil{
                                    print("ERROR")
                                }
                            })
                        }
                    })
            })
        })
        
    }
    
    func count(completion: @escaping(Int)->Void){
        guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else {
            return
        }
        var count: Int = 0;
        receiptCount = count
        let userReceipts = self.ref.child("/users/").child(uid).child("/receipts/")
        userReceipts.observeSingleEvent(of: .value){ (snapshot) in
            if let dict = snapshot.value as? [String:Any] {
                let receipts = dict.keys
                count = receipts.count
            }
            completion(count)
        }
        
    }
}
