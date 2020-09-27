//
//  UniversalParser.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/06/12.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import Foundation


class UniversalParser : TimeTableParser {

    var delegate: ParserDelegate?
    
    var selectedDate: Date?
    
    var currentSession: URLSessionDataTask?
    
    
    override func setDelegate(delegate: ParserDelegate?) {
        self.delegate = delegate
    }
    
    override func parse(from: Stop, to: Stop, when: Date) {
        self.selectedDate = when
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let url = "https://mphsoft.uber.space/api/kotsu/departure/\(from.id)/\(to.id)/\(dateFormatter.string(from: when))"
        
        if currentSession != nil {
            currentSession?.cancel()
            currentSession = nil
        }
        currentSession = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {(data, response, error) in
            if let error = error as NSError?, error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                print("Request cancelled")
                return
            }
            
            guard let data = data, error == nil else {
                print("Failed to retrieve data")
                self.delegate?.failure()
                return
            }
            
            guard let items = try? JSONDecoder().decode([Item].self, from: data) else {
                print("Failed to decode data")
                self.delegate?.failure()
                return
            }
            
            var departures: [Departure] = []
            for item in items {
                guard let destination = StopLoader.instance.getStop(id: item.terminal.code) else { continue }
                
                var date: Date = Date(timeInterval: 0, since: self.selectedDate!)
                var hour = item.hours
                if hour > 23 {
                    date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
                    hour = 0
                }
                let time: Date = Calendar.current.date(bySettingHour: hour, minute: item.minutes, second: 0, of: date)!
                
                var line = item.line
                if Locale.current.languageCode != "ja" {
                    line = line.replacingOccurrences(of: "奈",  with: "Kotsu")
                    line = line.replacingOccurrences(of: "関", with: "KATE")
                }
                
                let departure = Departure(destination: destination, line: line, platform: item.platform, fare: item.fare, time: time, duration: item.duration)
                departures.append(departure)
            }
            
            if departures.count > 0 {
                self.delegate?.success(departures: departures.sorted(by: {$0.time.compare($1.time) == .orderedAscending}))
            } else {
                self.delegate?.failure()
            }
        })
        currentSession?.resume()
    }
    
    
    struct Item : Codable {
        let date: String
        let hours: Int
        let minutes: Int
        let line: String
        let platform: Int
        let duration: Int
        let fare: Int
        let terminal: Terminal
    }
    
    struct Terminal : Codable {
        let code: Int
    }

}
