//
//  ReceiptListController.swift
//  U.O.ME
//
//  Created by Owen Ricketts on 7/22/20.
//  Copyright © 2020 Christie Chen. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase

class ReceiptListController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    let ref = Database.database().reference()
    var myData: [[String:Any]] = [[:]]
    var keys: [String] = []
    var selected: Int = 0
    var method:String = ""
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myData.count
    }
    
    
    
    @IBAction func pressButton(_ sender: UIBarButtonItem) {
        keys.removeAll()
        keys.append("")
        method = "add"
        performSegue(withIdentifier: "editReceipt", sender: self)
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(myData)
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        let cellInfo = myData[indexPath.row]
        cell.textLabel?.text = "Date: \(cellInfo["Date"] ?? "")\nMerchant: \(cellInfo["Merchant"] ?? "")\nTotal: $\(cellInfo["Total"] ?? "")"
//        cell.textLabel?.textAlignment = .center
          cell.textLabel?.numberOfLines = 0
        
        
        cell.backgroundColor = UIColor(red: 0.76, green: 0.88, blue: 0.87, alpha: 1.00)
        cell.layer.borderColor = CGColor.init(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        cell.layer.borderWidth = 4
        cell.layer.cornerRadius = 10
        
        return cell
    }
    
    
    func fetchReceiptData(){
        myData.removeAll()
        keys.removeAll()
        guard (FirebaseAuth.Auth.auth().currentUser?.uid) != nil else {
            return
        }
        loadData(completion: { (array,key) in
           
            for i in 0..<array.count{
                if(!array[i].isEmpty){
                    if(array[i]["deleted"] as! Bool == false){
                        self.myData.append(array[i])
                        self.keys.append(key[i])
                    }
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }

        })
        
    }
    
    func loadData(completion: @escaping([[String:Any]], [String])->Void){
        guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else {
            return
        }
        let userReceipts = self.ref.child("/users/").child(uid).child("/receipts/")
        var array: [[String:Any]] = [[:]]
        var k: [String] = []
        userReceipts.observeSingleEvent(of: .value){ (snapshot) in
            if let dict = snapshot.value as? [String:Any] {
                array = Array(dict.values) as! [[String:Any]]
                k = Array(dict.keys)
            }
            completion(array, k)
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected = indexPath.row
        method = "edit"
        self.performSegue(withIdentifier: "editReceipt", sender: self)
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath){
        if(editingStyle == .delete){
            
            print()
            guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else {
                return
            }
            let userReceipts = self.ref.child("/users/").child(uid).child("/receipts/").child(keys[indexPath.row])
            myData[indexPath.row]["deleted"] = true
            userReceipts.updateChildValues(myData[indexPath.row], withCompletionBlock: { error, ref in
                if error != nil{
                    print("ERROR")
                }
                DispatchQueue.main.async{
                    self.fetchReceiptData()
                }
            })
            
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "myCell")
        //fetchReceiptData()
        // Do any additional setup after loading the view.
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        selected = 0
        fetchReceiptData()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let receiptVC = segue.destination as! ReceiptViewController
        receiptVC.state = method
        
        receiptVC.editReceipt = keys[selected]
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
