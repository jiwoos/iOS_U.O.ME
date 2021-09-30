//
//  TestViewController.swift
//  U.O.ME
//
//  Created by Anderson Gonzalez on 7/20/20.
//  Copyright © 2020 Christie Chen. All rights reserved.
//
import UIKit
import Firebase
import FirebaseStorage

class TestViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    
    
    let ref = Database.database().reference()
    
    var imgPickerCtrl:UIImagePickerController = UIImagePickerController()
    
    var debtors: [String] = ["Choose Name"]
    var tableViewNames: [String] = []
    var receiptCount:Int? = nil
    var group = ""
    var imageSelected:UIImage? = nil
    var date = ""
    var merchant = ""
    var subtotal = 0.0
    var tax = 0.0
    var total = 0.0
    var priceSplit = 0.0
    var state = "add"
    var editReceipt = ""
    var payedBy = ""
    var imgURL = ""
    var selectedRow:Int? = nil
    var selectedUser:String = ""
    var selectedReceipt = 0
    var keys:[String] = []
    var currentReceiptName:String = ""
    var paidOrNot = ""
    var paidOrNotDisplay = ""
    
    
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var receiptImageView: UIImageView!
    @IBOutlet weak var submittedLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    
    
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var dateLabel: UITextField!
    @IBOutlet weak var merchantLabel: UITextField!
    
    @IBOutlet weak var displayInfoView: UIView!
    @IBOutlet weak var paidButtonOutlet: UIButton!
    @IBOutlet weak var submitButtonOutlet: UIButton!
    
    @IBOutlet weak var stillOwedTF: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submittedLabel.isHidden = true
        displayInfoView.layer.cornerRadius = 15
        paidButtonOutlet.layer.cornerRadius = 15
        submitButtonOutlet.layer.cornerRadius = 15
        pickerViewValue()
        pickerView.dataSource = self
        pickerView.delegate = self
        updateTheBoard()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "theCell")
        print("current receipt name is: \(currentReceiptName)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        submittedLabel.isHidden = true
        updateTheBoard()
    }
    
    func pickerViewValue() {
        debtors.removeAll()
        tableViewNames.removeAll()
        debtors.append("Choose Name")
        ref.child("groupData/\(group)/people").observeSingleEvent(of: .value) { (snapshot) in
            let peopleString = snapshot.value as! String
            let peopleArray = peopleString.components(separatedBy: ",")
            for people in peopleArray{
                if (people != self.payedBy) {
                    self.debtors.append(people)
                    self.tableViewNames.append(people)
                }
            }
            self.tableView.reloadData()
            self.pickerView.reloadAllComponents()
        }
    }
    
    
    @IBAction func paidButton(_ sender: Any) {
        if selectedUser == "Choose Name" {
            let alert = UIAlertController(title: "Error", message: "choose a friend", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler : nil )
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
        else {
            ref.child("groupData/\(group)").child("receipts/\(currentReceiptName)/payed/\(selectedUser)").observeSingleEvent(of: .value) {
                (snapshot) in
                let paidBool = snapshot.value as! String
                if paidBool == "false" {
                    self.ref.child("groupData/\(self.group)").child("receipts/\(self.currentReceiptName)/payed/\(self.selectedUser)").setValue("true")
                }
                else {
                    let alert = UIAlertController(title: "Alert", message: "\(self.selectedUser) has already paid", preferredStyle: UIAlertController.Style.alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler : nil )
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
                self.tableView.reloadData()
                self.updateTheBoard()
            }
        }
        
    }
    
    func updateTheBoard() {
        let fileURL = URL(string: imgURL)
        let placeholderImg = UIImage(named: "noImage")
        if(fileURL != nil){
            receiptImageView.sd_setImage(with: fileURL, placeholderImage: placeholderImg)
        }
        var numPeopleNotPaid = 0
        totalLabel.text = String(total)
        dateLabel.text = date
        merchantLabel.text = merchant
        for d in 1..<debtors.count{
            ref.child("groupData/\(group)/receipts/\(currentReceiptName)/payed/\(debtors[d])/").observeSingleEvent(of: .value) {
                (snapshot) in
                var paidNotPaid = ""
                paidNotPaid = snapshot.value as! String
                if paidNotPaid == "false" {
                    numPeopleNotPaid = numPeopleNotPaid + 1
                    print("hi")
                }
                else {
                    // do nothing
                    print("by")
                }
                print(numPeopleNotPaid)
                
                let stillOwedAmount = self.priceSplit * Double(numPeopleNotPaid)
                let priceFormatted = String(format: "%.2f", stillOwedAmount)
                if stillOwedAmount > 0 {
                    self.stillOwedTF.text = "Still Owed: \(priceFormatted)"
                }
                else {
                    self.stillOwedTF.text = "Everyone has paid!"
                }
            }
        }
        
    }
    
    
    
    
    func loadTextFields(){
        dateLabel.text = date
        merchantLabel.text = merchant
        totalLabel.text = String(total)
    }
    
    
    @IBAction func submitReceipt(_ sender: Any) {
        let d = dateLabel.text ?? ""
        let m = merchantLabel.text ?? ""
        let to = Double(self.totalLabel.text ?? "") ?? 0
        DispatchQueue.global(qos: .userInitiated).async {
            self.updateDatabase(d, m, to)
            DispatchQueue.main.async {
                self.submitButton.isHidden = true
                self.submittedLabel.isHidden = false
            }
        }
    }
    
    func updateDatabase(_ date: String, _ merchant: String, _ total: Double){
        let userReceipts = self.ref.child("/groupData/").child(group).child("/receipts/\(currentReceiptName)")
        userReceipts.child("Date").setValue(date)
        userReceipts.child("Merchant").setValue(merchant)
        userReceipts.child("total").setValue(total)
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "theCell")
        let cellName = tableViewNames[indexPath.row]
        ref.child("groupData/\(group)/receipts/\(currentReceiptName)/payed/\(cellName)/").observeSingleEvent(of: .value) {
            (snapshot) in
            print(self.currentReceiptName)
            print(cellName)
            self.paidOrNot = snapshot.value as! String
            if self.paidOrNot == "false" {
                cell.textLabel?.text = "\(cellName) hasn't paid yet"
            }
            else {
                cell.textLabel?.text = "\(cellName) has paid"
            }
        }
        
        return cell
    }
}





extension TestViewController: UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        debtors.count
    }
}

extension TestViewController: UIPickerViewDelegate{
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return debtors[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRow = row
        selectedUser = debtors[selectedRow!]
    }
    
    
    
    
}
