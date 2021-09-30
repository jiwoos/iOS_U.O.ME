//
//  FriendsListViewController.swift
//  U.O.ME
//
//  Created by Christie Chen on 7/27/20.
//  Copyright © 2020 Christie Chen. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import Firebase
import FirebaseStorage
import SDWebImage

class FriendsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numUsers-1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseCell")! as UITableViewCell
        
        
        cell.textLabel?.text = users[indexPath.row]
        
        if(inFriends[indexPath.row] == true){
            cell.imageView?.image = UIImage(named: "check")
        }
        else{
            cell.imageView?.image = UIImage(named:"emptyCircle")
        }
        
        cell.backgroundColor = UIColor(red: 0.85, green: 0.92, blue: 0.91, alpha: 1.00)
        cell.layer.borderColor = CGColor.init(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        cell.layer.borderWidth = 2
        
        cell.layer.cornerRadius = 10
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ref = Database.database().reference()
        if(inFriends[indexPath.row] == false){
            inFriends[indexPath.row] = true
            ref.child("/friends/" + currentUser + "/" + users[indexPath.row]).setValue(0)
            ref.child("/friends/" + users[indexPath.row] + "/" + currentUser).setValue(0)
        }
        
        else if(inFriends[indexPath.row] == true && amount[indexPath.row] == 0){
            inFriends[indexPath.row] = false
            //deletes it
            ref.child("/friends/" + currentUser + "/" + users[indexPath.row]).setValue(nil)
            
        }
        tableView.reloadData()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        getUsers()
        tableView.reloadData()
        
    }
    
    var numUsers = 0
    var users:[String] = []
    var inFriends:[Bool] = []
    var amount:[Double] = []
    var currentUser = ""
    let storageRef = Storage.storage().reference(forURL: "gs://final-project-591d1.appspot.com/")

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = UIColor.blue
        // Do any additional setup after loading the view.
        let ref = Database.database().reference()
        guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        
        _ = ref.child("/users/" + uid + "/username").observeSingleEvent(of: .value){
            (snapshot) in
            self.currentUser = snapshot.value as! String
        }
        
        scrollView.contentSize = tableView.contentSize
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseCell")
        tableView.dataSource = self
        tableView.delegate = self
        print("loaded")
        getUsers()
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none

    }
    
    
    func getUsers(){
        let ref = Database.database().reference()
        ref.child("/takenUsernames").observeSingleEvent(of: .value){
            (snapshot) in
            let users = snapshot.value as! [String:Int]
            let usernames = users.keys
            self.numUsers = usernames.count
            ref.child("/friends/" + self.currentUser).observeSingleEvent(of: .value){
                (snapshot) in

                let currentUsersFriends = snapshot.value as! [String:Double]
                
                let currentUsersFriendsNames = currentUsersFriends.keys
                
                //each name in the users
                for name in usernames{
                    
                    if(name == self.currentUser){
                        continue
                    }
                    
                    self.users.append(name)
                    if(currentUsersFriendsNames.contains(name)){
                        self.inFriends.append(true)
                        self.amount.append(currentUsersFriends[name]!)
                    }
                    else{
                        self.inFriends.append(false)
                        self.amount.append(0)
                    }
                    
                }
                self.tableView.reloadData()

                
            }
        }
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
