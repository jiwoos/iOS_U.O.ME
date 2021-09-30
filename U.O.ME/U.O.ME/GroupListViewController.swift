//
//  GroupListViewController.swift
//  U.O.ME
//
//  Created by Anderson Gonzalez on 7/25/20.
//  Copyright © 2020 Christie Chen. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class Receipt: NSObject{
    var date: String?
    var merchant: String?
    var total: Double?
    var subtotal: Double?
    var tax: Double?
    var payedBy: String?
    var photoURL: String?
    var priceSplit: Double?
    var deleted: String?
}

class GroupListViewController: UIViewController,UITableViewDataSource,UITableViewDelegate{


    
    @IBOutlet weak var theGroupsTable: UITableView!
        
    
    let myRefreshControl = UIRefreshControl()
       let ref = Database.database().reference()
       var theUserGroups: [String] = []
       var theTitle = ""
       var arrayofReceiptIds: [String] = []
       var arrayOfReceipts = [Receipt]()
       var theGroupID = ""
       var theUSer = ""
       var thePeople: [String] = []
       var theGroupIds: [String] =  []
       var theGroupToSend : [[String]] = []
       var selected = 0
       //var subTitleGroup = ""
       
       override func viewDidLoad() {
           super.viewDidLoad()
           theGroupsTable.dataSource = self
           theGroupsTable.delegate = self
           theGroupsTable.register(UITableViewCell.self, forCellReuseIdentifier: "theFavorite")
           let  barButton = UIBarButtonItem(title: "Add Group" , style: .done, target: self, action: #selector(addGroup))
           self.navigationItem.rightBarButtonItem = barButton
          //getUserGroups1()
          myRefreshControl.addTarget(self, action: #selector(GroupListViewController.handleRefresh), for: .valueChanged)
          theGroupsTable.refreshControl = myRefreshControl
           // Do any additional setup after loading the view.
            theGroupsTable.separatorStyle = UITableViewCell.SeparatorStyle.none

       }
    
       @objc func addGroup(){
                  self.performSegue(withIdentifier: "addGroup", sender: self)
        }
    
       
        @objc func handleRefresh(_sender:UIRefreshControl){
            self.theUserGroups.removeAll()
                      self.thePeople.removeAll()
                      self.theGroupIds.removeAll()
                      //check for user ID
                      guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else {
                          print("no user found")
                          return }
                      
                      //get UserName
                      let nameRef = self.ref.child("/users/" + uid + "/username")
                      nameRef.observeSingleEvent(of: .value, with: {(snapshot) in
                          let userM = snapshot.value as? String ?? ""
                          self.theUSer = userM
                          print("The user is:" + self.theUSer)
                      })
                      
                      //get Groups of User
                      let refGroups = self.ref.child("/users/" + uid + "/groups")
                      refGroups.observeSingleEvent(of: .value, with: {(snapshot) in
                          if snapshot.hasChildren() {
                              for child in snapshot.children{
                                  let singleGroup = child as! DataSnapshot
                                  let groupId = singleGroup.key
                                  self.theGroupIds.append(groupId)
                                  if let dictionary = singleGroup.value as? [String: AnyObject]
                                  {
                                      let groupName = dictionary["name"] as! String
                                      self.theUserGroups.append(groupName)
                                      let groupMembers = dictionary["people"] as! String
                                      self.getGroupMembers(groupName: groupMembers)
                                  }
                                  
                              }
                          }
                          DispatchQueue.main.async {
                             self.theGroupsTable.reloadData()
                             self.myRefreshControl.endRefreshing()
                          }
                      })
       }
       
       
    
       func getUserGroups1()
       {
           self.theUserGroups.removeAll()
           self.thePeople.removeAll()
           self.theGroupIds.removeAll()
           //check for user ID
           guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else {
               print("no user found")
               return }
           
           //get UserName
           let nameRef = self.ref.child("/users/" + uid + "/username")
           nameRef.observeSingleEvent(of: .value, with: {(snapshot) in
               let userM = snapshot.value as? String ?? ""
               self.theUSer = userM
               print("The user is:" + self.theUSer)
           })
           
           //get Groups of User
           let refGroups = self.ref.child("/users/" + uid + "/groups")
           refGroups.observeSingleEvent(of: .value, with: {(snapshot) in
               if snapshot.hasChildren() {
                   for child in snapshot.children{
                       let singleGroup = child as! DataSnapshot
                       let groupId = singleGroup.key
                       if let dictionary = singleGroup.value as? [String: AnyObject]
                       {
                           let groupName = dictionary["name"] as! String
                           self.theUserGroups.append(groupName)
                           let groupMembers = dictionary["people"] as! String
                           self.getGroupMembers(groupName: groupMembers)
                           self.theGroupIds.append(groupId)
                       }
                       
                   }
               }
               DispatchQueue.main.async {
                  self.theGroupsTable.reloadData()
               }
           })
           
           }
       
       func getGroupMembers(groupName:String){
           let firstArray = groupName.components(separatedBy: ",")
           var secondArray: [String] = []
           for item in firstArray{
               if item != self.theUSer{
                   secondArray.append(item)
               }
           }
           self.theGroupToSend.append(secondArray)
           let theactualMembers = secondArray.joined(separator: ",")
           self.thePeople.append(theactualMembers)
           print(self.thePeople.count)
           print(theactualMembers)
       }
       
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return self.theUserGroups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "theFavorite")
       cell.textLabel?.text = self.theUserGroups[indexPath.row]
       cell.detailTextLabel?.text = self.thePeople[indexPath.row]
        
        cell.backgroundColor = UIColor(red: 0.85, green: 0.92, blue: 0.91, alpha: 1.00)
        cell.layer.borderColor = CGColor.init(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        cell.layer.borderWidth = 4
        cell.layer.cornerRadius = 10
        
       return cell
    }
       
       
       func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         self.arrayOfReceipts.removeAll()
         self.arrayofReceiptIds.removeAll()
         self.selected = indexPath.row
         self.theTitle = self.theUserGroups[indexPath.row]
         self.theGroupID = self.theGroupIds[indexPath.row]
         let receiptDataRef = self.ref.child("groupData/\(self.theGroupIds[indexPath.row])/receipts")
               receiptDataRef.observeSingleEvent(of: .value, with: { (snapshot) in
                   if snapshot.hasChildren(){
                       for child in snapshot.children{
                           let singleReceipt = child as! DataSnapshot
                           if let dictionary = singleReceipt.value as? [String: AnyObject] {
                           let receipt = Receipt()
                               receipt.date = dictionary["Date"] as? String ?? ""
                               receipt.merchant = dictionary["Merchant"] as? String ?? ""
                               receipt.total = dictionary["Total"] as? Double ?? 0.0
                               receipt.subtotal = dictionary["Subtotal"] as? Double ?? 0.0
                               receipt.payedBy = dictionary["payedBy"] as? String ?? ""
                               receipt.photoURL = dictionary["imageURL"] as? String ?? ""
                               receipt.tax = dictionary["Tax"] as? Double ?? 0.0
                               receipt.priceSplit = dictionary["priceSplit"] as? Double ?? 0.0
                               receipt.deleted  = dictionary["deleted"] as? String ?? ""
                               if( receipt.deleted == "false"){
                                self.arrayOfReceipts.append(receipt) }
                                self.arrayofReceiptIds.append(singleReceipt.key)
                            }
                       }
                   }
                   DispatchQueue.main.async{
                                        self.performSegue(withIdentifier: "toGroup", sender: self)
                                        }
               })
           
           }
       
       
       override func viewWillAppear(_ animated: Bool) {
                if let selectedIndexPath = theGroupsTable.indexPathForSelectedRow {
                    theGroupsTable.deselectRow(at: selectedIndexPath, animated: animated)
                }
                getUserGroups1()
            }
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if(segue.identifier == "toGroup"){
               let detailedVC = segue.destination as! GroupViewController
               detailedVC.theTile = self.theTitle
               detailedVC.theGroupMembers = self.theGroupToSend[selected]
               detailedVC.theReceipts = self.arrayOfReceipts
               detailedVC.theUserName = self.theUSer
               detailedVC.theGroupID = self.theGroupID
               detailedVC.arrayofReceiptIds = self.arrayofReceiptIds
               }
               if(segue.identifier == "addGroup"){
                   let detailedVC = segue.destination as! AddingGroupViewController
                   detailedVC.theUser = self.theUSer
               }
    }
    

}

