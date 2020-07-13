//
//  Post4TableViewCell.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/14.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import FirebaseUI
import Firebase

class Post4TableViewCell: UITableViewCell {
    
    var postdata: PostData?
    var message: Message?
    
    @IBOutlet weak var postImageView: UIImageView!
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
            
            // 画像の表示
            postImageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
            let imageRef = Storage.storage().reference().child("images").child(postData.id + ".jpg")
            postImageView.sd_setImage(with: imageRef)
            
            // キャプションの表示
            self.captionLabel.text = "\(postData.caption!)"
            
            self.nameLabel.text = "\(postData.name!)"
            
            self.communityLabel.text = "\(postData.community!)"
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
