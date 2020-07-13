//
//  ChatRoomViewController.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase
import MessageUI
import NotificationBannerSwift
import PKHUD

class ChatRoomViewController: UIViewController {
    
    var postdata: PostData?
    var message: Message?
    
    // 投稿データを格納する配列
    var postArray: [PostData] = []
    
    // ブロックユーザーデータを格納する配列
    var blockUserArray: [String] = []
    
    private let cellId = "cellId"
    private var messages = [Message]()
    
    private var refreshControl = UIRefreshControl()
    
    private lazy var chatInputAccessoryView: ChatInputAccessoryView = {
        let view = ChatInputAccessoryView()
        view.frame = .init(x: 0, y: 0, width: view.frame.width, height: 100)
        view.delegate = self
        return view
    }()
    
    @IBOutlet weak var chatRoomTableView: UITableView!
    
    @IBOutlet weak var unfocusBtn: UIButton!
    
    // Firestoreのリスナー
    var listener: ListenerRegistration!
    var listener_block: ListenerRegistration!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ナビゲーションバーの色
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        //タブバーの色
        self.tabBarController?.tabBar.barTintColor = UIColor.white
        
        blockCheck()
        
        fetchPosts()
        fetchMessages()
        
        // カスタムセルを登録する
        let nib1 = UINib(nibName: "Post3TableViewCell", bundle: nil)
        chatRoomTableView.register(nib1, forCellReuseIdentifier: "Cell3")
        let nib2 = UINib(nibName: "Post4TableViewCell", bundle: nil)
        chatRoomTableView.register(nib2, forCellReuseIdentifier: "Cell4")
        
        //空セルのseparator(しきり線)を消す
        chatRoomTableView.tableFooterView = UIView(frame: .zero)
        chatRoomTableView.separatorInset = .zero
        
