//
//  PostData.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase
class PostData: NSObject {
    
    //投稿情報
    var id: String
    var uid: String
    var name: String?
    var community: String?
    var caption: String?
    var date: Date?
    var with_image: Bool = false
    
    //いいね機能
    var likes: [[String:Any]] = []
    var isLiked: Bool = false
    var likedTime: TimeInterval = 0
    
    //投稿に対する自分のコメント
    var comments: [[String:Any]] = []
    var isCommented: Bool = false
    
    //投稿に対する全てのコメント
    var allComments: [[String:Any]] = []
    var isAllCommented: Bool = false
    
    //投稿に自分が投稿したかどうか
    var join: [[String:Any]] = []
    var isJoined: Bool = false
    var joinedTime: TimeInterval = 0
    
    //投稿を自分が見たかどうか
    var viewer: [[String:Any]] = []
    var viewed: Bool = false
    var viewedTime: TimeInterval = 0
    
    //投稿の通報・削除
    var reports: [[String:Any]] = []
    var reportedTime: TimeInterval = 0
    var isReported: Bool = false
    var myReportExist: Bool = false
    var deletes: [[String:Any]] = []
    var deletedTime: TimeInterval = 0
    
    //投稿の非表示
    var blocks: [[String:Any]] = []
    var blockedTime: TimeInterval = 0
    
    init(document: DocumentSnapshot) {
        self.id = document.documentID
        let postDic = document.data()!
        self.name = postDic["name"] as? String
        self.community = postDic["community"] as? String
        self.caption = postDic["caption"] as? String
        self.uid = postDic["uid"] as? String ?? ""
        let timestamp = postDic["date"] as? Timestamp
        self.date = timestamp?.dateValue()
        
        if let likes = postDic["likes"] as? [[String:Any]] {
            self.likes = likes
        }
        if let myid = Auth.auth().currentUser?.uid {
            // likesの配列の中にmyidが含まれているかチェックすることで、自分がいいねを押しているかを判断
            if let index = likes.firstIndex(where: { (like) -> Bool in
                let uid = like["uid"] as! String
                return uid == myid
            }) {
                isLiked = true
                likedTime = likes[index]["time"] as! TimeInterval
            }
        }
        
        //投稿を非表示にする
        if let blocks = postDic["blocks"] as? [[String:Any]] {
            self.blocks = blocks
        }
        if let myid = Auth.auth().currentUser?.uid {
            if let index = blocks.firstIndex(where: { (block) -> Bool in
                let uid = block["uid"] as! String
                return uid == myid
            }) {
                isReported = true
                blockedTime = blocks[index]["time"] as! TimeInterval
            }
        }
        
        if let reports = postDic["reports"] as? [[String:Any]] {
            self.reports = reports
        }
        if let myid = Auth.auth().currentUser?.uid {
            
            if let index = reports.firstIndex(where: { (report) -> Bool in
                let uid = report["uid"] as! String
                return uid == myid
            }) {
                myReportExist = true
                reportedTime = reports[index]["time"] as! TimeInterval
            }
        }
        //通報が20以上のときにisReportedをtrueにする
        if reports.count >= 20 {
            isReported = true
        }
        
        if let deletes = postDic["deletes"] as? [[String:Any]] {
            self.deletes = deletes
        }
        if let myid = Auth.auth().currentUser?.uid {
            
            if let index = deletes.firstIndex(where: { (delete) -> Bool in
                let uid = delete["uid"] as! String
                return uid == myid
            }) {
                deletedTime = deletes[index]["time"] as! TimeInterval
            }
        }
        if deletes.count >= 1 {
            isReported = true
        }
        
        if postDic["with_image"] != nil {
            self.with_image = postDic["with_image"] as! Bool
        }
        else {
            self.with_image = false
        }
        
        if let allComments = postDic["allComments"] as? [[String:Any]] {
            self.allComments = allComments
        }
        if let myid = Auth.auth().currentUser?.uid {
            if let index = allComments.firstIndex(where: { (allComment) -> Bool in
                let uid = allComment["uid"] as! String
                return uid == myid
            }) {
                isAllCommented = true
            }
        }
        
        if let comments = postDic["comments"] as? [[String:Any]] {
            self.comments = comments
        }
        if let myid = Auth.auth().currentUser?.uid {
            if let index = comments.firstIndex(where: { (comment) -> Bool in
                let uid = comment["uid"] as! String
                return uid == myid
            }) {
                isCommented = true
            }
        }
        
        if let join = postDic["join"] as? [[String:Any]] {
            self.join = join
        }
        if let myid = Auth.auth().currentUser?.uid {
            
            if let index = join.firstIndex(where: { (join) -> Bool in
                let uid = join["uid"] as! String
                return uid == myid
            }) {
                isJoined = true
                joinedTime = join[index]["time"] as! TimeInterval
            }
        }
        
        if let viewer = postDic["viewer"] as? [[String:Any]] {
            self.viewer = viewer
        }
        if let myid = Auth.auth().currentUser?.uid {
            
            if let index = viewer.firstIndex(where: { (view) -> Bool in
                let uid = view["uid"] as! String
                return uid == myid
            }) {
                viewed = true
                viewedTime = viewer[index]["time"] as! TimeInterval
            }
        }
    }
}



