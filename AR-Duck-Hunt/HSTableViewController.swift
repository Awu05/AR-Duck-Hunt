//
//  HSTableViewController.swift
//  AR-Duck-Hunt
//
//  Created by Andy Wu on 2/23/19.
//  Copyright © 2019 Andy Wu. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class HSTableViewController: UITableViewController {
    
    var highScoreList = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadHighScores()
        let nib = UINib(nibName: "HSTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "customCell")
        
    }
    
    func loadHighScores() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "HighScore")
        let sortByScore = NSSortDescriptor(key: "score", ascending: false)
        fetchRequest.sortDescriptors = [sortByScore]
        
        do {
            highScoreList = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: HSTableViewCell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as! HSTableViewCell
        let person = highScoreList[indexPath.row]
        cell.nameLabel.text = person.value(forKey: "name") as? String
        cell.scoreLabel.text = String((person.value(forKey: "score") as? Int)!)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.highScoreList.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(tableView.cellForRow(at: indexPath) ?? "Test")
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
