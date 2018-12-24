//
//  MyCell.swift
//  accountbook
//
//  Created by lemonart on 2018/12/10.
//  Copyright © 2018 Lemon. All rights reserved.
//

import UIKit

class MyCell: UITableViewCell
{
    
    
    
    @IBOutlet weak var lblItem: UILabel!
    
    @IBOutlet weak var lblDate: UILabel!
    
    @IBOutlet weak var lblAmount: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
