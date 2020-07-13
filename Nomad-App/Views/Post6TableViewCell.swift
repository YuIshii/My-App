//
//  Post6TableViewCell.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/14.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import FirebaseUI
import Firebase

class Post6TableViewCell: UITableViewCell {
    
    var postdata: PostData?

    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setPostData(_ postData: PostData) {
        
        if postData.caption != nil{
            
        //全ての改行削除
            let msg = postData.caption!.replacingOccurrences(of: "\n\n", with: "")
            //PostDataの投稿データをセルに表示
            // キャプションの表示
            self.captionLabel.text = "\(msg)"
        }
        
        // 画像の表示
        postImageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
        let imageRef = Storage.storage().reference().child("images").child(postData.id + ".jpg")
        postImageView.sd_setImage(with: imageRef)
    }
}

