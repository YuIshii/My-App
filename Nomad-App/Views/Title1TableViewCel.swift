//
//  Title1TableViewCel.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/14.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit

class Title1TableViewCell: UITableViewCell {
    private var hasSeparator = true
    
    override func layoutSubviews() {
        super.layoutSubviews()
        toggleSeparator()
    }
    
    
    func configure(hasSeparator: Bool) {
        self.hasSeparator = hasSeparator
    }
    
    private func toggleSeparator() {
        for separatorView in subviews where separatorView != contentView {
            separatorView.isHidden = hasSeparator
        }
    }
    
}
