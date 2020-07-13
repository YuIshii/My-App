//
//  MyPostsViewController.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase
import MessageUI
import NotificationBannerSwift

class MyPostsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var refreshControl = UIRefreshControl()
    
    // 投稿データを格納する配列
    var postArray: [PostData] = []
    // ブロックユーザーデータを格納する配列
    var blockUserArray: [String] = []
    
    private var postdata: PostData?
    
    // Firestoreのリスナー
    var listener: ListenerRegistration!
    var listener_block: ListenerRegistration!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //空セルのseparator(しきり線)を消す
        tableView.tableFooterView = UIView(frame: .zero)
        
        //テーブルビューの仕切り線を左端までつける
        tableView.separatorInset = .zero
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // カスタムセルを登録する
        let nib1 = UINib(nibName: "Post1TableViewCell", bundle: nil)
        tableView.register(nib1, forCellReuseIdentifier: "Cell1")
        
        let nib2 = UINib(nibName: "Post2TableViewCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: "Cell2")
        
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(self.refresh(sender:)), for: .valueChanged)
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.tabBarController?.tabBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.tintColor = UIColor.black
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        
        let backBarButtonItem = UIBarButtonItem()
        backBarButtonItem.title = "Back"
        self.navigationItem.backBarButtonItem = backBarButtonItem
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        
        let postsRef = Firestore.firestore().collection("posts").order(by: "date", descending: true)
        listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
            if let error = error {
                print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                return
            }
            
            self.blockCheck()
            
            // 取得したdocumentをもとにPostDataを作成し、postArrayの配列にする。
            self.postArray = querySnapshot!.documents.flatMap { document in
                print("DEBUG_PRINT: document取得 \(document.documentID)")
                let data = document.data()
                if (data == nil) {
                    return nil
                }
                let postData = PostData(document: document)
                postData.id = document.documentID
                let uid = Auth.auth().currentUser?.uid
                //PostData側でmyid == uidならis〇〇みたいにして同様にやる
                if postData.uid == uid && postData.isReported == false{
                    return postData
                }
                return nil
            }
            
            self.tableView.reloadData()
            sender.endRefreshing()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")
        
        if Auth.auth().currentUser != nil {
            // ログイン済み
            if listener == nil {
                // listener未登録なら、登録してスナップショットを受信する
                let postsRef = Firestore.firestore().collection("posts").order(by: "date", descending: true)
                listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
                    if let error = error {
                        print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                        return
                    }
                    
                    self.blockCheck()
                    
                    // 取得したdocumentをもとにPostDataを作成し、postArrayの配列にする。
                    self.postArray = querySnapshot!.documents.flatMap { document in
                        print("DEBUG_PRINT: document取得 \(document.documentID)")
                        let data = document.data()
                        if (data == nil) {
                            return nil
                        }
                        let postData = PostData(document: document)
                        postData.id = document.documentID
                        let uid = Auth.auth().currentUser?.uid
                        //PostData側でmyid == uidならis〇〇みたいにして同様にやる
                        if postData.uid == uid && postData.isReported == false{
                            return postData
                        }
                        return nil
                    }
                    
                    self.tableView.reloadData()
                }
            }
        } else {
            // ログイン未(またはログアウト済み)
            if listener != nil {
                // listener登録済みなら削除してpostArrayをクリアする
                listener.remove()
                listener = nil
                postArray = []
                tableView.reloadData()
            }
        }
    }
    
    func blockCheck() {
        if let myid = Auth.auth().currentUser?.uid {
            if listener_block == nil {
                let postsRef_block = Firestore.firestore().collection("blockUsers").document(myid)
                postsRef_block.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                        print("Document data: \(dataDescription)")
                    } else {
                        print("Document does not exist")
                    }
                    let postDic = document?.data()
                    if postDic != nil{
                        if let blockUsers = postDic!["users"] as? [String] {
                            self.blockUserArray = blockUsers
                            
                            self.postArray = self.postArray.filter {
                                if blockUsers.contains($0.uid) {
                                    return false
                                } else {
                                    return true
                                }
                            }
                            print("blockUsers:\(blockUsers)")
                            self.tableView.reloadData()
                        }
                    }
                }
            }
            print("block user list")
            print("self.blockUserArray.description:\(self.blockUserArray.description)")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let chatRoomViewController = storyboard.instantiateViewController(identifier: "ChatRoomViewController") as! ChatRoomViewController
        postdata = self.postArray[indexPath.row]
        //postdataをChatRoomViewControllerに渡す
        chatRoomViewController.postdata = postdata
        
       // viewerを更新する
       if let myid = Auth.auth().currentUser?.uid {
           // 更新データを作成する
           var updateValue: FieldValue
           var updateValue2: FieldValue
           
           if postdata!.viewed {
               print("古いmyidを消して新しいmyidを加えます")
               //再度新しい日付でmyidを加えるために一度古い日付で登録したmyidを消す
               updateValue = FieldValue.arrayRemove([["uid": myid, "time": postdata!.viewedTime]])
               updateValue2 = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
               let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
               postRef.updateData(["viewer": updateValue])
               postRef.updateData(["viewer": updateValue2])
           } else{
               print("新しいmyidを加えます")
               updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
               let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
               postRef.updateData(["viewer": updateValue])
           }
       }
        navigationController?.pushViewController(chatRoomViewController, animated: true)
        //選択状態の解除
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("postArray.count:\(postArray.count)")
        return self.postArray.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //現在ログイン中のユーザーIDのみ取り出す
        let uid = Auth.auth().currentUser?.uid
        // with_imageがtrueの場合 Post2TableViewCell
        if self.postArray[indexPath.row].with_image == true {
            print("Create Post2TableViewCell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell2", for: indexPath) as! Post2TableViewCell
            postdata = self.postArray[indexPath.row]
            cell.postdata = postdata
            cell.setPostData(postArray[indexPath.row])
            // セル内のボタンのアクションをソースコードで設定する
            cell.likeButton.addTarget(self, action:#selector(handleButton(_:forEvent:)), for: .touchUpInside)
            //セル押下時のハイライト(色が濃くなる)を無効
            cell.selectionStyle = .none
            
            if postdata?.uid == uid {
                cell.alertButton.removeTarget(self, action: #selector(alertButton2(_:forEvent:)), for: .touchUpInside)
                //スレッドの削除アラートを表示する
                cell.alertButton.addTarget(self, action:#selector(alertButton(_:forEvent:)), for: .touchUpInside)
            }else{
                cell.alertButton.removeTarget(self, action: #selector(alertButton(_:forEvent:)), for: .touchUpInside)
                //スレッドの通報アラートを表示する
                cell.alertButton.addTarget(self, action:#selector(alertButton2(_:forEvent:)), for: .touchUpInside)
            }
            cell.commentButton.addTarget(self, action:#selector(toComment(_:forEvent:)), for: .touchUpInside)
            return cell
        }
            // with_imageがfalseの場合 Post1TableViewCell
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell1", for: indexPath) as! Post1TableViewCell
            //Post1TableViewCellのpostdataにpostArray[indexPath.row]を渡す
            postdata = self.postArray[indexPath.row]
            //Post1TableViewCellのpostdataにpostArray[indexPath.row]を渡す
            cell.postdata = postdata
            cell.setPostData(self.postArray[indexPath.row])
            // セル内のボタンのアクションをソースコードで設定する
            cell.likeButton.addTarget(self, action:#selector(handleButton(_:forEvent:)), for: .touchUpInside)
            //セル押下時のハイライト(色が濃くなる)を無効
            cell.selectionStyle = .none
            //投稿した人のuidと現在操作しているuidが一緒なら
            if postdata?.uid == uid {
                cell.alertButton.removeTarget(self, action: #selector(alertButton2(_:forEvent:)), for: .touchUpInside)
                //スレッドの削除アラートを表示する
                cell.alertButton.addTarget(self, action:#selector(alertButton(_:forEvent:)), for: .touchUpInside)
            }else{
                cell.alertButton.removeTarget(self, action: #selector(alertButton(_:forEvent:)), for: .touchUpInside)
                //スレッドの通報アラートを表示する
                cell.alertButton.addTarget(self, action:#selector(alertButton2(_:forEvent:)), for: .touchUpInside)
            }
            cell.commentButton.addTarget(self, action:#selector(toComment(_:forEvent:)), for: .touchUpInside)
            return cell
        }
    }
    
    @objc func alertButton(_ sender: UIButton, forEvent event: UIEvent){
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: point)
        
        print("アラートボタン")
        // インスタンス生成　styleはActionSheet.
        let myAlert = UIAlertController(title: "あなたの投稿です", message: "この投稿を削除しますか？", preferredStyle: UIAlertController.Style.actionSheet)
        // アクションを生成.
        let myAction_1 = UIAlertAction(title: "投稿を削除する", style: UIAlertAction.Style.default, handler: {
            (action: UIAlertAction!) in
            
            let alert: UIAlertController = UIAlertController(title: "投稿の削除", message: "本当にこの投稿を削除してよろしいでしょうか？", preferredStyle:  UIAlertController.Style.alert)
            let defaultAction: UIAlertAction = UIAlertAction(title: "削除", style: UIAlertAction.Style.destructive, handler:{
                (action: UIAlertAction!) -> Void in
                print("削除")
                // 削除のコード
                
                // 配列からタップされたインデックスのデータを取り出す
                let postData = self.postArray[indexPath!.row]
                
                if let myid = Auth.auth().currentUser?.uid {
                    // 更新データを作成する
                    var updateValue: FieldValue
                    print("新しいmyidを加えます")
                    updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(postData.id)
                    postRef.updateData(["deletes": updateValue])
                    
                    let banner = NotificationBanner(title: "削除しました", leftView: nil, rightView: nil, style: .info, colors: nil)
                    banner.autoDismiss = false
                    banner.dismissOnTap = true
                    banner.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: self.navigationController!)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                        banner.dismiss()
                    })
                }
            })
            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.default, handler:{
                (action: UIAlertAction!) -> Void in
                print("Cancel")
            })
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            self.present(alert, animated: true, completion: nil)
        })
        let myAction_2 = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: {
            (action: UIAlertAction!) in
            print("キャンセル")
        })
        // アクションを追加.
        myAlert.addAction(myAction_1)
        myAlert.addAction(myAction_2)
        self.present(myAlert, animated: true, completion: nil)
    }
    
    @objc func alertButton2(_ sender: UIButton, forEvent event: UIEvent){
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: point)
        
        print("alert")
        // インスタンス生成
        let myAlert = UIAlertController(title: "問題のある投稿", message: "あてはまるものをお選びください", preferredStyle: UIAlertController.Style.actionSheet)
        
        // アクションを生成.
        let myAction_1 = UIAlertAction(title: "投稿を通報する", style: UIAlertAction.Style.default, handler: {
            (action: UIAlertAction!) in
            print("通報")
            
            // 配列からタップされたインデックスのデータを取り出す
            let postData = self.postArray[indexPath!.row]
            let documentId = postData.id
            let caption:String = String(postData.caption!)
            
            if let myid = Auth.auth().currentUser?.uid {
                // 更新データを作成する
                var updateValue: FieldValue
                if postData.myReportExist {
                    print("既に通報しています")
                    let alertController:UIAlertController =
                        UIAlertController(title:"投稿の通報",
                                          message: "あてはまるものをお選びください",
                                          preferredStyle: .alert)
                    
                    // Default のaction
                    let action1:UIAlertAction =
                        UIAlertAction(title: "不審な内容またはスパム投稿である",
                                      style: .default,
                                      handler:{
                                        (action:UIAlertAction!) -> Void in
                                        // 処理
                                        print("新しいmyidを加えます")
                                        
                                        //メーラーを起動する
                                        guard MFMailComposeViewController.canSendMail() else {
                                            return
                                        }
                                        
                                        let composer = MFMailComposeViewController()
                                        composer.mailComposeDelegate = self
                                        composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                        composer.setSubject("問題の詳細を報告") // 件名
                                        composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false) // 本文
                                        self.present(composer,animated: true)
                        })
                    
                    let action2:UIAlertAction =
                        UIAlertAction(title: "誹謗中傷をしている",
                                      style: .default,
                                      handler:{
                                        (action:UIAlertAction!) -> Void in
                                        //メーラーを起動する
                                        guard MFMailComposeViewController.canSendMail() else {
                                            return
                                        }
                                        
                                        let composer = MFMailComposeViewController()
                                        composer.mailComposeDelegate = self
                                        composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                        composer.setSubject("問題の詳細を報告") // 件名
                                        composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false) // 本文
                                        self.present(composer,animated: true)
                        })
                    
                    let action3:UIAlertAction =
                        UIAlertAction(title: "不適切な内容を含んでいる",
                                      style: .default,
                                      handler:{
                                        (action:UIAlertAction!) -> Void in
                                        //メーラーを起動する
                                        guard MFMailComposeViewController.canSendMail() else {
                                            return
                                        }
                                        
                                        let composer = MFMailComposeViewController()
                                        composer.mailComposeDelegate = self
                                        composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                        composer.setSubject("問題の詳細を報告") // 件名
                                        composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false) // 本文
                                        self.present(composer,animated: true)
                        })
                    
                    let action4:UIAlertAction =
                        UIAlertAction(title: "自殺の意思をほのめかしている",
                                      style: .default,
                                      handler:{
                                        (action:UIAlertAction!) -> Void in
                                        // 処理
                                        print("新しいmyidを加えます")
                                        
                                        //メーラーを起動する
                                        guard MFMailComposeViewController.canSendMail() else {
                                            return
                                        }
                                        
                                        let composer = MFMailComposeViewController()
                                        composer.mailComposeDelegate = self
                                        composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                        composer.setSubject("問題の詳細を報告") // 件名
                                        composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false) // 本文
                                        self.present(composer,animated: true)
                        })
                    
                    // Cancel のaction
                    let cancelAction:UIAlertAction =
                        UIAlertAction(title: "キャンセル",
                                      style: .cancel,
                                      handler:{
                                        (action:UIAlertAction!) -> Void in
                                        // 処理
                                        print("キャンセル")
                        })
                    
                    // actionを追加
                    alertController.addAction(action1)
                    alertController.addAction(action2)
                    alertController.addAction(action3)
                    alertController.addAction(action4)
                    alertController.addAction(cancelAction)
                    
                    // UIAlertControllerの起動
                    self.present(alertController, animated: true, completion: nil)
                    
                } else{
                    
                    let alertController:UIAlertController =
                        UIAlertController(title:"投稿の通報",
                                          message: "あてはまるものをお選びください",
                                          preferredStyle: .alert)
                    
                    
                    updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(postData.id)
                    
                    // Default のaction
                    let action1:UIAlertAction =
                        UIAlertAction(title: "不審な内容またはスパム投稿である",
                                      style: .default,
                                      handler:{
                                        (action:UIAlertAction!) -> Void in
                                        // 処理
                                        print("新しいmyidを加えます")
                                        
                                        postRef.updateData(["reports": updateValue])
                                        
                                        //メーラーを起動する
                                        guard MFMailComposeViewController.canSendMail() else {
                                            return
                                        }
                                        
                                        let composer = MFMailComposeViewController()
                                        composer.mailComposeDelegate = self
                                        composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                        composer.setSubject("問題の詳細を報告") // 件名
                                        composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false) // 本文
                                        self.present(composer,animated: true)
                        })
                    
                    let action2:UIAlertAction =
                        UIAlertAction(title: "誹謗中傷をしている",
                                      style: .default,
                                      handler:{
                                        (action:UIAlertAction!) -> Void in
                                        // 処理
                                        print("新しいmyidを加えます")
                                        
                                        postRef.updateData(["reports": updateValue])
                                        
                                        //メーラーを起動する
                                        guard MFMailComposeViewController.canSendMail() else {
                                            return
                                        }
                                        
                                        let composer = MFMailComposeViewController()
                                        composer.mailComposeDelegate = self
                                        composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                        composer.setSubject("問題の詳細を報告") // 件名
                                        composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false) // 本文
                                        self.present(composer,animated: true)
                        })
                    
                    let action3:UIAlertAction =
                        UIAlertAction(title: "不適切な内容を含んでいる",
                                      style: .default,
                                      handler:{
                                        (action:UIAlertAction!) -> Void in
                                        // 処理
                                        print("新しいmyidを加えます")
                                        
                                        postRef.updateData(["reports": updateValue])
                                        
                                        //メーラーを起動する
                                        guard MFMailComposeViewController.canSendMail() else {
                                            return
                                        }
                                        
                                        let composer = MFMailComposeViewController()
                                        composer.mailComposeDelegate = self
                                        composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                        composer.setSubject("問題の詳細を報告") // 件名
                                        composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false) // 本文
                                        self.present(composer,animated: true)
                        })
                    
                    let action4:UIAlertAction =
                        UIAlertAction(title: "自殺の意思をほのめかしている",
                                      style: .default,
                                      handler:{
                                        (action:UIAlertAction!) -> Void in
                                        // 処理
                                        print("新しいmyidを加えます")
                                        
                                        postRef.updateData(["reports": updateValue])
                                        
                                        //メーラーを起動する
                                        guard MFMailComposeViewController.canSendMail() else {
                                            return
                                        }
                                        
                                        let composer = MFMailComposeViewController()
                                        composer.mailComposeDelegate = self
                                        composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                        composer.setSubject("問題の詳細を報告") // 件名
                                        composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false) // 本文
                                        self.present(composer,animated: true)
                        })
                    
                    // Cancel のaction
                    let cancelAction:UIAlertAction =
                        UIAlertAction(title: "キャンセル",
                                      style: .cancel,
                                      handler:{
                                        (action:UIAlertAction!) -> Void in
                                        // 処理
                                        print("キャンセル")
                        })
                    
                    // actionを追加
                    alertController.addAction(action1)
                    alertController.addAction(action2)
                    alertController.addAction(action3)
                    alertController.addAction(action4)
                    alertController.addAction(cancelAction)
                    
                    // UIAlertControllerの起動
                    self.present(alertController, animated: true, completion: nil)
                    
                }
            }
        })
        
        let myAction_2 = UIAlertAction(title: "投稿を非表示にする", style: UIAlertAction.Style.default, handler: {
            (action: UIAlertAction!) in
            
            let alert: UIAlertController = UIAlertController(title: "投稿の非表示", message: "本当にこの投稿を非表示にしてよろしいでしょうか？", preferredStyle:  UIAlertController.Style.alert)
            
            let defaultAction: UIAlertAction = UIAlertAction(title: "非表示", style: UIAlertAction.Style.destructive, handler:{
                (action: UIAlertAction!) -> Void in
                
                print("非表示")
                
                // 配列からタップされたインデックスのデータを取り出す
                let postData = self.postArray[indexPath!.row]
                
                if let myid = Auth.auth().currentUser?.uid {
                    // 更新データを作成する
                    var updateValue: FieldValue
                    print("新しいmyidを加えます")
                    updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(postData.id)
                    postRef.updateData(["blocks": updateValue])
                    let banner = NotificationBanner(title: "非表示にしました", leftView: nil, rightView: nil, style: .info, colors: nil)
                    banner.autoDismiss = false
                    banner.dismissOnTap = true
                    banner.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: self.navigationController!)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                        banner.dismiss()
                    })
                }
            })
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.default, handler:{
                (action: UIAlertAction!) -> Void in
                print("Cancel")
            })
            
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            
            self.present(alert, animated: true, completion: nil)
        })
        
        let myAction_3 = UIAlertAction(title: "ユーザーをブロックする", style: UIAlertAction.Style.default, handler: {
                (action: UIAlertAction!) in
                
                let alert: UIAlertController = UIAlertController(title: "ユーザーのブロック", message: "このユーザーの投稿は今後表示されなくなりますがよろしいでしょうか？", preferredStyle:  UIAlertController.Style.alert)
                
                let defaultAction: UIAlertAction = UIAlertAction(title: "ブロック", style: UIAlertAction.Style.destructive, handler:{
                    (action: UIAlertAction!) -> Void in
                    
                    print("ブロック")
                    // 配列からタップされたインデックスのデータを取り出す
                    let postData = self.postArray[indexPath!.row]
                    if let myid = Auth.auth().currentUser?.uid {
                        
                        // 更新データを作成する
                        var updateValue: FieldValue
                        updateValue = FieldValue.arrayUnion([postData.uid])
                        let postRef = Firestore.firestore().collection("blockUsers").document(myid)
                        
                        postRef.getDocument { (document, error) in
                            
                            if let document = document, document.exists {
                                
                                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                                print("Document data: \(dataDescription)")
                                
                                postRef.updateData(["users": updateValue])
                                let banner = NotificationBanner(title: "ブロックしました", leftView: nil, rightView: nil, style: .info, colors: nil)
                                banner.autoDismiss = false
                                banner.dismissOnTap = true
                                banner.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: self.navigationController!)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                                    banner.dismiss()
                                    self.blockCheck()
                                })
                                
                            } else {
                                print("Document does not exist")
                                
                                postRef.setData(["users": updateValue])
                                let banner = NotificationBanner(title: "ブロックしました", leftView: nil, rightView: nil, style: .info, colors: nil)
                                banner.autoDismiss = false
                                banner.dismissOnTap = true
                                banner.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: self.navigationController!)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                                    banner.dismiss()
                                    self.blockCheck()
                                })
                            }
                        }
                    }
                })
                
                let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.default, handler:{
                    (action: UIAlertAction!) -> Void in
                    print("Cancel")
                })
                
                alert.addAction(cancelAction)
                alert.addAction(defaultAction)
                self.present(alert, animated: true, completion: nil)
                
            })
            
            let cancelAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: {
                (action: UIAlertAction!) in
                print("キャンセル")
            })
            // アクションを追加.
            myAlert.addAction(myAction_1)
            myAlert.addAction(myAction_2)
            myAlert.addAction(myAction_3)
            myAlert.addAction(cancelAction)
            self.present(myAlert, animated: true, completion: nil)
        }
    
    // セル内のボタンがタップされた時に呼ばれるメソッド
    @objc func handleButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: likeボタンがタップされました。")
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
        
        // likesを更新する
        if let myid = Auth.auth().currentUser?.uid {
            // 更新データを作成する
            var updateValue: FieldValue
            if postData.isLiked {
                // すでにいいねをしている場合は、いいね解除のためmyidを取り除く更新データを作成
                updateValue = FieldValue.arrayRemove([["uid": myid, "time": postData.likedTime]])
            } else {
                // 今回新たにいいねを押した場合は、myidを追加する更新データを作成
                updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
            }
            // likesに更新データを書き込む
            let postRef = Firestore.firestore().collection("posts").document(postData.id)
            postRef.updateData(["likes": updateValue])
        }
        
    }
    
    @objc func toComment(_ sender: UIButton, forEvent event: UIEvent) {
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let chatRoomViewController = storyboard.instantiateViewController(identifier: "ChatRoomViewController") as! ChatRoomViewController
        
        postdata = postArray[indexPath!.row]
        //postdataをChatRoomViewControllerに渡す
        chatRoomViewController.postdata = postdata
        
        // viewerを更新する
        if let myid = Auth.auth().currentUser?.uid {
            // 更新データを作成する
            var updateValue: FieldValue
            var updateValue2: FieldValue
            
            if postdata!.viewed {
                print("古いmyidを消して新しいmyidを加えます")
                //再度新しい日付でmyidを加えるために一度古い日付で登録したmyidを消す
                updateValue = FieldValue.arrayRemove([["uid": myid, "time": postdata!.viewedTime]])
                updateValue2 = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                postRef.updateData(["viewer": updateValue])
                postRef.updateData(["viewer": updateValue2])
            } else{
                print("新しいmyidを加えます")
                updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                postRef.updateData(["viewer": updateValue])
            }
        }
        navigationController?.pushViewController(chatRoomViewController, animated: true)
        //選択状態の解除
        tableView.deselectRow(at: indexPath as! IndexPath, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    if let _ = error {
        controller.dismiss(animated: true)
    }
    switch result {
        case .cancelled:
            print("Email Send Cancelled")
            let banner = NotificationBanner(title: "通報しました", leftView: nil, rightView: nil, style: .info, colors: nil)
            banner.autoDismiss = false
            banner.dismissOnTap = true
            banner.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: self.navigationController!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                banner.dismiss()
            })
            break
        case .saved:
            print("Email Saved as a Draft")
            let banner = NotificationBanner(title: "通報しました", leftView: nil, rightView: nil, style: .info, colors: nil)
            banner.autoDismiss = false
            banner.dismissOnTap = true
            banner.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: self.navigationController!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                banner.dismiss()
            })
            break
        case .sent:
            print("Email Sent Successfully")
            let banner = NotificationBanner(title: "通報しました", leftView: nil, rightView: nil, style: .info, colors: nil)
            banner.autoDismiss = false
            banner.dismissOnTap = true
            banner.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: self.navigationController!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                banner.dismiss()
            })
            break
        case .failed:
            print("Email Send Failed")
            let banner = NotificationBanner(title: "通報しました", leftView: nil, rightView: nil, style: .warning, colors: nil)
            banner.autoDismiss = false
            banner.dismissOnTap = true
            banner.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: self.navigationController!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                banner.dismiss()
            })
            break
        default:
            break
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        // 他の画面から segue を使って戻ってきた時に呼ばれる
    }
}
