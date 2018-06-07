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
    
    private static var kansaiAirportParser : TimeTableParser = KansaiAirportParser();
    private static var naraKotsuParser : TimeTableParser = NaraKotsuParser();
    
    public static func getParser(from: Stop, to: Stop, delegate: ParserDelegate) -> TimeTableParser {
        if(from.id == 100001 || from.id == 100002 || to.id == 100001 || to.id == 100002) {
            kansaiAirportParser.setDelegate(delegate: delegate);
            return kansaiAirportParser;
        } else {
            naraKotsuParser.setDelegate(delegate: delegate);
            return naraKotsuParser;
        }
    }
}
