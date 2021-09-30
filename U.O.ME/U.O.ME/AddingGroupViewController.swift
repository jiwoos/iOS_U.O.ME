//
//  AddingGroupViewController.swift
//  U.O.ME
//
//  Created by Anderson Gonzalez on 7/29/20.
//  Copyright © 2020 Christie Chen. All rights reserved.
//

import UIKit
import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class AddingGroupViewController: UIViewController ,UITableViewDelegate, UITableViewDataSource {
  
    let ref = Database.database().reference()
    var friends: [String] = []
    var theUser = ""
    var groupMembers: [String] =  []
    var people = ""
    var groupNameString = ""
    
    
    @IBOutlet weak var groupName: UITextField!
    
    @IBOutlet weak var friendsTable: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        friendsTable.register(UITableViewCell.self, forCellReuseIdentifier: "theFavorite")
        friendsTable.dataSource = self
        friendsTable.delegate = self
        getFriends()
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButton(_ sender: Any) {
        if groupName.text != nil && groupMembers.count != 0 && groupName.text != ""{
        let newGroupRef = self.ref.child("/groupData/").childByAutoId()
        let newGroupKey = newGroupRef.key!
        groupMembers.append(theUser)
        let people = groupMembers.joined(separator: ",")
        
        let newGroupInfo = ["name": groupName.text!, "people":people ] as [String: Any]
        
        //add group to the GroupData
        newGroupRef.setValue(newGroupInfo, withCompletionBlock:  {error, ref in
                   if error != nil{
                       print("ERROR")
                   }
               })
            
        //add group to individual users
        let usersRef = self.ref.child("/users")
        usersRef.observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.hasChildren(){
                for child in snapshot.children{
                    let user = child as! DataSnapshot
                    var userName = ""
                    if let dictionary = user.value as? [String: AnyObject]{
                        userName = dictionary["username"] as! String
                    }
                    if self.groupMembers.contains(userName)
                    {
                        self.ref.child("users/\(user.key)/groups/\(newGroupKey)").setValue(newGroupInfo, withCompletionBlock: {error, ref in
                            if error != nil{
                                print("ERROR")
                            }
                        })
                    }
                }
            }
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        })
        }
        else{
              if groupMembers.count == 0{
                          let alert = UIAlertController(title: "Error", message: "Please Add Group Members", preferredStyle: .alert)
                          self.present(alert, animated: true)
                          alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                      }
                      else{
                          let alert = UIAlertController(title: "Error", message: "Please Add Group Name", preferredStyle: .alert)
                                         self.present(alert, animated: true)
                                         alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                      }
        }
    }
    
    
    
    func getFriends(){
        friends.removeAll()
        let friendslistRef = self.ref.child("/friends/\(theUser)")
        friendslistRef.observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.hasChildren() {
                for child in snapshot.children {
                    let theFriend = child as! DataSnapshot
                    let theFriendName = theFriend.key
                    if(theFriendName == "default"){
                        continue
                    }
                    self.friends.append(theFriendName)
                    print(theFriendName)
                }
            }
            DispatchQueue.main.async{
                print(self.friends.count)
                self.friendsTable.reloadData()
            }
        })
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
      }
    
      
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "theFavorite")
        cell.textLabel?.text = friends[indexPath.row]
        if groupMembers.contains(friends[indexPath.row])
        {
            cell.imageView?.image = UIImage(named: "check")
        }
        else{
            cell.imageView?.image = UIImage(named:"emptyCircle")
        }
        
        cell.backgroundColor = UIColor(red: 0.85, green: 0.92, blue: 0.91, alpha: 1.00)
               cell.layer.borderColor = CGColor.init(srgbRed: 1, green: 1, blue: 1, alpha: 1)
               cell.layer.borderWidth = 4
               cell.layer.cornerRadius = 10
        
        return cell
      }
      
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nameToSearch = friends[indexPath.row]
        
        if groupMembers.contains(nameToSearch)
        {
            let indexE:Int = groupMembers.firstIndex(of: nameToSearch) ?? 0
            self.groupMembers.remove(at: indexE)
        }
        else{
            groupMembers.append(nameToSearch)
        }
        friendsTable.reloadData()
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


}
