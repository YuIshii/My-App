//
//  LoginViewController.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

class LoginViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var mailAddressTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
           super.viewDidLoad()
        
        mailAddressTextField.addBorderBottom(height: 1.0, color: UIColor.lightGray)
        passwordTextField.addBorderBottom(height: 1.0, color: UIColor.lightGray)
        
        mailAddressTextField.delegate = self
        passwordTextField.delegate = self
        
        loginButton.layer.cornerRadius = 5.0
        
       }

    // ログインボタンをタップしたときに呼ばれるメソッド
    @IBAction func handleLoginButton(_ sender: Any) {
        if let address = mailAddressTextField.text, let password = passwordTextField.text {

            // アドレスとパスワード名のいずれかでも入力されていない時は何もしない
            if address.isEmpty || password.isEmpty {
                HUD.flash(.labeledError(title: "エラー", subtitle: "必要項目を入力して下さい"), delay: 1.4)
                return
            }

            HUD.show(.progress, onView: view)
            
            Auth.auth().signIn(withEmail: address, password: password) { authResult, error in
                if let error = error {
                    print("DEBUG_PRINT: " + error.localizedDescription)
                    HUD.flash(.labeledError(title: "エラー", subtitle: "サインインに失敗しました"), delay: 1.4)
                    return
                }
                print("DEBUG_PRINT: ログインに成功しました。")

                // 画面を閉じてタブ画面に戻る
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootTabBarController")
                HUD.hide()
                self.present(rootViewController, animated: true, completion: nil)
                   }
            }
        }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを閉じる
        view.endEditing(true)
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
    }
    
}

extension UITextField {
    func addBorderBottom(height: CGFloat, color: UIColor) {
        let border = CALayer()
        border.frame = CGRect(x: 0, y: self.frame.height - height, width: self.frame.width, height: height)
        border.backgroundColor = color.cgColor
        self.layer.addSublayer(border)
    }
    
}