        chatRoomTableView.delegate = self
        chatRoomTableView.dataSource = self
        chatRoomTableView.register(UINib(nibName: "ChatRoomTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
        
        navigationController?.navigationBar.tintColor = .black
        navigationItem.title = "コメント"
        
        chatRoomTableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(self.refresh(sender:)), for: .valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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
                            
                            self.messages = self.messages.filter {
                                if blockUsers.contains($0.uid) {
                                    return false
                                } else {
                                    return true
                                }
                            }
                            print("blockUsers:\(blockUsers)")
                            self.chatRoomTableView.reloadData()
                        }
                    }
                }
            }
            print("block user list")
            print("self.blockUserArray.description:\(self.blockUserArray.description)")
        }
    }
    
    @IBAction func unfocus(_ sender: Any) {
        //入力欄を表示しているときに入力欄以外をタップすると入力欄を閉じるようにする
        self.chatInputAccessoryView.chatTextView.resignFirstResponder()
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if notification.name == UIResponder.keyboardWillChangeFrameNotification || notification.name == UIResponder.keyboardWillShowNotification {
            if ( keyboardSize.height > 100 ) {
                self.view.bringSubviewToFront(unfocusBtn)
            }
        }
        else if notification.name == UIResponder.keyboardWillHideNotification {
            self.view.sendSubviewToBack(unfocusBtn)
        }
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        print("refresh")
        
        blockCheck()
        
        let postsRef = Firestore.firestore().collection("posts").document(postdata!.id)
        listener = postsRef.addSnapshotListener() { (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            self.postdata  = PostData(document: document)
        }
        
        let postsRef2 = Firestore.firestore().collection("posts").document(postdata!.id).collection("messages").order(by: "createdAt", descending: true)
        listener = postsRef2.addSnapshotListener() { (querySnapshot, error) in
            if let error = error {
                print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                return
            }
            self.messages = querySnapshot!.documents.flatMap { document in
                print("DEBUG_PRINT: document取得 \(document.documentID)")
                let message = Message(document: document)
                message.id = document.documentID
                if message.isReported2 == false {
                    return message
                }
                return nil
            }
            self.chatRoomTableView.reloadData()
            sender.endRefreshing()
        }
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return chatInputAccessoryView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    private func fetchPosts(){
        
        let postsRef = Firestore.firestore().collection("posts").document(postdata!.id)
        listener = postsRef.addSnapshotListener() { (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            self.postdata  = PostData(document: document)
            self.chatRoomTableView.reloadData()
        }
    }
    
    private func fetchMessages(){
        
        let postsRef = Firestore.firestore().collection("posts").document(postdata!.id).collection("messages").order(by: "createdAt", descending: true)
        listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
            if let error = error {
                print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                return
            }
            self.messages = querySnapshot!.documents.flatMap { document in
                print("DEBUG_PRINT: document取得 \(document.documentID)")
                let message = Message(document: document)
                message.id = document.documentID
                if message.isReported2 == false {
                    return message
                }
                return nil
            }
            self.chatRoomTableView.reloadData()
        }
    }
}

extension ChatRoomViewController: ChatInputAccessoryViewDelegate {
    
    //chatroomTableViewCellのsendButtonを押したら、コメントを保存できるようにする
    func tappedSendButton(text: String) {
        
        let timeInterval = Date.timeIntervalSinceReferenceDate
        
        chatInputAccessoryView.removeText()
        
        //不要な改行削除
        let msg = text.replace("\n", "")
        //テキストの半角空白文字削除
        let trimmedString = msg.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedString.count == 0{
            print("DEBUG_PRINT: コメントが空白です")
            HUD.flash(.labeledError(title: "エラー", subtitle: "コメントが空白です"), delay: 1.4)
            return
        }else if trimmedString.count > 1000{
            print("DEBUG_PRINT: コメントが1000文字をこえています")
            HUD.flash(.labeledError(title: "エラー", subtitle: "コメントが1000文字をこえています"), delay: 1.4)
            return
        }
        
        let trimmedString2 = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        //現在ログイン中のユーザー名を取り出す
        guard let name = Auth.auth().currentUser?.displayName else {return}
        //現在ログイン中のユーザーIDを取り出す
        guard let uid = Auth.auth().currentUser?.uid else { return }
        //現在ログイン中のユーザーのメールアドレスを取り出す
        guard let email = Auth.auth().currentUser?.email else { return }
        
        let docData = [
            "name": name,
            "createdAt": Timestamp(),
            "time": timeInterval,
            "uid": uid,
            "message": trimmedString2,
            "email": email,
            ] as [String : Any]
        let ref = Firestore.firestore().collection("posts").document(postdata!.id).collection("messages").document()
        ref.setData(docData) { (err) in
            if let err = err{
                print("コメント情報の保存に失敗しました。\(err)")
                return
            }
            
            let banner = NotificationBanner(title: "コメントを送信しました", leftView: nil, rightView: nil, style: .info, colors: nil)
            banner.autoDismiss = false
            banner.dismissOnTap = true
            banner.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: self.navigationController!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                banner.dismiss()
            })
            
            //生成されるセルのdocumentIDを取得する
            let documentId = ref.documentID
            print("コメントの保存に成功しました。")
            print("documentId:\(documentId)")
            
            // commentsを更新する
            if let myid = Auth.auth().currentUser?.uid {
                // 更新データを作成する
                var updateValue: FieldValue
                var updateValue2: FieldValue
                
                if self.postdata!.isCommented {
                    updateValue = FieldValue.arrayUnion([["uid": myid, "time": timeInterval]])
                    updateValue2 = FieldValue.arrayUnion([["uid": myid, "time": timeInterval]])
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                    postRef.updateData(["comments": updateValue])
                    postRef.updateData(["allComments": updateValue2])
                } else {
                    updateValue = FieldValue.arrayUnion([["uid": myid, "time": timeInterval]])
                    updateValue2 = FieldValue.arrayUnion([["uid": myid, "time": timeInterval]])
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                    postRef.updateData(["comments": updateValue])
                    postRef.updateData(["allComments": updateValue2])
                }
                
                var updateValue3: FieldValue
                var updateValue4: FieldValue
                
                if self.postdata!.isJoined {
                    print("古いmyidを消して新しいmyidを加えます")
                    //再度新しい日付でmyidを加えるために一度古い日付で登録したmyidを消す
                    updateValue3 = FieldValue.arrayRemove([["uid": myid, "time": self.postdata!.joinedTime]])
                    updateValue4 = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                    postRef.updateData(["join": updateValue3])
                    postRef.updateData(["join": updateValue4])
                } else{
                    print("新しいmyidを加えます")
                    updateValue3 = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                    postRef.updateData(["join": updateValue3])
                }
            }
        }
    }
}

