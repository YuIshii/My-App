//
//  ProfileTableViewCell.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/14.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase

class ProfileTableViewCell: UITableViewCell {

    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var postsCount: UILabel!
    @IBOutlet weak var editButton: UIButton!
    

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
