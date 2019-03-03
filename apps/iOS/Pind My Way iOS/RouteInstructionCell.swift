//
//  RouteInstructionCell.swift
//  Pind My Way iOS
//
//  Created by Bhuvan on 03/03/2019.
//  Copyright © 2019 Atto Allas. All rights reserved.
//

import UIKit

class RouteInstructionCell: UITableViewCell {

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