extension ChatRoomViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // セクションの背景色を変更する
        view.tintColor = UIColor.rgb(red: 240, green: 240, blue: 240)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        chatRoomTableView.estimatedRowHeight = 20
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0{
            return 1
        }else if section == 1 {
            return self.messages.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0{
            return 0
        }else if section == 1 {
            return 0
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            print("スレッドがタップされました。")
            chatInputAccessoryView.sendButton.isEnabled = false
            let blank = ""
            chatInputAccessoryView.chatTextView.text = blank
            chatInputAccessoryView.chatTextView.becomeFirstResponder()
        } else if indexPath.section == 1 {
            print("コメントがタップされました。")
            chatInputAccessoryView.sendButton.isEnabled = false
            // 配列からタップされたインデックスのデータを取り出す
            let messageData = self.messages[indexPath.row]
            //コメントの投稿者の名前を取り出す
            let name = messageData.name
            let replyName = ">>" + name + "さん\n"
            chatInputAccessoryView.chatTextView.text = replyName
            chatInputAccessoryView.chatTextView.becomeFirstResponder()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //現在ログイン中のユーザーIDを取り出す
        let uid = Auth.auth().currentUser?.uid
        
        //セクション1は投稿を表示
        if indexPath.section == 0 {
            // with_imageがtrueの場合 Post2TableViewCell
            if self.postdata?.with_image == true {
                print("Create Post4TableViewCell")
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell4", for: indexPath) as! Post4TableViewCell
                
                cell.postdata = postdata
                cell.setPostData(postdata!)
                // セル内のボタンのアクションをソースコードで設定する
                cell.likeButton.addTarget(self, action:#selector(handleButton(_:forEvent:)), for: .touchUpInside)
                //セル押下時のハイライト(色が濃くなる)を無効
                cell.selectionStyle = .none
                //投稿した人のuidと現在操作しているuidが一緒なら
                if postdata?.uid == uid{
                    
                    cell.alertButton.removeTarget(self, action: #selector(alertButton2(_:forEvent:)), for: .touchUpInside)
                    //スレッドの削除アラートを表示する
                    cell.alertButton.addTarget(self, action:#selector(alertButton(_:forEvent:)), for: .touchUpInside)
                }else{
                    
                    cell.alertButton.removeTarget(self, action: #selector(alertButton(_:forEvent:)), for: .touchUpInside)
                    //スレッドの通報アラートを表示する
                    cell.alertButton.addTarget(self, action:#selector(alertButton2(_:forEvent:)), for: .touchUpInside)
                }
                return cell
            }
                // with_imageがfalseの場合 Post1TableViewCell
            else {
                print("Create Post3TableViewCell")
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell3", for: indexPath) as! Post3TableViewCell
                
                cell.postdata = postdata
                cell.setPostData(postdata!)
                // セル内のボタンのアクションをソースコードで設定する
                cell.likeButton.addTarget(self, action:#selector(handleButton(_:forEvent:)), for: .touchUpInside)
                //セル押下時のハイライト(色が濃くなる)を無効
                cell.selectionStyle = .none
                //投稿した人のuidと現在操作しているuidが一緒なら
                if postdata?.uid == uid{
                    
                    cell.alertButton.removeTarget(self, action: #selector(alertButton2(_:forEvent:)), for: .touchUpInside)
                    //スレッドの削除アラートを表示する
                    cell.alertButton.addTarget(self, action:#selector(alertButton(_:forEvent:)), for: .touchUpInside)
                }else{
                    
                    cell.alertButton.removeTarget(self, action: #selector(alertButton(_:forEvent:)), for: .touchUpInside)
                    //スレッドの通報アラートを表示する
                    cell.alertButton.addTarget(self, action:#selector(alertButton2(_:forEvent:)), for: .touchUpInside)
                }
                return cell
            }
            //セクション2はコメント欄を表示
        }else {
            let cell = chatRoomTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatRoomTableViewCell
            message = self.messages[indexPath.row]
            //ChatRoomTableViewCellのmessageとpostdataにそれぞれmessages[indexPath.row]とpostdataを渡す
            cell.postdata = postdata
            cell.message = message
            //セル押下時のハイライト(色が濃くなる)を無効
            cell.selectionStyle = .none
            
            //スレッドを作成した人が他の人のコメントを削除する場合
            if postdata?.uid == uid && message?.uid != uid {
                cell.alertButton.removeTarget(self, action: #selector(alertButton4(_:forEvent:)), for: .touchUpInside)
                cell.alertButton.removeTarget(self, action: #selector(alertButton3(_:forEvent:)), for: .touchUpInside)
                //コメントの削除アラートを表示する(ただし、commentsは減らさない)
                cell.alertButton.addTarget(self, action:#selector(alertButton3b(_:forEvent:)), for: .touchUpInside)
            }
                //コメントした人のuidと現在操作しているuidが一緒の場合
            else if message?.uid == uid {
                cell.alertButton.removeTarget(self, action: #selector(alertButton4(_:forEvent:)), for: .touchUpInside)
                cell.alertButton.removeTarget(self, action: #selector(alertButton3b(_:forEvent:)), for: .touchUpInside)
                //コメントの削除アラートを表示する
                cell.alertButton.addTarget(self, action:#selector(alertButton3(_:forEvent:)), for: .touchUpInside)
            }else{
                cell.alertButton.removeTarget(self, action: #selector(alertButton3(_:forEvent:)), for: .touchUpInside)
                cell.alertButton.removeTarget(self, action: #selector(alertButton3b(_:forEvent:)), for: .touchUpInside)
                //コメントの通報アラートを表示する
                cell.alertButton.addTarget(self, action:#selector(alertButton4(_:forEvent:)), for: .touchUpInside)
            }
            return cell
        }
    }
    
    // セル内のボタンがタップされた時に呼ばれるメソッド
    @objc func handleButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: likeボタンがタップされました。")
        
        // likesを更新する
        if let myid = Auth.auth().currentUser?.uid {
            // 更新データを作成する
            var updateValue: FieldValue
            if postdata!.isLiked {
                // すでにいいねをしている場合は、いいね解除のためmyidを取り除く更新データを作成
                updateValue = FieldValue.arrayRemove([["uid": myid, "time": postdata!.likedTime]])
                postdata!.isLiked = false // falseにすべき
            } else {
                // 今回新たにいいねを押した場合は、myidを追加する更新データを作成
                updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                postdata!.isLiked = true // trueにすべき
            }
            // likesに更新データを書き込む
            let postRef = Firestore.firestore().collection("posts").document(postdata!.id)
            postRef.updateData(["likes": updateValue])
        }
    }
    
    //スレッドを作成した人がスレッドを削除するとき
    @objc func alertButton(_ sender: UIButton, forEvent event: UIEvent){
        
        print("アラートボタン")
        
        // インスタンス生成　styleはActionSheet.
        let myAlert = UIAlertController(title: "あなたの投稿です", message: "この投稿を削除しますか？", preferredStyle: UIAlertController.Style.actionSheet)
        // アクションを生成.
        let myAction_1 = UIAlertAction(title: "投稿を削除する", style: UIAlertAction.Style.default, handler: {
            (action: UIAlertAction!) in
            let alert: UIAlertController = UIAlertController(title: "投稿の削除", message: "本当にこの投稿を削除してよろしいでしょうか？", preferredStyle:  UIAlertController.Style.alert)
            
            let defaultAction: UIAlertAction = UIAlertAction(title: "削除", style: UIAlertAction.Style.destructive, handler:{
                (action: UIAlertAction!) -> Void in
                //削除のコード
                //firestoreをインスタンスにしてメンバにしておく
                if let myid = Auth.auth().currentUser?.uid {
                    // 更新データを作成する
                    var updateValue: FieldValue
                    print("新しいmyidを加えます")
                    updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                    postRef.updateData(["deletes": updateValue])
                    
                    //遷移してから以下のコメントを出したい
                    let banner = NotificationBanner(title: "削除しました", leftView: nil, rightView: nil, style: .info, colors: nil)
                    banner.autoDismiss = false
                    banner.dismissOnTap = true
                    banner.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: self.navigationController!)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                        banner.dismiss()
                        //遷移元に戻る
                        self.navigationController?.popViewController(animated: true)
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
    
    //スレッドを作成した人以外がスレッドを通報するとき
    @objc func alertButton2(_ sender: UIButton, forEvent event: UIEvent){
        
        print("alert")
        // インスタンス生成　styleはActionSheet.
        let myAlert = UIAlertController(title: "問題のある投稿", message: "あてはまるものをお選びください", preferredStyle: UIAlertController.Style.actionSheet)
        // アクションを生成.
        let myAction_1 = UIAlertAction(title: "投稿を通報する", style: UIAlertAction.Style.default, handler: {
            (action: UIAlertAction!) in
            print("通報")
            
            let documentID = self.postdata?.id
            let documentId:String = String(documentID!)
            let caption:String = String(self.postdata!.caption!)
            
            if let myid = Auth.auth().currentUser?.uid {
                // 更新データを作成する
                var updateValue: FieldValue
                
                //すでに通報している場合
                if self.postdata!.myReportExist {
                    let alertController:UIAlertController =
                           UIAlertController(title:"投稿の通報",
                                             message: "あてはまるものをお選びください",
                                             preferredStyle: .alert)
                       
                       
                       let action1:UIAlertAction =
                           UIAlertAction(title: "不審な内容またはスパム投稿である",
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
                    
                    print("新しいmyidを加えます")
                    
                    let alertController:UIAlertController =
                        UIAlertController(title:"投稿の通報",
                                          message: "あてはまるものをお選びください",
                                          preferredStyle: .alert)
                    
                    updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                    
                    let action1:UIAlertAction =
                        UIAlertAction(title: "不審な内容またはスパム投稿である",
                                      style: .default,
                                      handler:{
                                        (action:UIAlertAction!) -> Void in
                                        // 処理
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
            
            if let myid = Auth.auth().currentUser?.uid {
                    // 更新データを作成する
                    var updateValue: FieldValue
                    print("新しいmyidを加えます")
                    updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                    postRef.updateData(["blocks": updateValue])
                    
                    //遷移してから以下のコメントを出したい
                    let banner = NotificationBanner(title: "非表示にしました", leftView: nil, rightView: nil, style: .info, colors: nil)
                    banner.autoDismiss = false
                    banner.dismissOnTap = true
                    banner.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: self.navigationController!)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                        banner.dismiss()
                        //遷移元に戻る
                        self.navigationController?.popViewController(animated: true)
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
                
                if let myid = Auth.auth().currentUser?.uid {
                    
                    // 更新データを作成する
                    var updateValue: FieldValue
                    updateValue = FieldValue.arrayUnion([self.postdata!.uid])
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
                                //遷移元に戻る
                                self.navigationController?.popViewController(animated: true)
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
                                //遷移元に戻る
                                self.navigationController?.popViewController(animated: true)
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
    
    //自分のコメントを削除するとき
    @objc func alertButton3(_ sender: UIButton, forEvent event: UIEvent){
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.chatRoomTableView)
        let indexPath = self.chatRoomTableView.indexPathForRow(at: point)
        
        // インスタンス生成　styleはActionSheet.
        let myAlert = UIAlertController(title: "あなたのコメントです", message: "このコメントを削除しますか？", preferredStyle: UIAlertController.Style.actionSheet)
        // アクションを生成.
        let myAction_1 = UIAlertAction(title: "コメントを削除する", style: UIAlertAction.Style.default, handler: {
            (action: UIAlertAction!) in
            let alert: UIAlertController = UIAlertController(title: "コメントの削除", message: "本当にこのコメントを削除してよろしいでしょうか？", preferredStyle:  UIAlertController.Style.alert)
            
            let defaultAction: UIAlertAction = UIAlertAction(title: "削除", style: UIAlertAction.Style.destructive, handler:{
                (action: UIAlertAction!) -> Void in
                
                //削除のコード
                //現在ログイン中のユーザーIDのみ取り出す
                let db = Firestore.firestore()
                db.collection("posts").document(self.postdata!.id).collection("messages").getDocuments() { (documents, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    }
                    
                    // 更新データを作成する
                    var updateValue: FieldValue
                    var updateValue2: FieldValue
                    var updateValue3: FieldValue
                    
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                    
                    // 配列からタップされたインデックスのデータを取り出す
                    let messageData = self.messages[indexPath!.row]
                    let messageRef = Firestore.firestore().collection("posts").document(self.postdata!.id).collection("messages").document(messageData.id)
                    
                    updateValue = FieldValue.arrayRemove([["uid": messageData.uid, "time": messageData.time]])
                    postRef.updateData(["comments": updateValue])
                    
                    updateValue2 = FieldValue.arrayRemove([["uid": messageData.uid, "time": messageData.time]])
                    postRef.updateData(["allComments": updateValue2])
                    
                    updateValue3 = FieldValue.arrayUnion([["uid": messageData.uid, "time": Date.timeIntervalSinceReferenceDate]])
                    messageRef.updateData(["deletes2": updateValue3])
                    
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
    
    //MOD(スレッドを作成した人)が自分以外のコメントを削除するとき
    @objc func alertButton3b(_ sender: UIButton, forEvent event: UIEvent){
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.chatRoomTableView)
        let indexPath = self.chatRoomTableView.indexPathForRow(at: point)
        
        // インスタンス生成　styleはActionSheet.
        let myAlert = UIAlertController(title: "問題のあるコメント", message: "あてはまるものをお選びください", preferredStyle: UIAlertController.Style.actionSheet)
        // アクションを生成.
        let myAction_1 = UIAlertAction(title: "コメントを通報する", style: UIAlertAction.Style.default, handler: {
        (action: UIAlertAction!) in
            
            // 更新データを作成する
                var updateValue: FieldValue
                var updateValue2: FieldValue
                var updateValue3: FieldValue
                
                let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                
                // 配列からタップされたインデックスのデータを取り出す
                let messageData = self.messages[indexPath!.row]
                let documentId = messageData.id
                let caption:String = String(messageData.message)
                let messageRef = Firestore.firestore().collection("posts").document(self.postdata!.id).collection("messages").document(messageData.id)
                
                if let myid = Auth.auth().currentUser?.uid {
                   
                    //既に自分が通報している場合
                    if messageData.myReportExist {
                        let alertController:UIAlertController =
                            UIAlertController(title:"コメントの通報",
                                              message: "あてはまるものをお選びください",
                                              preferredStyle: .alert)
                        
                        let action1:UIAlertAction =
                            UIAlertAction(title: "不審な内容またはスパム投稿である",
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
                        
                        //通報が既に19回されていて自分が初めて通報する場合(あと一回の通報で投稿非表示)
                        if messageData.reports2.count >= 19 {
                            print("この通報で削除になります。")
                            
                            updateValue = FieldValue.arrayRemove([["uid": messageData.uid, "time": messageData.time]])
                            updateValue2 = FieldValue.arrayRemove([["uid": messageData.uid, "time": messageData.time]])
                            updateValue3 = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                            
                            let alertController:UIAlertController =
                                UIAlertController(title:"コメントの通報",
                                                  message: "あてはまるものをお選びください",
                                                  preferredStyle: .alert)
                            
                            let action1:UIAlertAction =
                                UIAlertAction(title: "不審な内容またはスパム投稿である",
                                              style: .default,
                                              handler:{
                                                (action:UIAlertAction!) -> Void in
                                                // 処理
                                                postRef.updateData(["comments": updateValue])
                                                postRef.updateData(["allComments": updateValue2])
                                                messageRef.updateData(["deletes2": updateValue3])
                                                
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
                                                postRef.updateData(["comments": updateValue])
                                                postRef.updateData(["allComments": updateValue2])
                                                messageRef.updateData(["deletes2": updateValue3])
                                                
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
                                                postRef.updateData(["comments": updateValue])
                                                postRef.updateData(["allComments": updateValue2])
                                                messageRef.updateData(["deletes2": updateValue3])
                                                
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
                                                postRef.updateData(["comments": updateValue])
                                                postRef.updateData(["allComments": updateValue2])
                                                messageRef.updateData(["deletes2": updateValue3])
                                                
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
                            
                            
                        }else {
                            print("通報が加わります")
                            print("新しいmyidを加えます")
                            var updateValue: FieldValue
                            updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                            
                            
                            let alertController:UIAlertController =
                                UIAlertController(title:"コメントの通報",
                                                  message: "あてはまるものをお選びください",
                                                  preferredStyle: .alert)
                            
                            let action1:UIAlertAction =
                                UIAlertAction(title: "不審な内容またはスパム投稿である",
                                              style: .default,
                                              handler:{
                                                (action:UIAlertAction!) -> Void in
                                                // 処理
                                                messageRef.updateData(["reports2": updateValue])
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
                                                messageRef.updateData(["reports2": updateValue])
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
                                                messageRef.updateData(["reports2": updateValue])
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
                                                messageRef.updateData(["reports2": updateValue])
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
            }
        })
        
        let myAction_2 = UIAlertAction(title: "コメントを削除する", style: UIAlertAction.Style.default, handler: {
            (action: UIAlertAction!) in
            let alert: UIAlertController = UIAlertController(title: "コメントの削除", message: "本当にコメントを削除してよろしいでしょうか？", preferredStyle:  UIAlertController.Style.alert)
            
            let defaultAction: UIAlertAction = UIAlertAction(title: "削除", style: UIAlertAction.Style.destructive, handler:{
                (action: UIAlertAction!) -> Void in
                //削除のコード
                
                let db = Firestore.firestore()
                db.collection("posts").document(self.postdata!.id).collection("messages").getDocuments() { (documents, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    }
                    
                    // 更新データを作成する
                    var updateValue: FieldValue
                    var updateValue2: FieldValue
                    
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
                    
                    // 配列からタップされたインデックスのデータを取り出す
                    let messageData = self.messages[indexPath!.row]
                    let messageRef = Firestore.firestore().collection("posts").document(self.postdata!.id).collection("messages").document(messageData.id)
                    
                    updateValue = FieldValue.arrayRemove([["uid": messageData.uid, "time": messageData.time]])
                    postRef.updateData(["allComments": updateValue])
                    
                    updateValue2 = FieldValue.arrayUnion([["uid": messageData.uid, "time": Date.timeIntervalSinceReferenceDate]])
                    messageRef.updateData(["deletes2": updateValue2])
                    
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
        
        let myAction_3 = UIAlertAction(title: "ユーザーをブロックする", style: UIAlertAction.Style.default, handler: {
                (action: UIAlertAction!) in
                
                let alert: UIAlertController = UIAlertController(title: "ユーザーのブロック", message: "このユーザーの投稿は今後表示されなくなりますがよろしいでしょうか？", preferredStyle:  UIAlertController.Style.alert)
                
                let defaultAction: UIAlertAction = UIAlertAction(title: "ブロック", style: UIAlertAction.Style.destructive, handler:{
                    (action: UIAlertAction!) -> Void in
                    
                    print("ブロック")
                    // 配列からタップされたインデックスのデータを取り出す
                    let messageData = self.messages[indexPath!.row]
                    if let myid = Auth.auth().currentUser?.uid {
                        
                        // 更新データを作成する
                        var updateValue: FieldValue
                        updateValue = FieldValue.arrayUnion([messageData.uid])
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
    
    //コメントの通報 2回以上通報がたまるとそのコメントを非表示
    @objc func alertButton4(_ sender: UIButton, forEvent event: UIEvent){
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.chatRoomTableView)
        let indexPath = self.chatRoomTableView.indexPathForRow(at: point)
        
        print("alert")
        // インスタンス生成　styleはActionSheet.
        let myAlert = UIAlertController(title: "問題のあるコメント", message: "あてはまるものをお選びください", preferredStyle: UIAlertController.Style.actionSheet)
        // アクションを生成.
        let myAction_1 = UIAlertAction(title: "コメントを通報する", style: UIAlertAction.Style.default, handler: {
            (action: UIAlertAction!) in
            print("YES")
            
            // 更新データを作成する
            var updateValue: FieldValue
            var updateValue2: FieldValue
            var updateValue3: FieldValue
            
            let postRef = Firestore.firestore().collection("posts").document(self.postdata!.id)
            
            // 配列からタップされたインデックスのデータを取り出す
            let messageData = self.messages[indexPath!.row]
            let documentId = messageData.id
            let caption:String = String(messageData.message)
            let messageRef = Firestore.firestore().collection("posts").document(self.postdata!.id).collection("messages").document(messageData.id)
            
            if let myid = Auth.auth().currentUser?.uid {
                
                //既に自分が通報している場合
                if messageData.myReportExist {
                    let alertController:UIAlertController =
                        UIAlertController(title:"コメントの通報",
                                          message: "あてはまるものをお選びください",
                                          preferredStyle: .alert)
                    
                    let action1:UIAlertAction =
                        UIAlertAction(title: "不審な内容またはスパム投稿である",
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
                }  else{
                    
                    //通報が既に19回されていて自分が初めて通報する場合(あと一回の通報で投稿非表示)
                    if messageData.reports2.count >= 19 {
                        print("この通報で削除になります。")
                        
                        updateValue = FieldValue.arrayRemove([["uid": messageData.uid, "time": messageData.time]])
                        updateValue2 = FieldValue.arrayRemove([["uid": messageData.uid, "time": messageData.time]])
                        updateValue3 = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                        
                        let alertController:UIAlertController =
                            UIAlertController(title:"コメントの通報",
                                              message: "あてはまるものをお選びください",
                                              preferredStyle: .alert)
                        
                        let action1:UIAlertAction =
                            UIAlertAction(title: "不審な内容またはスパム投稿である",
                                          style: .default,
                                          handler:{
                                            (action:UIAlertAction!) -> Void in
                                            // 処理
                                            postRef.updateData(["comments": updateValue])
                                            postRef.updateData(["allComments": updateValue2])
                                            messageRef.updateData(["deletes2": updateValue3])
                                            
                                                //メーラーを起動する
                                                guard MFMailComposeViewController.canSendMail() else {
                                                    return
                                                }
                                                
                                                let composer = MFMailComposeViewController()
                                                composer.mailComposeDelegate = self
                                                composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                                composer.setSubject("問題の詳細を報告") // 件名
                                                composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false)
                                                self.present(composer,animated: true)
                            })
                        
                        let action2:UIAlertAction =
                            UIAlertAction(title: "誹謗中傷をしている",
                                          style: .default,
                                          handler:{
                                            (action:UIAlertAction!) -> Void in
                                            // 処理
                                            postRef.updateData(["comments": updateValue])
                                            postRef.updateData(["allComments": updateValue2])
                                            messageRef.updateData(["deletes2": updateValue3])
                                            
                                                //メーラーを起動する
                                                guard MFMailComposeViewController.canSendMail() else {
                                                    return
                                                }
                                                
                                                let composer = MFMailComposeViewController()
                                                composer.mailComposeDelegate = self
                                                composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                                composer.setSubject("問題の詳細を報告") // 件名
                                                composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false)
                                                self.present(composer,animated: true)
                            })
                        
                        let action3:UIAlertAction =
                            UIAlertAction(title: "不適切な内容を含んでいる",
                                          style: .default,
                                          handler:{
                                            (action:UIAlertAction!) -> Void in
                                            // 処理
                                            postRef.updateData(["comments": updateValue])
                                            postRef.updateData(["allComments": updateValue2])
                                            messageRef.updateData(["deletes2": updateValue3])
                                            
                                                //メーラーを起動する
                                                guard MFMailComposeViewController.canSendMail() else {
                                                    return
                                                }
                                                
                                                let composer = MFMailComposeViewController()
                                                composer.mailComposeDelegate = self
                                                composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                                composer.setSubject("問題の詳細を報告") // 件名
                                                composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false)
                                                self.present(composer,animated: true)
                            })
                        
                        let action4:UIAlertAction =
                            UIAlertAction(title: "自殺の意思をほのめかしている",
                                          style: .default,
                                          handler:{
                                            (action:UIAlertAction!) -> Void in
                                            // 処理
                                            postRef.updateData(["comments": updateValue])
                                            postRef.updateData(["allComments": updateValue2])
                                            messageRef.updateData(["deletes2": updateValue3])
                                            
                                                let composer = MFMailComposeViewController()
                                                composer.mailComposeDelegate = self
                                                composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                                composer.setSubject("問題の詳細を報告") // 件名
                                                composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false)
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
                        
                        
                    }else {
                        print("通報が加わります")
                        print("新しいmyidを加えます")
                        var updateValue: FieldValue
                        updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                        
                        
                        let alertController:UIAlertController =
                            UIAlertController(title:"コメントの通報",
                                              message: "あてはまるものをお選びください",
                                              preferredStyle: .alert)
                        
                        
                        let action1:UIAlertAction =
                            UIAlertAction(title: "不審な内容またはスパム投稿である",
                                          style: .default,
                                          handler:{
                                            (action:UIAlertAction!) -> Void in
                                            // 処理
                                            messageRef.updateData(["reports2": updateValue])
                                                //メーラーを起動する
                                                guard MFMailComposeViewController.canSendMail() else {
                                                    return
                                                }
                                                
                                                let composer = MFMailComposeViewController()
                                                composer.mailComposeDelegate = self
                                                composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                                composer.setSubject("問題の詳細を報告") // 件名
                                                composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false)
                                                self.present(composer,animated: true)
                            })
                        
                        let action2:UIAlertAction =
                            UIAlertAction(title: "誹謗中傷をしている",
                                          style: .default,
                                          handler:{
                                            (action:UIAlertAction!) -> Void in
                                            // 処理
                                            messageRef.updateData(["reports2": updateValue])
                                                //メーラーを起動する
                                                guard MFMailComposeViewController.canSendMail() else {
                                                    return
                                                }
                                                
                                                let composer = MFMailComposeViewController()
                                                composer.mailComposeDelegate = self
                                                composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                                composer.setSubject("問題の詳細を報告") // 件名
                                                composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false)
                                                self.present(composer,animated: true)
                            })
                        
                        let action3:UIAlertAction =
                            UIAlertAction(title: "不適切な内容を含んでいる",
                                          style: .default,
                                          handler:{
                                            (action:UIAlertAction!) -> Void in
                                            // 処理
                                            messageRef.updateData(["reports2": updateValue])
                                                //メーラーを起動する
                                                guard MFMailComposeViewController.canSendMail() else {
                                                    return
                                                }
                                                
                                                let composer = MFMailComposeViewController()
                                                composer.mailComposeDelegate = self
                                                composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                                composer.setSubject("問題の詳細を報告") // 件名
                                                composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false)
                                                self.present(composer,animated: true)
                            })
                        
                        let action4:UIAlertAction =
                            UIAlertAction(title: "自殺の意思をほのめかしている",
                                          style: .default,
                                          handler:{
                                            (action:UIAlertAction!) -> Void in
                                            // 処理
                                            messageRef.updateData(["reports2": updateValue])
                                                //メーラーを起動する
                                                guard MFMailComposeViewController.canSendMail() else {
                                                    return
                                                }
                                                
                                                let composer = MFMailComposeViewController()
                                                composer.mailComposeDelegate = self
                                                composer.setToRecipients(["support@nomad.fan"]) // 宛先アドレス
                                                composer.setSubject("問題の詳細を報告") // 件名
                                                composer.setMessageBody("【報告する投稿】\nドキュメントID:\n \(documentId)\n内容:\n\(caption)\n\n以下、詳細等ご入力ください。\n\n", isHTML: false)
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
            }
            
        })
        
        let myAction_2 = UIAlertAction(title: "コメントを非表示にする", style: UIAlertAction.Style.default, handler: {
        (action: UIAlertAction!) in
        
        let alert: UIAlertController = UIAlertController(title: "コメントの非表示", message: "本当にこのコメントを非表示にしてよろしいでしょうか？", preferredStyle:  UIAlertController.Style.alert)
        
        let defaultAction: UIAlertAction = UIAlertAction(title: "非表示", style: UIAlertAction.Style.destructive, handler:{
            (action: UIAlertAction!) -> Void in
            
            print("非表示")
            
            if let myid = Auth.auth().currentUser?.uid {
                // 更新データを作成する
                var updateValue: FieldValue
                print("新しいmyidを加えます")
                updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                
                let messageData = self.messages[indexPath!.row]
                let messageRef = Firestore.firestore().collection("posts").document(self.postdata!.id).collection("messages").document(messageData.id)
                messageRef.updateData(["blocks2": updateValue])
                
                //遷移してから以下のコメントを出したい
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
                    let messageData = self.messages[indexPath!.row]
                    if let myid = Auth.auth().currentUser?.uid {
                        
                        // 更新データを作成する
                        var updateValue: FieldValue
                        updateValue = FieldValue.arrayUnion([messageData.uid])
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
}

extension ChatRoomViewController: MFMailComposeViewControllerDelegate {
    
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
}

