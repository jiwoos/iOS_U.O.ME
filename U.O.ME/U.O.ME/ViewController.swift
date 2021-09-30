import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class ViewController: UIViewController {
//    submit
    let ref = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTF.isHidden = true
        usernameLabel.isHidden = true
        usernameTF.autocorrectionType = .no
        passwordTF.autocorrectionType = .no
        passwordTF.isSecureTextEntry = true
        emailTF.autocorrectionType = .no
        profileImageView.isHidden = true
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        profileImageView.image = UIImage(named: "addPhoto")
        uomeLabel.layer.cornerRadius = 15
        processView.layer.cornerRadius = 15
        continueButton.layer.cornerRadius = 15
        profileImageView.addGestureRecognizer(tapGesture)
        profileImageView.isUserInteractionEnabled = true
        circularProfilePic()
        
        navigationController?.navigationBar.barTintColor = UIColor(red: 0.85, green: 0.92, blue: 0.91, alpha: 1.00)
        self.tabBarController?.tabBar.barTintColor = UIColor(red: 0.85, green: 0.92, blue: 0.91, alpha: 1.00)
            
    }
    
    func circularProfilePic() {
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.masksToBounds = false
        profileImageView.layer.borderColor = UIColor.black.cgColor
        profileImageView.layer.cornerRadius = profileImageView.frame.height/2
        profileImageView.clipsToBounds = true
    }
    
    var image:UIImage? = nil
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    var imagePicker:UIImagePickerController!
    var loginSegment:Bool = true
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var uomeLabel: UIView!
    @IBOutlet weak var processView: UIView!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBAction func loginOrRegister(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex
        {
        case 0:
            profileImageView.isHidden = true
            usernameTF.isHidden = true
            usernameLabel.isHidden = true
            loginSegment = true
        case 1:
            profileImageView.isHidden = false
            usernameTF.isHidden = false
            usernameLabel.isHidden = false
            loginSegment = false
        default:
            break
        }
    }
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        print("continue button is tapped")
        if loginSegment == true {// if it is login,
            guard let email = emailTF.text, !email.isEmpty,
                let password = passwordTF.text, !password.isEmpty else {
                    print("Missing field data")
                    alertMessage(message: "Missing field data")
                    return
            }
            
            FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { result, error in
                guard error == nil else {
                    print("no such user is found")
                    self.alertMessage(message: "user not found")
                    return
                }
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let mainTabBarController = storyboard.instantiateViewController(identifier: "MainTabBarController")
                
                // This is to get the SceneDelegate object from your view controller
                // then call the change root view controller function to change to main tab bar
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainTabBarController)
                print("You have signed in")
            })
        }
        else { // if continue to register
            if image == nil {
                print ("choose photo")
                self.alertMessage(message: "pick a profile picture")
                return
            }
            guard let email = emailTF.text, !email.isEmpty,
                let password = passwordTF.text, !password.isEmpty,
                let username = usernameTF.text, !username.isEmpty else {
                    print("Missing field data")
                    self.alertMessage(message: "Missing field data")
                    return
            }
            ref.child("/takenUsernames/").observeSingleEvent(of: .value){
                (snapshot) in
                let data = snapshot.value as! [String:Any]
                let keys = data.keys
                if(keys.contains(username)){
                    print("Duplicate username, not registered")
                    self.alertMessage(message: "username *\(username)* already exists")
                    return
                }
                else {
                    
                    FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { result, error in
                        guard error == nil else {
                            print("Account Registration Failed")
                            self.alertMessage(message: "Account Registration Failed: email might exist/password should be longer")
                            return
                        }
                        
                        guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
                        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
                        
                        let userref = self.ref.child("/users/").child(uid)
                        var values: Dictionary<String, Any> = [
                            "username": username,
                            "email": email,
                            "profilePicURL": ""
                        ]
                        
                        
                        let storageRef = Storage.storage().reference(forURL: "gs://final-project-591d1.appspot.com")
                        let storageProfileRef = storageRef.child("profile").child(uid)
                        
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
                                        values["profilePicURL"] = metaImageURL
                                        print(metaImageURL)
                                        
                                        userref.updateChildValues(values, withCompletionBlock: { error, ref in
                                            if error != nil{
                                                print("ERROR")
                                            }
                                        })
                                        self.ref.child("/friends/\(username)/default").setValue(0)
                                        self.ref.child("/takenUsernames/\(username)").setValue(1)
                                    }
                                })
                        })
                        self.performSegue(withIdentifier: "regiComplete", sender: self)
                        print("Registration complete")
                    })
                }
            }
        }
        
    }
    @IBAction func profilePhotoTapped(_ sender: UITapGestureRecognizer) {
        print("image Tapped")
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func alertMessage(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler : nil )
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let imageSelected = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        profileImageView.image = imageSelected
        image = imageSelected
        view.sendSubviewToBack(profileImageView)
        imagePicker.dismiss(animated:true, completion: nil)
    }
}
