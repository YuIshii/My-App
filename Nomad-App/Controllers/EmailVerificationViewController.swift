//
//  EmailVerificationViewController.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

class EmailVerificationViewController: UIViewController {
    
    var timer: Timer!
    
    @IBOutlet weak var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        backButton.layer.cornerRadius = 5.0
        backButton.layer.borderColor = UIColor.gray.cgColor
        backButton.layer.borderWidth = 1.0
    }
    
    @IBAction func back(_ sender: Any) {
        
        let alert: UIAlertController = UIAlertController.init(title: "登録画面に戻る", message: "仮登録したアカウントは削除されますがよろしいですか？",
                                                              preferredStyle: UIAlertController.Style.alert)
        let cancelAction: UIAlertAction = UIAlertAction.init(title: "キャンセル", style: UIAlertAction.Style.cancel,
                                                             handler: { (UIAlertAction) in
                                                                print("キャンセルが選択されました。")
                                                                alert.dismiss(animated: true, completion: nil)
        })
        alert.addAction(cancelAction)
        let okAction: UIAlertAction = UIAlertAction.init(title: "はい", style: UIAlertAction.Style.destructive,
                                                         handler: { (UIAlertAction) in
                                                            print("OKが選択されました。")
                                                            // ログイン中のユーザーアカウントを削除する。
                                                            Auth.auth().currentUser?.delete() {  (error) in
                                                                // エラーが無ければ、ログイン画面へ戻る
                                                                if error == nil {
                                                                    print("アカウント削除完了")
                                                                    
                                                                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                                                    let rootViewController = storyboard.instantiateViewController(withIdentifier: "LoginNavi")
                                                                    self.present(rootViewController, animated: true, completion: nil)
                                                                }else{
                                                                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                                                    let rootViewController = storyboard.instantiateViewController(withIdentifier: "LoginNavi")
                                                                    self.present(rootViewController, animated: true, completion: nil)
                                                                }
                                                            }
        })
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.reload), userInfo: nil, repeats: true)
    }
    
    // 画面が閉じる直前に呼ばれる
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // タイマーを停止する
        if let workingTimer = timer{
            workingTimer.invalidate()
        }
    }
    
    @objc func reload(_ sender: Timer) {
        if Auth.auth().currentUser != nil {
            Auth.auth().currentUser?.reload(completion: { error in
                if error == nil {
                    if Auth.auth().currentUser?.isEmailVerified == true {
                        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                        let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootTabBarController")
                        self.present(rootViewController, animated: true, completion: nil)
                    } else if Auth.auth().currentUser?.isEmailVerified == false {
                        print("メール認証が完了していません")
                    }
                }
            })
        }
    }
}
