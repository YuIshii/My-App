//
//  PostViewControlle.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

class PostViewController: UIViewController, UITextViewDelegate,UITextFieldDelegate{
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textView: PlaceHolderTextView!
    @IBOutlet weak var postButton: UIBarButtonItem!
    @IBOutlet weak var photo: UIImageView!
    
    var pickerView: UIPickerView = UIPickerView()
    var selectedImage: UIImage!
    
    let list: [String] = ["選択してください","ニュース","話題・おもしろ","TV・エンタメ","音楽","スポーツ","政治・経済","金融・ビジネス","IT・科学","健康・医療","美容・ファッション","仕事","学校","漫画・アニメ","ゲーム","暮らし・家族","結婚・恋愛","グルメ・レシピ","資格・勉強","趣味","質問・相談","不思議・謎","都道府県","海外","雑談・ネタ"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ナビゲーションバーの色
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        
        postButton.isEnabled = false
        
        // テキストフィールド、テキストビューのデリゲートの通知先を自身(このViewController)に設定
        textField.delegate = self
        
        textView.delegate = self
        
        // ピッカー設定
        pickerView.delegate = self as! UIPickerViewDelegate
        pickerView.dataSource = self as! UIPickerViewDataSource
        pickerView.showsSelectionIndicator = true
        
        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spacelItem, doneItem], animated: true)
        
        // インプットビュー設定
        textField.inputView = pickerView
        textField.inputAccessoryView = toolbar
        
        //テキストフィールドのカーソルを消す
        textField.tintColor = UIColor.clear
        
        textView.placeHolder = "タイトルを入力してください"
        textView.placeHolderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        
        textField.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        textField.layer.borderWidth = 1.3
        textField.layer.cornerRadius = 5
        textView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        textView.layer.borderWidth = 1.3
        textView.layer.cornerRadius = 5
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.selectImageView))
        photo.addGestureRecognizer(tapGesture)
        photo.isUserInteractionEnabled = true
        
        self.photo.image = UIImage(named: "photo-placeholder")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.selectedImage != nil{
            self.photo.image = selectedImage
        }else{
            print("画像は選択されていません")
        }
    }
    
    @objc func selectImageView(){
        // ライブラリ（カメラロール）を指定してピッカーを開く
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = .photoLibrary
            self.present(pickerController, animated: true, completion: nil)
        }
    }
    
    // 決定ボタン押下
    @objc func done() {
        textField.endEditing(true)
        //ピッカーで選択した値を取り出して、それをテキストフィールドに反映させる。
        let selectedList = list[pickerView.selectedRow(inComponent: 0)]
        
        if selectedList == "選択してください"{
            textField.text = ""
        }else{
            textField.text = "\(selectedList)"
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを閉じる
        view.endEditing(true)
    }
}

extension PostViewController : UIPickerViewDelegate, UIPickerViewDataSource {
    
