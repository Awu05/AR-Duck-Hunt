//
//  HSTableViewCell.swift
//  AR-Duck-Hunt
//
//  Created by Andy Wu on 2/23/19.
//  Copyright © 2019 Andy Wu. All rights reserved.
//

import UIKit

class HSTableViewCell: UITableViewCell {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
