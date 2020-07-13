//
//  ProfileEditViewController.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import PKHUD

class ProfileEditViewController: UIViewController, UITextFieldDelegate {
    
    var pickerView: UIPickerView = UIPickerView()
    var selectedImage: UIImage!
    
    @IBOutlet weak var profileImageButton: UIButton!{
        didSet {
            profileImageButton.imageView?.contentMode = .scaleAspectFill
            profileImageButton.imageView?.layer.cornerRadius = 50.0
            profileImageButton.imageView?.layer.borderWidth = 0.5
            profileImageButton.imageView?.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var mailTextField: UITextField!
    
    let user = Auth.auth().currentUser?.displayName
    let mail = Auth.auth().currentUser?.email
    
    let icon: UIImage? = nil
    private let storageRef = Storage.storage().reference()
    private var picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImageButton.setImage(icon, for: .normal)
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.view.backgroundColor = .white
        
        nameTextField.text = user
        mailTextField.text = mail
        mailTextField.isEnabled = false
        
        nameTextField.delegate = self
        saveButton.isEnabled = false
        
        self.nameTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        nameTextField.textColor = .link
        
        //もしプロフィール画像を設定していなかったら"placeholderImg"を表示し、プロフィール画像を設定している場合はその画像を表示する。
        if Auth.auth().currentUser?.photoURL != nil{
            profileImageButton.sd_imageIndicator = SDWebImageActivityIndicator.gray
            let photoURL = Auth.auth().currentUser?.photoURL
            self.profileImageButton.sd_setImage(with: photoURL, for: .normal)
        }else {
            self.profileImageButton.setImage(UIImage(named: "placeholderImg"), for: .normal)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.selectImageView))
        profileImageButton.addGestureRecognizer(tapGesture)
        profileImageButton.isUserInteractionEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @IBAction func handleLibraryButton(_ sender: Any) {
        // ライブラリ（カメラロール）を指定してピッカーを開く
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = .photoLibrary
            self.present(pickerController, animated: true, completion: nil)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField:UITextField){
        //テキストの半角空白文字削除
        let trimmedString = self.nameTextField.text!.trimmingCharacters(in: .whitespaces)
        
        if trimmedString.isEmpty || trimmedString.count > 20 {
            saveButton.isEnabled = false
            print("無効化1")
        }else{
            saveButton.isEnabled = true
            print("有効化1")
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        //テキストの半角空白文字削除
        let trimmedString = self.nameTextField.text!.trimmingCharacters(in: .whitespaces)
        
        if trimmedString.isEmpty || trimmedString.count > 20 {
            saveButton.isEnabled = false
            print("無効化2")
        }else{
            saveButton.isEnabled = true
            print("有効化2")
        }
    }
    
    private func signInAnonymously(displayName: String?, photoURL: URL?) {
        
        // 表示名が入力されていない時はHUDを出して何もしない
        if displayName!.isEmpty {
            HUD.flash(.labeledError(title: "エラー", subtitle: "ユーザー名を入力してください"), delay: 1.4)
            return
        }else if displayName!.count > 20{
            print("DEBUG_PRINT: ユーザー名が21文字以上です")
            HUD.flash(.labeledError(title: "エラー", subtitle: "ユーザー名が20文字をこえています"), delay: 1.4)
            return
        }
        
        let user = Auth.auth().currentUser
        if let user = user {
            let changeRequest = user.createProfileChangeRequest()
            let displayName = self.nameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            changeRequest.displayName = displayName
            changeRequest.photoURL = photoURL
            changeRequest.commitChanges { error in
                if let error = error {
                    HUD.flash(.labeledError(title: "エラー", subtitle: "ユーザー名の変更に失敗しました"), delay: 1.4)
                    print("DEBUG_PRINT: " + error.localizedDescription)
                    return
                }
                HUD.flash(.labeledSuccess(title: "変更完了", subtitle: nil), delay: 1.4)
                print("DEBUG_PRINT: [displayName = \(user.displayName!)]の設定に成功しました。")
                //遷移元に戻る
                self.navigationController?.popViewController(animated: true)
            }
        }
        self.view.endEditing(true)
    }
    
    @IBAction func didTapSaveButton(_ sender: Any) {
        print("didTapSaveButton")
        
        HUD.show(.progress, onView: view)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let imageData = profileImageButton.imageView?.image?.jpegData(compressionQuality: 0.3) else { return }
        let imageRef = storageRef.child("images/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let _ = imageRef.putData(imageData, metadata: metadata) { [weak self] (metadata, error) in
            guard let _ = metadata else { return }
            imageRef.downloadURL { (url, error) in
                guard let photoURL = url else { return }
                self?.signInAnonymously(displayName: self?.nameTextField.text, photoURL: photoURL)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを閉じる
        view.endEditing(true)
    }
}

extension ProfileEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editImage = info[.editedImage] as? UIImage {
            profileImageButton.setImage(editImage.withRenderingMode(.alwaysOriginal), for: .normal)
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        profileImageButton.setTitle("", for: .normal)
        profileImageButton.imageView?.contentMode = .scaleAspectFill
        profileImageButton.contentHorizontalAlignment = .fill
        profileImageButton.contentVerticalAlignment = .fill
        profileImageButton.clipsToBounds = true
        
        if self.profileImageButton.imageView?.image != UIImage(named: "placeholderImg") && nameTextField.text?.count != 0{
            saveButton.isEnabled = true
        }else{
            saveButton.isEnabled = false
        }
        dismiss(animated: true, completion: nil)
    }
    
}
