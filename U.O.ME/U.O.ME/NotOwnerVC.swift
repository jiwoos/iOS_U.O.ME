//
//  NotOwnerVC.swift
//  U.O.ME
//
//  Created by Owen Ricketts on 7/28/20.
//  Copyright © 2020 Christie Chen. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class NotOwnerVC: UIViewController {

    let ref = Database.database().reference()
    var imgURL = ""
    var date = ""
    var merchant = ""
    var subtotal = 0.0
    var tax = 0.0
    var uploader = ""
    var total = 0.0
    var split = 0.0
    @IBOutlet weak var uploaderLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var merchantLabel: UILabel!
    @IBOutlet weak var subtotalLabel: UILabel!
    @IBOutlet weak var taxLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var receiptImage: UIImageView!
    @IBOutlet weak var splitLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        updateFields()
    }
    
    func updateFields(){
        let fileURL = URL(string: imgURL)
        let placeholderImg = UIImage(named: "loading")
        if(fileURL != nil){
            receiptImage.sd_setImage(with: fileURL, placeholderImage: placeholderImg)
        }
        else if imgURL == ""{
            receiptImage.image = UIImage(named: "noPhoto")
        }
        uploaderLabel.text = "Uploader: \(uploader)"
        dateLabel.text = "Date: \(date)"
        merchantLabel.text = "Merchant: \(merchant)"
        subtotalLabel.text = "Subtotal: $\(subtotal)"
        taxLabel.text = "Tax: $\(tax)"
        totalLabel.text = "Total: $\(total)"
        splitLabel.text = "Price Split: $ \(String(format: "%.2f", split))"
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
