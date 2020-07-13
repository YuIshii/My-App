//
//  TabBarController.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import Firebase

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //0番目のtabの選択時の画像を設定
        tabBar.items![0].selectedImage = UIImage(named: "home")!.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
    
        //1番目のtabの選択時の画像を設定
        tabBar.items![1].selectedImage = UIImage(named: "trending")!.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        
        //3番目のtabの選択時の画像を設定
        tabBar.items![3].selectedImage = UIImage(named: "profile")!.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        
        UITabBar.appearance().tintColor = UIColor.black
        
        // UITabBarControllerDelegateプロトコルのメソッドをこのクラスで処理する。
        self.delegate = self
        
        //異なるViewController間のイベント(処理)通知を実現させるNotificationCenterの受信側。
        //toFirstTab通知が発行されたtoFirstTabメソッドが実行される。
        NotificationCenter.default.addObserver(self, selector: #selector(toFirstTab), name: .toFirstTab, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(firstMenu), name: .firstMenu, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser != nil {
            if Auth.auth().currentUser?.isEmailVerified == true {
                print("メール認証が完了しています。")
            } else {
                print("メール認証が完了していません")
                let storyboard = UIStoryboard(name: "EmailVerification", bundle: Bundle.main)
                let rootViewController = storyboard.instantiateViewController(withIdentifier: "EmailVerification")
                self.present(rootViewController, animated: true, completion: nil)
            }
        }else {
            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginNavi")
            self.present(loginViewController!, animated: true, completion: nil)
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("tabBar didSelect item.tag: \(item.tag) selectedIndex: \(self.selectedIndex)")
        if item.tag == self.selectedIndex {
            switch item.tag {
            case 0:
                NotificationCenter.default.post(name: .page1Top, object: nil)
            case 1:
                let navigationController = self.viewControllers?[1] as! UINavigationController
                let trendingViewController = navigationController.topViewController as! TrendingViewController
                if trendingViewController.postArray.count == 0 {
                    print("お気に入りの投稿がありません")
                }else{
                    trendingViewController.tableView?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                }
            case 3:
                let navigationController = self.viewControllers?[3] as! UINavigationController
                let profileViewController = navigationController.topViewController as! ProfileViewController
                if profileViewController.postArray.count == 0 {
                    print("お気に入りの投稿がありません")
                }else{
                    profileViewController.tableView?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                }
                print("テスト中")
            default: break
            }
        }
    }

    // タブバーのアイコンがタップされた時に呼ばれるdelegateメソッドを処理する。
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController is UINavigationController {
            let navigationController = viewController as! UINavigationController
            if navigationController.topViewController! is PostViewController {
                // PostViewControllerは、タブ切り替えではなくモーダル画面遷移する
                let PostViewController = storyboard!.instantiateViewController(withIdentifier: "Post")
                present(PostViewController, animated: true)
                return false
            } else {
                // その他のViewControllerは通常のタブ切り替えを実施
                return true
            }
        }
        return true
    }
    //viewControllersプロパティでBaseViewControllerを取得し、そこからslideメソッドを呼び出す
    @objc func toFirstTab(notification: Notification) {
        self.selectedIndex = 0
        if let userInfo = notification.userInfo, let index = userInfo["index"] as? Int {
            let navigationController = self.viewControllers?[0] as! UINavigationController
            let baseViewController = navigationController.topViewController as! BaseViewController
            baseViewController.slide(index: index)
        }
    }
    
    @objc func firstMenu(){
        self.selectedIndex = 0
        var navigationController = self.viewControllers?[0] as! UINavigationController
        var baseViewController = navigationController.topViewController as! BaseViewController
        baseViewController.firstMenu()
    }
}

//Notificationの通知名の設定。TabBarControllerクラスの外に記述。
extension Notification.Name {
    static let toFirstTab = Notification.Name("toFirstTab")
}

extension Notification.Name {
    static let firstMenu = Notification.Name("firstMenu")
}

extension Notification.Name {
    static let page1Top = Notification.Name("page1Top")
}
