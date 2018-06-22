//
//  Stop.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/05/29.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import Foundation

class Stop : NSObject, Codable {
    
    var id = 0
    var nameEN = ""
    var nameJP = ""
    
    var visible = true
    
    
    init(id: Int, nameEN: String, nameJP: String, visible: Bool = true) {
        self.id = id
        self.nameEN = nameEN
        self.nameJP = nameJP
        self.visible = visible
    }
    
    func getName() -> String {
        if(Locale.current.languageCode == "ja") {
            return nameJP
        } else {
            return nameEN
        }
    }
    
}