    // ドラムロールの列数
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // ドラムロールの行数
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return list.count
    }
    
    // ドラムロールの各タイトル
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return list[row]
    }
    
    
    // ドラムロール選択時
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if list[row] == "選択してください"{
            
            self.textField.text = ""
            
        }else{
            self.textField.text = list[row]
        }
    }
    
    //テキストビューを入力し終わったときのボタンの有効化/無効化
    func textViewDidChange(_ textView: UITextView) {
        
        //不要な改行削除
        let msg = self.textView.text!.replace("\n", "")
        //テキストの半角空白文字削除
        let trimmedString = msg.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedString.count > 500{
            textView.textColor = .red
        } else {
            textView.textColor = .black
        }
        
        if textField.text != "" && trimmedString != "" && trimmedString.count <= 500 {
            postButton.isEnabled = true
            print("有効化1")
        }else{
            postButton.isEnabled = false
            print("無効化1")
        }
    }
    
    //テキストフィールドを入力し終わった後のボタンの有効化/無効化
    func textFieldDidEndEditing(_ textField:UITextField){
        
        //不要な改行削除
        let msg = self.textView.text!.replace("\n", "")
        //テキストの半角空白文字削除
        let trimmedString = msg.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedString.count > 500{
            textView.textColor = .red
        } else {
            textView.textColor = .black
        }
        
        if textField.text != "" && trimmedString != "" && trimmedString.count <= 500 {
            postButton.isEnabled = true
            print("有効化2")
        }else{
            postButton.isEnabled = false
            print("無効化2")
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let existingLines = textView.text.components(separatedBy: .newlines)//既に存在する改行数
        let newLines = text.components(separatedBy: .newlines)//新規改行数
        let linesAfterChange = existingLines.count + newLines.count - 1 //最終改行数。-1は編集したら必ず1改行としてカウントされるため。
        return linesAfterChange <= 25 //25行までの入力制限
    }
    
    // 投稿ボタンをタップしたときに呼ばれるメソッド
    @IBAction func postButton(_ sender: Any) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        //不要な改行削除
        let msg = self.textView.text!.replace("\n", "")
        //テキストの半角空白文字削除
        let trimmedString = msg.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedString.count > 500{
            print("DEBUG_PRINT: タイトルが501文字以上です")
            HUD.flash(.labeledError(title: "エラー", subtitle: "タイトルは500文字以下にしてください"), delay: 1.4)
            return
        }else if trimmedString.count == 0{
            print("DEBUG_PRINT: タイトルが空白です")
            HUD.flash(.labeledError(title: "エラー", subtitle: "タイトルが空白です"), delay: 1.4)
            return
        }
        
        let trimmedString2 = self.textView.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 画像と投稿データの保存場所を定義する
        let postRef = Firestore.firestore().collection("posts").document()
        
        // HUDで投稿処理中の表示を開始
        HUD.show(.progress, onView: view)
        
        // FireStoreに投稿データを保存する
        let name = Auth.auth().currentUser?.displayName
        let email = Auth.auth().currentUser?.email
        
        if self.photo.image == UIImage(named: "photo-placeholder") {
            print("画像なしの投稿")
            let postDic = [
                "name": name!,
                "email": email!,
                "uid": uid,
                "community": self.textField.text!,
                "caption": trimmedString2,
                "date": FieldValue.serverTimestamp(),
                "with_image" : false,
                ] as [String : Any]
            postRef.setData(postDic)
            
            HUD.flash(.labeledSuccess(title: "投稿完了", subtitle: nil), delay: 1.4)
            // 投稿処理が完了したので0番目のタブに変える
            // 投稿処理が完了したので先頭画面に戻る
            UIApplication.shared.windows.first{ $0.isKeyWindow }?.rootViewController?.dismiss(animated: true, completion: {
                NotificationCenter.default.post(
                    name: .toFirstTab,
                    object: nil,
                    userInfo: ["index": self.pickerView.selectedRow(inComponent: 0) - 1]
                )
                print("ホームに移動")
            })
        } else{
            print("画像ありの投稿")
            // 画像をJPEG形式に変換し、compressionQualityで0.9に圧縮する(1.0が圧縮していない状態)
            if selectedImage != nil{
                let imageData = selectedImage.jpegData(compressionQuality: 0.9)
                let imageRef = Storage.storage().reference().child("images").child(postRef.documentID + ".jpg")
                // Storageに画像をアップロードする
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                imageRef.putData(imageData!, metadata: metadata) { (metadata, error) in
                    if error != nil {
                        // 画像のアップロード失敗
                        print(error!)
                        HUD.flash(.labeledError(title: "エラー", subtitle: "再度お試しください"), delay: 1.4)
                        // 投稿処理をキャンセルし、先頭画面に戻る
                        UIApplication.shared.windows.first{ $0.isKeyWindow }?.rootViewController?.dismiss(animated: true, completion: nil)
                        return
                    }
                    let postDic = [
                        "name": name!,
                        "uid": uid,
                        "community": self.textField.text!,
                        "caption": trimmedString2,
                        "date": FieldValue.serverTimestamp(),
                        "with_image" : true,
                        ] as [String : Any]
                    postRef.setData(postDic)
                    
                    HUD.flash(.labeledSuccess(title: "投稿完了", subtitle: nil), delay: 1.4)
                    
                    // 投稿処理が完了したので0番目のタブに変える
                    // 投稿処理が完了したので先頭画面に戻る
                    UIApplication.shared.windows.first{ $0.isKeyWindow }?.rootViewController?.dismiss(animated: true, completion: {
                        NotificationCenter.default.post(
                            name: .toFirstTab,
                            object: nil,
                            userInfo: ["index": self.pickerView.selectedRow(inComponent: 0) - 1]
                        )
                        print("ホームに移動")
                    })
                }
            }
        }
    }
    
    @IBAction func handleCancelButton(_ sender: Any) {
        // 画面を閉じる
        self.dismiss(animated: true, completion: nil)
    }
}

extension String {
    func replace(_ from: String,_ to: String) -> String {
        var replacedString = self
        while((replacedString.range(of: from)) != nil){
            if let range = replacedString.range(of: from) {
                replacedString.replaceSubrange(range, with: to)
            }
        }
        return replacedString
    }
}

extension PostViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if info[.originalImage] != nil {
            // 撮影/選択された画像を取得する
            let image = info[.originalImage] as! UIImage
            selectedImage = image
            photo.image = image
        }
        self.dismiss(animated: true, completion: nil)
    }
}
