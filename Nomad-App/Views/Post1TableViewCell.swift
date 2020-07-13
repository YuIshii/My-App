//
//  Post1TableViewCell.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import FirebaseUI
import Firebase

class Post1TableViewCell: UITableViewCell {
    
    var postdata: PostData?
    var message: Message?
    
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var communityLabel: UILabel!
    @IBOutlet weak var modLabel: UILabel!
    @IBOutlet weak var alertButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var commentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // PostDataの内容をセルに表示
    func setPostData(_ postData: PostData) {
        
        //現在ログインして操作しているユーザーのuidがmessageのuidと一緒だったら
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if postdata?.uid == uid{
            modLabel.isHidden = false
        }else{
            modLabel.isHidden = true
        }
        
        if postData.caption != nil{
            //PostDataの投稿データをセルに表示
            // キャプションの表示
            self.captionLabel.text = "\(postData.caption!)"
        }
        
        if postData.name != nil{
            self.nameLabel.text = "\(postData.name!)"
        }
        
        if postData.community != nil{
            self.communityLabel.text = "\(postData.community!)"
        }

        // 日時の表示
        self.dateLabel.text = ""
        if let date = postData.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
            let dateString = formatter.string(from: date)
            self.dateLabel.text = dateString
        }

        // いいね数の表示
        let likeNumber = postData.likes.count
        likeLabel.text = "\(likeNumber)"

        // いいねボタンの表示
        if postData.isLiked {
            let buttonImage = UIImage(named: "like_exist")
            self.likeButton.setImage(buttonImage, for: .normal)
        } else {
            let buttonImage = UIImage(named: "like_none")
            self.likeButton.setImage(buttonImage, for: .normal)
        }
        
        // コメント数の表示
        commentLabel.text = "\(postData.allComments.count)"
        
        // コメントボタンの表示
        if postData.isCommented {
            let buttonImage = UIImage(named: "comments2")
            self.commentButton.setImage(buttonImage, for: .normal)
        } else {
            let buttonImage = UIImage(named: "comments")
            self.commentButton.setImage(buttonImage, for: .normal)
        }
    }
}

