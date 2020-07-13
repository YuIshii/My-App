//
//  BaseViewController.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/13.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import UIKit
import SegementSlide
import Firebase

class BaseViewController: SegementSlideViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadData()
        
        scrollToSlide(at: 0, animated: true)

        //segementslideのナビゲーションバーとタブバーが標準で透明になっているため、それを解除する。
        self.tabBarController?.tabBar.isTranslucent = false
        self.navigationController?.navigationBar.isTranslucent = false
        
        //ナビゲーションバーの色
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        //タブバーの色
        self.tabBarController?.tabBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.black
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backBarButtonItem = UIBarButtonItem()
        self.navigationItem.backBarButtonItem = backBarButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        let backBarButtonItem = UIBarButtonItem()
        backBarButtonItem.title = "Back"
        self.navigationItem.backBarButtonItem = backBarButtonItem
    }
    
    let titleArray: [String] = ["ニュース","話題・おもしろ","TV・エンタメ","音楽","スポーツ","政治・経済","金融・ビジネス","IT・科学","健康・医療","美容・ファッション","仕事","学校","漫画・アニメ","ゲーム","暮らし・家族","結婚・恋愛","グルメ・レシピ","資格・勉強","趣味","質問・相談","不思議・謎","都道府県","海外","雑談・ネタ"]

    
    //タイトル部分
    override var titlesInSwitcher: [String]{
        return titleArray
    }
    
    override var bouncesType: BouncesType {
        return .child
    }
    
    override func segementSlideContentViewController(at index: Int) -> SegementSlideContentScrollViewDelegate? {
        let vc = Page1ViewController()
        if let category = Category(rawValue: index) {
            vc.category = category.name
            return vc
        }
        vc.category = Category.news.name
        return vc
    }
    
    func slide(index: Int){
        //1番上までスクロールする
        reloadData()
        //ニュースタブから表示する
        scrollToSlide(at: index, animated: true)
    }
    
    
    func firstMenu(){
      //1番上までスクロールする
      reloadData()
      //ニュースタブから表示する
      scrollToSlide(at: 0, animated: true)
    }
    
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        // 他の画面から segue を使って戻ってきた時に呼ばれる
    }
}
