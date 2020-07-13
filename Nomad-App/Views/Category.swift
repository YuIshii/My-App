//
//  Category.swift
//  Nomad-App
//
//  Created by yuishii on 2020/07/14.
//  Copyright © 2020 Yu Ishii. All rights reserved.
//

import Foundation

enum Category: Int {
    case news
    case topics
    case entertainment
    case music
    case sports
    case politics
    case business
    case science
    case medical
    case fashion
    case works
    case school
    case comics
    case game
    case living
    case marriage
    case recipe
    case study
    case hobby
    case question
    case mystery
    case prefectures
    case overseas
    case chat
    
    var name: String {
        switch self {
        case .news:
            return "ニュース"
        case .topics:
            return "話題・おもしろ"
        case .entertainment:
             return "TV・エンタメ"
        case .music:
             return "音楽"
        case .sports:
             return "スポーツ"
        case .politics:
             return "政治・経済"
        case .business:
             return "金融・ビジネス"
        case .science:
             return "IT・科学"
        case .medical:
             return "健康・医療"
        case .fashion:
             return "美容・ファッション"
        case .works:
             return "仕事"
        case .school:
             return "学校"
        case .comics:
             return "漫画・アニメ"
        case .game:
             return "ゲーム"
        case .living:
             return "暮らし・家族"
        case .marriage:
             return "結婚・恋愛"
        case .recipe:
             return "グルメ・レシピ"
        case .study:
             return "資格・勉強"
        case .hobby:
             return "趣味"
        case .question:
             return "質問・相談"
        case .mystery:
             return "不思議・謎"
        case .prefectures:
             return "都道府県"
        case .overseas:
             return "海外"
        case .chat:
             return "雑談・ネタ"
        }
    }
}

