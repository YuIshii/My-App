//
//  PlaceHolderTextView.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/14.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit

public class PlaceHolderTextView: UITextView {

    lazy var placeHolderLabel:UILabel = UILabel()
    var placeHolderColor:UIColor = UIColor.lightGray
    var placeHolder:NSString = ""

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.changeVisiblePlaceHolder()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textChanged),
                                               name: UITextView.textDidChangeNotification,
                                               object: nil)
    }

    override public func draw(_ rect: CGRect) {
        if(self.placeHolder.length > 0) {
            self.placeHolderLabel.frame = CGRect(x: 8, y: 8, width: self.bounds.size.width - 16 , height: 0)
            self.placeHolderLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            self.placeHolderLabel.numberOfLines = 0
            self.placeHolderLabel.font = self.font
            self.placeHolderLabel.backgroundColor = UIColor.clear
            //プレースホルダの文字の色(数字が大きいほど透明に)
            self.placeHolderLabel.textColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
            self.placeHolderLabel.alpha = 0
            self.placeHolderLabel.tag = 1

            self.placeHolderLabel.text = self.placeHolder as String
            self.placeHolderLabel.sizeToFit()
            self.addSubview(placeHolderLabel)
        }

        self.sendSubviewToBack(placeHolderLabel)

        if(self.text.utf16.count == 0 && self.placeHolder.length > 0){
            self.viewWithTag(1)?.alpha = 1
        }

        super.draw(rect)
    }


    private func changeVisiblePlaceHolder() {
        if self.placeHolder.length == 0 || !self.text.isEmpty {
            self.placeHolderLabel.alpha = 0.0
        } else {
            self.placeHolderLabel.alpha = 1.0
        }
    }

    @objc private func textChanged(notification: NSNotification?) {
        changeVisiblePlaceHolder()
    }
}


