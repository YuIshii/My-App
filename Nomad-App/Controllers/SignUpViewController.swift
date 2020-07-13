//
//  SignUpViewController.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

class SignUpViewController: UIViewController,UITextFieldDelegate {
    
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var mailAddressTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayNameTextField.addBorderBottom(height: 1.0, color: UIColor.lightGray)
        mailAddressTextField.addBorderBottom(height: 1.0, color: UIColor.lightGray)
        passwordTextField.addBorderBottom(height: 1.0, color: UIColor.lightGray)
        
        displayNameTextField.delegate = self
        mailAddressTextField.delegate = self
        passwordTextField.delegate = self
        
        self.navigationItem.hidesBackButton = true
        signupButton.layer.cornerRadius = 5.0
    }
    
    // アカウント作成ボタンをタップしたときに呼ばれるメソッド
    @IBAction func handleCreateAccountButton(_ sender: Any) {
        
        let displayName = displayNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if let address = mailAddressTextField.text, let password = passwordTextField.text {
            
            // アドレスとパスワードと表示名のいずれかでも入力されていない時は何もしない
            if address.isEmpty || password.isEmpty || displayName.isEmpty {
                print("DEBUG_PRINT: 何かが空文字です。")
                HUD.flash(.labeledError(title: "エラー", subtitle: "必要項目を入力してください"), delay: 1.4)
                return
            } else if displayName.count > 20{
                print("DEBUG_PRINT: ユーザー名が21文字以上です")
                HUD.flash(.labeledError(title: "エラー", subtitle: "ユーザー名が20文字をこえています"), delay: 1.4)
                return
            } else if password.count < 6 {
                HUD.flash(.labeledError(title: "エラー", subtitle: "パスワードは6文字以上にしてください"), delay: 1.4)
                return
            } else if isValidEmail(emailID: address) == false {
                HUD.flash(.labeledError(title: "エラー", subtitle: "無効なメールアドレスです"), delay: 1.4)
                return
            }
            
            let alert: UIAlertController = UIAlertController(title: "確認", message: "利用規約とプライバシーポリシーに同意の上、新規登録しますか？", preferredStyle:  UIAlertController.Style.alert)

            let defaultAction: UIAlertAction = UIAlertAction(title: "同意する", style: UIAlertAction.Style.default, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
                print("OK")

                let email = self.mailAddressTextField.text ?? ""
                let password = self.passwordTextField.text ?? ""
                let name = self.displayNameTextField.text ?? ""
                
                // HUDで投稿処理中の表示を開始
                HUD.show(.progress, onView: self.view)
                Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
                    guard let self = self else { return }
                    if let user = result?.user {
                        let req = user.createProfileChangeRequest()
                        req.displayName = name
                        req.commitChanges() { [weak self] error in
                            guard let self = self else { return }
                            if error == nil {
                                user.sendEmailVerification() { [weak self] error in
                                    guard let self = self else { return }
                                    if error == nil {
                                        print("確認メールを送信しました。")
                                        //メール認証が完了していなかったら
                                        let storyboard = UIStoryboard(name: "EmailVerification", bundle: Bundle.main)
                                        let rootViewController = storyboard.instantiateViewController(withIdentifier: "EmailVerification")
                                        HUD.hide()
                                        self.present(rootViewController, animated: true, completion: nil)
                                    }
                                    HUD.hide()
                                    self.showErrorIfNeeded(error)
                                }
                            }
                            HUD.hide()
                            self.showErrorIfNeeded(error)
                        }
                    }
                    HUD.hide()
                    self.showErrorIfNeeded(error)
                }
            })
            // キャンセルボタン
            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
                print("Cancel")
            })

            alert.addAction(cancelAction)
            alert.addAction(defaultAction)

            present(alert, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func back(_ sender: Any) {
        //遷移元に戻る
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
    }
    
    func isValidEmail(emailID:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: emailID)
    }
    
    private func showErrorIfNeeded(_ errorOrNil: Error?) {
        // エラーがなければ何もしません
        guard let error = errorOrNil else { return }
        
        let message = "エラーが起きました"
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを閉じる
        view.endEditing(true)
    }
}

