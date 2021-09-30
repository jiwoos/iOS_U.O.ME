//
//  ProfileViewController.swift
//
//
//  Created by Christie Chen on 7/20/20.
//

import UIKit

class ProfileViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

        
    var payData: [String: Double] = [:]
    var groups:[String] = []
    let hardCodedCurrentUser = "christie"
    let currentUser = "/friends/christie"

    
    
    func updateResult(){
        let ref = Database.database().reference()
        let hardCodedGroups = ["group1", "group2"]
        groups = []
        for groupName in hardCodedGroups{
            groups.append("/groupData/"+groupName)
        }

        for groupName in hardCodedGroups{
            ref.child("/groupData/" + groupName).observeSingleEvent(of: .value){
                (snapshot) in
                let data = snapshot.value as! [String:Any]
                
                //single receipt item
                for receiptItem in data{
                    let buildReceipt = "/groupData/" + groupName + "/" + receiptItem.key
                    ref.child(buildReceipt).observeSingleEvent(of: .value){
                        (snapshot) in
                        let receiptData = snapshot.value as! [String:Any]
                        print(receiptData["payedBy"])
                        //payData should hold how much current user owes other people
//                        self.payData.updateValue(receiptData["priceSplit"] as! Double, forKey: receiptData["payedBy"] as! String)
                        print ("updated dict")
//                        print(self.payData)
                    
                        let whoPayed = receiptData["payedBy"] as! String
                        let build = self.currentUser + "/" + whoPayed //path to user who payed in friends list
                        if(receiptData["processed"] as! Bool == false){
                            ref.child("/friends/" + self.hardCodedCurrentUser).observeSingleEvent(of: .value){
                               (snapshot) in
                                let data = snapshot.value as! [String: Any]
                                let friendsArray = data.keys // all the friends of the current user
                                
                                ref.child("/groups/" + groupName).observeSingleEvent(of: .value){
                                    (snapshot) in
                                    let people = snapshot.value as! String //the group of the current receipt
                                    let peopleArray = people.components(separatedBy: ", ")
//                                    for name in peopleArray{
                                        //if the person who payed is in the friends list (should be, but just in case)
//                                        if(friendsArray.contains(whoPayed)){
                                    var newOwed = 0.0
                                    if(self.hardCodedCurrentUser != whoPayed){
                                        var origOwed = data[whoPayed] as! Double//the original value in the database listed next to the friend
                                        newOwed = origOwed + (receiptData["priceSplit"] as! Double)
                                        ref.child("/friends/" + self.hardCodedCurrentUser + "/" + whoPayed).setValue(newOwed)
                                    }
                                    else{ //the person who paid this receipt is the user
                                        for name in peopleArray{
                                            var origOwed = data[name] as! Double// the original value in the database next to friend's name
                                            newOwed = origOwed - (receiptData["priceSplit"] as! Double)
                                            ref.child("/friends/" + self.hardCodedCurrentUser + "/" + name).setValue(newOwed)
                                        }
                                    
//                                        }
                                    }
                                }
                            }
                            ref.child(buildReceipt + "/processed").setValue(true)
                        } //end if false statement
                    }
                }
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
