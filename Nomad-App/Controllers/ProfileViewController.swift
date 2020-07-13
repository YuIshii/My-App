//
//  ProfileViewController.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import NotificationBannerSwift

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var postNumber: UILabel!
    @IBOutlet weak var likeNumber: UILabel!
    @IBOutlet weak var joinNumber: UILabel!
    @IBOutlet weak var profileImageButton: UIButton!{
        didSet {
            profileImageButton.imageView?.contentMode = .scaleAspectFill
            profileImageButton.imageView?.layer.cornerRadius = 35.0
            profileImageButton.imageView?.layer.borderWidth = 0.5
            profileImageButton.imageView?.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
    @IBOutlet weak var editButton: UIButton!
    
    private var refreshControl = UIRefreshControl()
    
    // 投稿データを格納する配列
    var postArray: [PostData] = []
    var postArray2: [PostData] = []
    var postArray3: [PostData] = []
    
    // ブロックユーザーデータを格納する配列
    var blockUserArray: [String] = []
    
    private var postdata: PostData?
    private var postdata2: PostData?
    private var postdata3: PostData?
    
    var state = State.first
    
    enum State: Int {
        case first
        case second
        case third
    }
    
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
        let nib1 = UINib(nibName: "Post5TableViewCell", bundle: nil)
        tableView.register(nib1, forCellReuseIdentifier: "Cell5")
        let nib2 = UINib(nibName: "Post6TableViewCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: "Cell6")
        let nib3 = UINib(nibName: "MyPostsTableViewCell", bundle: nil)
        tableView.register(nib3, forCellReuseIdentifier: "MyPosts")
        let nib4 = UINib(nibName: "LikeTableViewCell", bundle: nil)
        tableView.register(nib4, forCellReuseIdentifier: "Like")
        let nib5 = UINib(nibName: "JoinTableViewCell", bundle: nil)
        tableView.register(nib5, forCellReuseIdentifier: "Join")
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(self.refresh(sender:)), for: .valueChanged)
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.tabBarController?.tabBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.tintColor = UIColor.black
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        
        self.editButton.layer.borderColor = UIColor.link.cgColor
        self.editButton.layer.borderWidth = 0.8
        editButton.layer.cornerRadius = 10.0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toSearch") {
            print("検索に遷移")
            let backBarButtonItem = UIBarButtonItem()
            self.navigationItem.backBarButtonItem = backBarButtonItem
        }else{
            print("プロフィール編集に遷移")
        }
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        
        let postsRef = Firestore.firestore().collection("posts").order(by: "date", descending: true)
        listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
            if let error = error {
                print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                return
            }
            
            self.blockCheck1()
            
            //自分の投稿のみ
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
            
            self.blockCheck2()
            
            self.postArray2 = querySnapshot!.documents.flatMap { document in
                print("DEBUG_PRINT: document取得 \(document.documentID)")
                let data = document.data()
                if (data == nil) {
                    return nil
                }
                let postData = PostData(document: document)
                postData.id = document.documentID
                //いいねされた投稿のみを表示し、他はnilを返す
                if postData.isLiked && postData.isReported == false{
                    return postData
                }
                return nil
            }
            self.postArray2.sort {
                $0.likedTime > $1.likedTime
            }
            
            self.blockCheck3()
            
            //参加中の投稿のみ
            self.postArray3 = querySnapshot!.documents.flatMap { document in
                print("DEBUG_PRINT: document取得 \(document.documentID)")
                let data = document.data()
                if (data == nil) {
                    return nil
                }
                let postData = PostData(document: document)
                postData.id = document.documentID
                if postData.isCommented == true && postData.isReported == false{
                    return postData
                }
                return nil
            }
            self.postArray3.sort {
                $0.joinedTime > $1.joinedTime
            }
            let postCount = self.postArray.count
            self.postNumber.text = "\(postCount)"
            print("\(postCount)")
            let likeCount = self.postArray2.count
            self.likeNumber.text = "\(likeCount)"
            print("\(likeCount)")
            let joinCount = self.postArray3.count
            self.joinNumber.text = "\(joinCount)"
            print("\(joinCount)")
            self.tableView.reloadData()
            sender.endRefreshing()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")
        
        let backBarButtonItem = UIBarButtonItem()
        backBarButtonItem.title = "Back"
        self.navigationItem.backBarButtonItem = backBarButtonItem
        self.tabBarController?.tabBar.isHidden = false
        
        //もしプロフィール画像を設定していなかったら"placeholderImg"を表示し、プロフィール画像を設定している場合はその画像を表示する。
        if Auth.auth().currentUser?.photoURL != nil{
            profileImageButton.sd_imageIndicator = SDWebImageActivityIndicator.gray
            let photoURL = Auth.auth().currentUser?.photoURL
            self.profileImageButton.sd_setImage(with: photoURL, for: .normal)
        }else {
            self.profileImageButton.setImage(UIImage(named: "placeholderImg"), for: .normal)
        }
        
        let userName = Auth.auth().currentUser?.displayName
        nameLabel.text = userName
        
        if Auth.auth().currentUser != nil {
            // ログイン済み
            if listener == nil {
                // listener未登録なら、登録してスナップショットを受信する
                //自分がいいねしたやつを投稿順に表示させる
                let postsRef = Firestore.firestore().collection("posts").order(by: "date", descending: true)
                listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
                    if let error = error {
                        print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                        return
                    }
                    
                    self.blockCheck1()
                    
                    //自分の投稿のみ
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
                    
                    self.blockCheck2()
                    
                    self.postArray2 = querySnapshot!.documents.flatMap { document in
                        print("DEBUG_PRINT: document取得 \(document.documentID)")
                        let data = document.data()
                        if (data == nil) {
                            return nil
                        }
                        let postData = PostData(document: document)
                        postData.id = document.documentID
                        //いいねされた投稿のみを表示し、他はnilを返す
                        if postData.isLiked && postData.isReported == false{
                            return postData
                        }
                        return nil
                    }
                    self.postArray2.sort {
                        $0.likedTime > $1.likedTime
                    }
                    
                    self.blockCheck2()
                    
                    //参加中の投稿のみ
                    self.postArray3 = querySnapshot!.documents.flatMap { document in
                        print("DEBUG_PRINT: document取得 \(document.documentID)")
                        let data = document.data()
                        if (data == nil) {
                            return nil
                        }
                        let postData = PostData(document: document)
                        postData.id = document.documentID
                        if postData.isCommented == true && postData.isReported == false{
                            return postData
                        }
                        return nil
                    }
                    self.postArray3.sort {
                        $0.joinedTime > $1.joinedTime
                    }
                    
                    let postCount = self.postArray.count
                    self.postNumber.text = "\(postCount)"
                    print("\(postCount)")
                    let likeCount = self.postArray2.count
                    self.likeNumber.text = "\(likeCount)"
                    print("\(likeCount)")
                    let joinCount = self.postArray3.count
                    self.joinNumber.text = "\(joinCount)"
                    print("\(joinCount)")
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
                postArray2 = []
                postArray3 = []
                tableView.reloadData()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if listener != nil {
            // listener登録済みなら削除してpostArrayをクリアする
            listener.remove()
            listener = nil
            postArray = []
            postArray2 = []
            postArray3 = []
            tableView.reloadData()
        }
    }
    
    func blockCheck1() {
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
                            self.postArray2 = self.postArray2.filter {
                                if blockUsers.contains($0.uid) {
                                    return false
                                } else {
                                    return true
                                }
                            }
                            self.postArray3 = self.postArray3.filter {
                                if blockUsers.contains($0.uid) {
                                    return false
                                } else {
                                    return true
                                }
                            }
                            let postCount = self.postArray.count
                            self.postNumber.text = "\(postCount)"
                            print("\(postCount)")
                            let likeCount = self.postArray2.count
                            self.likeNumber.text = "\(likeCount)"
                            print("\(likeCount)")
                            let joinCount = self.postArray3.count
                            self.joinNumber.text = "\(joinCount)"
                            print("\(joinCount)")
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
    
    func blockCheck2() {
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
                            
                            self.postArray2 = self.postArray2.filter {
                                if blockUsers.contains($0.uid) {
                                    return false
                                } else {
                                    return true
                                }
                            }
                            let postCount = self.postArray.count
                            self.postNumber.text = "\(postCount)"
                            print("\(postCount)")
                            let likeCount = self.postArray2.count
                            self.likeNumber.text = "\(likeCount)"
                            print("\(likeCount)")
                            let joinCount = self.postArray3.count
                            self.joinNumber.text = "\(joinCount)"
                            print("\(joinCount)")
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
    
    func blockCheck3() {
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
                            
                            self.postArray3 = self.postArray3.filter {
                                if blockUsers.contains($0.uid) {
                                    return false
                                } else {
                                    return true
                                }
                            }
                            let postCount = self.postArray.count
                            self.postNumber.text = "\(postCount)"
                            print("\(postCount)")
                            let likeCount = self.postArray2.count
                            self.likeNumber.text = "\(likeCount)"
                            print("\(likeCount)")
                            let joinCount = self.postArray3.count
                            self.joinNumber.text = "\(joinCount)"
                            print("\(joinCount)")
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
    
    @IBAction func segementAction(_ sender: UISegmentedControl) {
        state = State(rawValue: sender.selectedSegmentIndex) ?? .first
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch state {
        case .first:
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
        case .second:
            let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
            let chatRoomViewController = storyboard.instantiateViewController(identifier: "ChatRoomViewController") as! ChatRoomViewController
            postdata2 = self.postArray2[indexPath.row]
            //postdataをChatRoomViewControllerに渡す
            chatRoomViewController.postdata = postdata2
            
            // viewerを更新する
            if let myid = Auth.auth().currentUser?.uid {
                // 更新データを作成する
                var updateValue: FieldValue
                var updateValue2: FieldValue
                
                if postdata2!.viewed {
                    print("古いmyidを消して新しいmyidを加えます")
                    //再度新しい日付でmyidを加えるために一度古い日付で登録したmyidを消す
                    updateValue = FieldValue.arrayRemove([["uid": myid, "time": postdata2!.viewedTime]])
                    updateValue2 = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata2!.id)
                    postRef.updateData(["viewer": updateValue])
                    postRef.updateData(["viewer": updateValue2])
                } else{
                    print("新しいmyidを加えます")
                    updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata2!.id)
                    postRef.updateData(["viewer": updateValue])
                }
            }
            
            navigationController?.pushViewController(chatRoomViewController, animated: true)
            //選択状態の解除
            tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        case .third:
            let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
            let chatRoomViewController = storyboard.instantiateViewController(identifier: "ChatRoomViewController") as! ChatRoomViewController
            postdata3 = self.postArray3[indexPath.row]
            //postdataをChatRoomViewControllerに渡す
            chatRoomViewController.postdata = postdata3
            
            // viewerを更新する
            if let myid = Auth.auth().currentUser?.uid {
                // 更新データを作成する
                var updateValue: FieldValue
                var updateValue2: FieldValue
                
                if postdata3!.viewed {
                    print("古いmyidを消して新しいmyidを加えます")
                    //再度新しい日付でmyidを加えるために一度古い日付で登録したmyidを消す
                    updateValue = FieldValue.arrayRemove([["uid": myid, "time": postdata3!.viewedTime]])
                    updateValue2 = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata3!.id)
                    postRef.updateData(["viewer": updateValue])
                    postRef.updateData(["viewer": updateValue2])
                } else{
                    print("新しいmyidを加えます")
                    updateValue = FieldValue.arrayUnion([["uid": myid, "time": Date.timeIntervalSinceReferenceDate]])
                    let postRef = Firestore.firestore().collection("posts").document(self.postdata3!.id)
                    postRef.updateData(["viewer": updateValue])
                }
            }
            
            navigationController?.pushViewController(chatRoomViewController, animated: true)
            //選択状態の解除
            tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state {
        case .first:
            if self.postArray.count == 0 {
                return 1
            }else{
                return self.postArray.count
            }
        case .second:
            if self.postArray2.count == 0 {
                return 1
            }else{
                return self.postArray2.count
            }
        case .third:
            if self.postArray3.count == 0 {
                return 1
            }else{
                return self.postArray3.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch state {
        case .first:
            if self.postArray.count == 0 {
                return 200
            }else{
                return 100
            }
        case .second:
            if self.postArray2.count == 0 {
                return 200
            }else{
                return 100
            }
        case .third:
            if self.postArray3.count == 0 {
                return 200
            }else{
                return 100
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch state {
        case .first:
            
            //自分の投稿が0だった場合
            if self.postArray.count == 0 {
                tableView.separatorStyle = .none
                print("MyPostsTableViewCellを表示")
                let cell = tableView.dequeueReusableCell(withIdentifier: "MyPosts", for: indexPath) as! MyPostsTableViewCell
                return cell
            }else{
                tableView.separatorStyle = .singleLine
                // with_imageがtrueの場合 Post2TableViewCell
                if self.postArray[indexPath.row].with_image == true {
                    print("Create Post2TableViewCell")
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell6", for: indexPath) as! Post6TableViewCell
                    postdata = self.postArray[indexPath.row]
                    cell.postdata = postdata
                    cell.setPostData(postArray[indexPath.row])
                    //セル押下時のハイライト(色が濃くなる)を無効
                    cell.selectionStyle = .none
                    return cell
                }
                    // with_imageがfalseの場合 Post1TableViewCell
                else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell5", for: indexPath) as! Post5TableViewCell
                    //Post1TableViewCellのpostdataにpostArray[indexPath.row]を渡す
                    postdata = self.postArray[indexPath.row]
                    //Post1TableViewCellのpostdataにpostArray[indexPath.row]を渡す
                    cell.postdata = postdata
                    cell.setPostData(self.postArray[indexPath.row])
                    //セル押下時のハイライト(色が濃くなる)を無効
                    cell.selectionStyle = .none
                    return cell
                }
            }
        case .second:
            
            if self.postArray2.count == 0 {
                tableView.separatorStyle = .none
                print("LikeTableViewCellを表示")
                let cell = tableView.dequeueReusableCell(withIdentifier: "Like", for: indexPath) as! LikeTableViewCell
                return cell
            }else{
                tableView.separatorStyle = .singleLine
                // with_imageがtrueの場合 Post2TableViewCell
                if self.postArray2[indexPath.row].with_image == true {
                    print("Create Post2TableViewCell")
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell6", for: indexPath) as! Post6TableViewCell
                    postdata2 = self.postArray2[indexPath.row]
                    cell.postdata = postdata2
                    cell.setPostData(postArray2[indexPath.row])
                    //セル押下時のハイライト(色が濃くなる)を無効
                    cell.selectionStyle = .none
                    return cell
                }
                    // with_imageがfalseの場合 Post1TableViewCell
                else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell5", for: indexPath) as! Post5TableViewCell
                    //Post1TableViewCellのpostdataにpostArray[indexPath.row]を渡す
                    postdata2 = self.postArray2[indexPath.row]
                    //Post1TableViewCellのpostdataにpostArray[indexPath.row]を渡す
                    cell.postdata = postdata2
                    cell.setPostData(self.postArray2[indexPath.row])
                    //セル押下時のハイライト(色が濃くなる)を無効
                    cell.selectionStyle = .none
                    return cell
                }
            }
        case .third:
            
            if self.postArray3.count == 0 {
                tableView.separatorStyle = .none
                print("JoinTableViewCellを表示")
                let cell = tableView.dequeueReusableCell(withIdentifier: "Join", for: indexPath) as! JoinTableViewCell
                return cell
            }else{
                tableView.separatorStyle = .singleLine
                    // with_imageがtrueの場合 Post2TableViewCell
                    if self.postArray3[indexPath.row].with_image == true {
                        print("Create Post2TableViewCell")
                        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell6", for: indexPath) as! Post6TableViewCell
                        postdata3 = self.postArray3[indexPath.row]
                        cell.postdata = postdata3
                        cell.setPostData(postArray3[indexPath.row])
                        //セル押下時のハイライト(色が濃くなる)を無効
                        cell.selectionStyle = .none
                        return cell
                    }
                        // with_imageがfalseの場合 Post1TableViewCell
                    else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell5", for: indexPath) as! Post5TableViewCell
                        //Post1TableViewCellのpostdataにpostArray[indexPath.row]を渡す
                        postdata3 = self.postArray3[indexPath.row]
                        //Post1TableViewCellのpostdataにpostArray[indexPath.row]を渡す
                        cell.postdata = postdata3
                        cell.setPostData(self.postArray3[indexPath.row])
                        return cell
                    }
                }
            }
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        // 他の画面から segue を使って戻ってきた時に呼ばれる
    }
}

extension UIImageView {
    
    func circle() {
        layer.masksToBounds = false
        layer.cornerRadius = frame.width/2
        clipsToBounds = true
    }
}
