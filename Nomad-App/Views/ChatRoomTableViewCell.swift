//
//  ChatRoomTableViewCell.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase


class ChatRoomTableViewCell: UITableViewCell {
    
    var postdata: PostData?
    
    var message: Message? {
        didSet{
            if let message = message {
                messageLabel.text = message.message
                dateLabel.text = dateFormatterDateLabel(date: message.createdAt.dateValue())
                nameLabel.text = message.name
            }
        }
    }
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var alertButton: UIButton!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        checkWhichUserMessage()
    }
    
    //色を変更する
    private func checkWhichUserMessage() {
        //現在ログインして操作しているユーザーのuidがmessageのuidと一緒だったら
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if uid == message?.uid{
            //セルの背景色を薄い青にする
            self.contentView.backgroundColor = UIColor.rgb(red: 247, green: 252, blue: 255)
        }else{
            self.contentView.backgroundColor = UIColor.rgb(red: 250, green: 250, blue: 250)
        }
        if postdata?.uid == message?.uid{
            //コメントを紫色にする
            messageLabel.textColor = UIColor.rgb(red: 102, green: 0, blue: 153)
            messageLabel.font = UIFont.boldSystemFont(ofSize: 16)
        }else{
            messageLabel.textColor = UIColor.black
            messageLabel.font = UIFont.boldSystemFont(ofSize: 16)
        }
        
        //messageLabel.font = UIFont.systemFont(ofSize: 15)
    }
    
    //日付の表示を設定する
    private func dateFormatterDateLabel(date: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_Jp")
        return formatter.string(from: date)
    }
}

