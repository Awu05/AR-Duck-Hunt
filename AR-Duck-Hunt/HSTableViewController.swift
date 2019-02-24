//
//  HSTableViewController.swift
//  AR-Duck-Hunt
//
//  Created by Andy Wu on 2/23/19.
//  Copyright © 2019 Andy Wu. All rights reserved.
//

import Foundation
import UIKit

class HSTableViewController: UITableViewController {
    
    let names = ["Andy", "Bob"]
    let scores = ["10", "5"]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "HSTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "customCell")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: HSTableViewCell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as! HSTableViewCell
        cell.nameLabel.text = self.names[indexPath.row]
        cell.scoreLabel.text = self.scores[indexPath.row]
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.names.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(tableView.cellForRow(at: indexPath) ?? "Test")
    }
}
