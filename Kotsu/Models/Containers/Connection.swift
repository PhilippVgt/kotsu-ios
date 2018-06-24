//
//  Connection.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/06/24.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import Foundation

class Connection : NSObject, Codable {
    
    var from, to : Stop
    
    init(from: Stop, to: Stop) {
        self.from = from
        self.to = to
    }
    
}
