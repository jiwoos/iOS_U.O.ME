//
//  GroupViewController.swift
//  U.O.ME
//
//  Created by Anderson Gonzalez on 7/25/20.
//  Copyright © 2020 Christie Chen. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

/*class Receipt: NSObject {
 var payedBy: String?
 var photo:String?
 var priceSplit: Int?
 var processed: Bool?
 var total: Int?
 }*/

class GroupViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    
    
    @IBOutlet weak var groupTable: UITableView!
    
    
    
    var theGroupID = ""
    var theUserName = ""
    var theGroupMembers: [String] = []
    var arrayofReceiptIds: [String] = []
    var theTile = ""
    var theReceipts = [Receipt]()
    let ref = Database.database().reference()
    var selected = 0
    var group = ""
    let myRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = theTile
        self.title = theTile
        print(theReceipts.count)
        setUpTable()
        
        // Do any additional setup after loading the view.
    }
    
    func setUpTable(){
        groupTable.dataSource = self
        groupTable.delegate = self
        groupTable.register(UITableViewCell.self, forCellReuseIdentifier: "theFavorite")
        let  barButton = UIBarButtonItem(title: "Add Receipt" , style: .done, target: self, action: #selector(addReceipt))
        self.navigationItem.rightBarButtonItem = barButton
        myRefreshControl.addTarget(self, action: #selector(GroupViewController.handleRefresh), for: .valueChanged)
        groupTable.refreshControl = myRefreshControl
    }
    
    @objc func handleRefresh(_sender:UIRefreshControl){
        theReceipts.removeAll()
        arrayofReceiptIds.removeAll()
        
        let receiptDataRef = self.ref.child("groupData/\(self.theGroupID)/receipts")
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
                        receipt.deleted = dictionary["deleted"]  as? String ?? ""
                        print(receipt)
                        if receipt.deleted == "false" {
                            print(receipt)
                            self.theReceipts.append(receipt)
                            self.arrayofReceiptIds.append(singleReceipt.key)
                        }
                            
                        }

                }
            }
            DispatchQueue.main.async{
                self.groupTable.reloadData()
                self.myRefreshControl.endRefreshing()
            }
        })
    }
    
    
    @objc func addReceipt(){
        
        self.performSegue(withIdentifier: "toOwnerAdd", sender: self)
        
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        print(theUserName)
        print(editingStyle)
        print(self.arrayofReceiptIds[indexPath.row])
        
        if editingStyle == .delete  && theReceipts[indexPath.row].payedBy == theUserName{
                 self.ref.child("groupData/\(self.theGroupID)/receipts/\(self.arrayofReceiptIds[indexPath.row])/deleted").setValue("true")
                 let theReceiptToDelete = self.ref.child("groupData/\(self.theGroupID)/receipts/\(self.arrayofReceiptIds[indexPath.row])/payed")
                    theReceiptToDelete.observeSingleEvent(of: .value, with: {(snapshot) in
                        if snapshot.hasChildren(){
                            for child in snapshot.children{
                                let singleMember = child as! DataSnapshot
                                let value = singleMember.value as? String ?? ""
                                if value == "false"
                                {
                                    self.ref.child("groupData/\(self.theGroupID)/receipts/\(self.arrayofReceiptIds[indexPath.row])/payed/\(singleMember.key)").setValue("true")
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            self.theReceipts.remove(at: indexPath.row)
                            self.arrayofReceiptIds.remove(at: indexPath.row)
                            tableView.deleteRows(at: [indexPath], with: .left)
                        }
                    })
             }
        
        else{
            let alert = UIAlertController(title: "Error", message: "Receipt can only be deleted by \(theReceipts[indexPath.row].payedBy!)", preferredStyle: .alert)
            self.present(alert, animated: true)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        }
         }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(theReceipts.count)
        return theReceipts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "theFavorite", for: indexPath)
        cell.textLabel?.text = createTextLabel(index: indexPath.row)
        cell.textLabel?.numberOfLines = 0
        
        ref.child("groupData/\(self.theGroupID)/receipts/\(self.arrayofReceiptIds[indexPath.row])/payed/\(theUserName)").observeSingleEvent(of: .value, with: {(snapshot) in
            let haveIPayed = snapshot.value as? String
            if(haveIPayed == nil){
                cell.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.00) //blue
            }
            else if(haveIPayed! != "false"){
                cell.backgroundColor = UIColor(red: 0.76, green: 0.88, blue: 0.87, alpha: 1.00) //blue
            }
            else{
                cell.backgroundColor = UIColor(red: 0.96, green: 0.87, blue: 0.74, alpha: 1.00) //orange
            }
            })
            cell.layer.borderColor = CGColor.init(srgbRed: 1, green: 1, blue: 1, alpha: 1)
            cell.layer.borderWidth = 4
            cell.layer.cornerRadius = 10
            return cell
    }
    
    
    func createTextLabel(index:Int)->String{
        let date = theReceipts[index].date  //string
        let total = theReceipts[index].total  //double
        let totalString = String(format: "%.2f", total ?? 0)
        let merchant = theReceipts[index].merchant //string
        let thelabel = "Date: \(date ?? "")\nMerchant: \(merchant ?? "" )\nTotal: $\(totalString)"
        return thelabel
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected = indexPath.row
        if(self.theUserName == self.theReceipts[indexPath.row].payedBy){
            //person is owner
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "toOwnerEdit", sender: self)
            }
        }
        else{
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "toNotOwner", sender: self)
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = groupTable.indexPathForSelectedRow {
            groupTable.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    
    @IBAction func addExpense(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "toOwnerAdd", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toNotOwner"){
            let nonOwner = segue.destination as! NotOwnerVC
            nonOwner.uploader = self.theReceipts[selected].payedBy!
            nonOwner.date = self.theReceipts[selected].date!
            nonOwner.merchant = self.theReceipts[selected].merchant!
            nonOwner.imgURL = self.theReceipts[selected].photoURL!
            nonOwner.split = self.theReceipts[selected].priceSplit!
            nonOwner.subtotal = self.theReceipts[selected].subtotal!
            nonOwner.tax = self.theReceipts[selected].tax!
            nonOwner.total = self.theReceipts[selected].total!
        }
        if(segue.identifier == "toOwnerAdd"){
            let ownerAdd = segue.destination as! GroupReceiptViewController
            ownerAdd.theGroupMebers = self.theGroupMembers
            ownerAdd.theGroupId = self.theGroupID
            ownerAdd.theUserName = self.theUserName
        }
        if(segue.identifier == "toOwnerEdit"){
            let owner = segue.destination as! TestViewController
            owner.group = theGroupID
            owner.state = "edit"
            owner.payedBy = self.theUserName
            owner.imgURL = self.theReceipts[selected].photoURL!
            owner.merchant = self.theReceipts[selected].merchant!
            owner.date = self.theReceipts[selected].date!
            owner.total = self.theReceipts[selected].total!
            owner.selectedReceipt = selected
            owner.priceSplit = self.theReceipts[selected].priceSplit!
            owner.currentReceiptName = arrayofReceiptIds[selected]
        }
    }
        
    }
