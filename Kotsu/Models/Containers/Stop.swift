//
//  Stop.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/05/29.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import Foundation

class Stop {
    
    var id = 0
    var nameEN = ""
    var nameJP = ""
    
    var visible = true
    
    
    init(id: Int, nameEN: String, nameJP: String, visible: Bool = true) {
        self.id = id
        self.nameEN = nameEN
        self.nameJP = nameJP
        self.visible = visible;
    }
    
    func getName() -> String {
        if(Locale.current.languageCode == "ja") {
            return nameJP
        } else {
            return nameEN
        }
    }
    
    
    static let allStops:[Stop] = [
        Stop(id: 560, nameEN: "NAIST", nameJP: "奈良先端科学技術大学院大学"),
        Stop(id: 558, nameEN: "Takayama Science Town", nameJP: "高山サイエンスタウン"),
        Stop(id: 2610, nameEN: "Gakken-Kita-Ikoma Station", nameJP: "学研北生駒駅"),
        Stop(id: -1, nameEN: "Gakuemmae Station", nameJP: "学園前駅"),
        Stop(id: 631, nameEN: "Chiku Center", nameJP: "地区センター"),
        Stop(id: 632, nameEN: "Shiki-no-Mori Kōen", nameJP: "四季の森公園"),
        Stop(id: -14, nameEN: "Gakken-Nara-Tomigaoka Station", nameJP: "学研奈良登美ヶ丘駅"),
        Stop(id: -5601, nameEN: "Takanohara Station", nameJP: "高の原駅"),
        Stop(id: 606, nameEN: "Keihanna Plaza", nameJP: "けいはんなプラザ"),
        
        Stop(id: 100001, nameEN: "Kansai Airport Terminal 1", nameJP: "関西空港第1ターミナル"),
        Stop(id: 100002, nameEN: "Kansai Airport Terminal 2", nameJP: "関西空港第2ターミナル"),
        
        Stop(id: 604, nameEN: "Gyoen Station", nameJP: "祝園駅", visible: false),
        Stop(id: 625, nameEN: "Kano-no-Kita 2-Chome", nameJP: "鹿ノ台北二丁目", visible: false)
    ]
    
    
    static func getAll() -> [Stop] {
        return allStops.filter({$0.visible == true})
    }
    
    static func getStop(id: Int) -> Stop? {
        let stops = allStops.filter({$0.id == id})
        return stops.count > 0 ? stops[0] : nil
    }
    
    static func getStop(jp: String) -> Stop? {
        let stops = allStops.filter({jp.contains($0.nameJP)})
        return stops.count > 0 ? stops[0] : nil
    }
    
}
