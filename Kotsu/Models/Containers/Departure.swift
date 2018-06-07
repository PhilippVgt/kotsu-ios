//
//  Departure.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/05/30.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import Foundation

class Departure {
    
    var destination: Stop
    var time: Date
    var line: String
    var platform: Int
    var fare: Int
    var duration: Int
    
    init(destination: Stop, line: String, platform: Int, fare: Int, time: Date, duration: Int) {
        self.destination = destination
        self.line = line
        self.platform = platform
        self.fare = fare
        self.time = time
        self.duration = duration
    }
    
}
