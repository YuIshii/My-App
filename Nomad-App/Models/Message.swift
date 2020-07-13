//
//  Message.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import Foundation
import Firebase

class Message: NSObject {
    var id: String
    var name: String
    var message: String
    var uid: String
    var createdAt: Timestamp
    var time = Date.timeIntervalSinceReferenceDate
    
    var reports2: [[String:Any]] = []
    var reportedTime2: TimeInterval = 0
    var isReported2: Bool = false
    var myReportExist: Bool = false
    var deletes2: [[String:Any]] = []
    var deletedTime2: TimeInterval = 0
    
    var blocks2: [[String:Any]] = []
    var blockedTime2: TimeInterval = 0
    
    init(document: QueryDocumentSnapshot) {
        self.id = document.documentID
        self.name = document["name"] as? String ?? ""
        self.message = document["message"] as? String ?? ""
        self.uid = document["uid"] as? String ?? ""
        self.createdAt = document["createdAt"] as? Timestamp ?? Timestamp()
        
        self.time = document["time"] as! TimeInterval
        
        
        if let blocks2 = document["blocks2"] as? [[String:Any]] {
            self.blocks2 = blocks2
        }
        if let myid = Auth.auth().currentUser?.uid {
            if let index = blocks2.firstIndex(where: { (block) -> Bool in
                let uid = block["uid"] as! String
                return uid == myid
            }) {
                isReported2 = true
                blockedTime2 = blocks2[index]["time"] as! TimeInterval
            }
        }
        
        if let reports2 = document["reports2"] as? [[String:Any]] {
            self.reports2 = reports2
        }
        if let myid = Auth.auth().currentUser?.uid {
            if let index = reports2.firstIndex(where: { (report) -> Bool in
                let uid = report["uid"] as! String
                return uid == myid
            }) {
                myReportExist = true
                reportedTime2 = reports2[index]["time"] as! TimeInterval
            }
        }
        //通報が20以上になったらisReported2を有効化
        if reports2.count >= 20 {
            isReported2 = true
        }
        
        if let deletes2 = document["deletes2"] as? [[String:Any]] {
            self.deletes2 = deletes2
        }
        if let myid = Auth.auth().currentUser?.uid {
            
            if let index = deletes2.firstIndex(where: { (delete) -> Bool in
                let uid = delete["uid"] as! String
                return uid == myid
            }) {
                deletedTime2 = deletes2[index]["time"] as! TimeInterval
            }
        }
        //自分のテーブル表示にだけ反映させたかったらこれを}の中に入れるが今回は全体に反映させる
        if deletes2.count >= 1 {
            isReported2 = true
        }
    }
    
}


