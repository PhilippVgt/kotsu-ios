//
//  TimeTableParser.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/06/04.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import Foundation


protocol ParserDelegate {
    func success(departures: [Departure])
    func failure()
}

class TimeTableParser : NSObject {
    func setDelegate(delegate: ParserDelegate?) {}
    func parse(from: Stop, to: Stop, when: Date) {}
    
    private static var universalParser : TimeTableParser = UniversalParser()
    
    public static func getParser(from: Stop, to: Stop, delegate: ParserDelegate) -> TimeTableParser {
        universalParser.setDelegate(delegate: delegate)
        return universalParser
    }
}
