//
//  SettingsTableViewController.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

class SettingsTableViewController: UITableViewController {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorInset = .zero
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.tintColor = UIColor.black
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        
        let backBarButtonItem = UIBarButtonItem()
        backBarButtonItem.title = "Back"
        self.navigationItem.backBarButtonItem = backBarButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 表示名を取得してTextFieldに設定する
        let user = Auth.auth().currentUser
        if let user = user {
            let displayName:String = String(user.displayName!)
            if displayName.count > 8 {
                let prefixName = displayName.prefix(8)
                nameLabel.text = "\(prefixName)...  ＞"
                let email:String = String(user.email!)
                mailLabel.text = "\(email)"
            } else {
                nameLabel.text = "\(displayName)  ＞"
                let email:String = String(user.email!)
                mailLabel.text = "\(email)"
            }
        }
        // アプリのバージョン
        if let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
          versionLabel.text = "\(version)"
        }
    }
    //選択状態の解除
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func handleLogoutButton(_ sender: Any) {
        alertLogout()
    }
    
    @IBAction func handleDeleteButton(_ sender: Any) {
        alertDelete()
    }
    
    func alertLogout(){
        let alert: UIAlertController = UIAlertController.init(title: "ログアウト", message: "ログアウトしてよろしいですか？",
                                                              preferredStyle: UIAlertController.Style.alert)
        let cancelAction: UIAlertAction = UIAlertAction.init(title: "キャンセル", style: UIAlertAction.Style.cancel,
                                                             handler: { (UIAlertAction) in
                                                                print("キャンセルが選択されました。")
                                                                alert.dismiss(animated: true, completion: nil)
        })
        alert.addAction(cancelAction)
        let okAction: UIAlertAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default,
                                                         handler: { (UIAlertAction) in
                                                            print("OKが選択されました。")
                                                            // ログアウトする
                                                            try! Auth.auth().signOut()
                                                            
                                                            self.dismiss(animated: true, completion: nil)
                                                            
        })
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    
    func alertDelete(){
        let alert: UIAlertController = UIAlertController.init(title: "退会", message: "退会してよろしいですか？",
                                                              preferredStyle: UIAlertController.Style.alert)
        let cancelAction: UIAlertAction = UIAlertAction.init(title: "キャンセル", style: UIAlertAction.Style.cancel,
                                                             handler: { (UIAlertAction) in
                                                                print("キャンセルが選択されました。")
                                                                alert.dismiss(animated: true, completion: nil)
        })
        alert.addAction(cancelAction)
        let okAction: UIAlertAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default,
                                                         handler: { (UIAlertAction) in
                                                            print("OKが選択されました。")
                                                            self.alertDelete2()
                                                        
        })
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func alertDelete2(){
        let alert: UIAlertController = UIAlertController.init(title: "退会すると全てのデータが消えます", message: "本当に退会してよろしいですか？",
                                                              preferredStyle: UIAlertController.Style.alert)
        let cancelAction: UIAlertAction = UIAlertAction.init(title: "キャンセル", style: UIAlertAction.Style.cancel,
                                                             handler: { (UIAlertAction) in
                                                                print("キャンセルが選択されました。")
                                                                alert.dismiss(animated: true, completion: nil)
        })
        alert.addAction(cancelAction)
        let okAction: UIAlertAction = UIAlertAction.init(title: "退会する", style: UIAlertAction.Style.destructive,
                                                         handler: { (UIAlertAction) in
                                                            print("OKが選択されました。")
                                                            // ログイン中のユーザーアカウントを削除する。
                                                            Auth.auth().currentUser?.delete() {  (error) in
                                                                // エラーが無ければ、ログイン画面へ戻る
                                                                if error == nil {
                                                                    
                                                                    self.dismiss(animated: true, completion: nil)

                                                                }else{
                                                                    print("エラー：\(String(describing: error?.localizedDescription))")
                                                                    HUD.flash(.labeledError(title: "エラー", subtitle: "再度ログインしてお試しください"), delay: 1.4)
                                                                }
                                                            }
        })
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
}
