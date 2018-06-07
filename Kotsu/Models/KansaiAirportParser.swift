//
//  KansaiAirportParser.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/06/04.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import Foundation
import WebKit
import SwiftSoup


class KansaiAirportParser : TimeTableParser, WKNavigationDelegate {
    
    var webView: WKWebView!

    var location, destination : Stop?
    var selectedDate: Date?
    
    var delegate: ParserDelegate?
    
    
    override init() {
        super.init()
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
    }
    
    
    override func setDelegate(delegate: ParserDelegate?) {
        self.delegate = delegate
    }
    
    override func parse(from: Stop, to: Stop, when: Date) {
        webView.stopLoading()
        
        self.location = from
        self.destination = to
        self.selectedDate = when
        
        let url = "http://www.kate.co.jp/timetable/detail/GK"
        print("Loading \(url)")
        
        webView.load(URLRequest(url: URL(string: url)!))
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            webView.evaluateJavaScript("document.body.innerHTML;",
                                       completionHandler: { (result, error) in
                                        if error == nil {
                                            var html = result as! String
                                            html = html.replacingOccurrences(of: "\\u003C", with: "<")
                                            html = html.replacingOccurrences(of: "\\t", with: "")
                                            html = html.replacingOccurrences(of: "\\n", with: "")
                                            html = html.replacingOccurrences(of: "\\\"", with: "\"")
                                            self.parse(html: html)
                                        } else {
                                            self.delegate?.failure()
                                        }
            })
        })
    }
    
    func parse(html: String) {
        do {
            let doc: Document = try SwiftSoup.parse(html)
            
            var finalStop: Stop?;
            var timeTable: Element;
            if location!.id == 100001 || location!.id == 100002 {
                timeTable = try doc.select(".timetable").get(1)
                finalStop = Stop.getStop(id: 606)
            } else {
                timeTable = try doc.select(".timetable").get(0)
                finalStop = Stop.getStop(id: 100002)
            }
            
            let fromStops = try timeTable.select(".dep_box .name")
            var fromColumn = -1
            for i in 0...(fromStops.size() - 1) {
                if try fromStops.get(i).text().contains(location!.nameJP) {
                    fromColumn = i
                    break
                }
            }
            
            let toStops = try timeTable.select(".arr_box .name")
            var toColumn = -1
            for i in 0...(toStops.size() - 1) {
                if try toStops.get(i).text().contains(destination!.nameJP) {
                    toColumn = fromStops.size() + i
                    break
                }
            }
            
            if fromColumn < 0 || toColumn < 0 {
                delegate?.failure()
                return
            }
            
            var fareString = try doc.select(".fare_area").first()?.text()
            if fareString != nil {
                fareString = fareString!.replacingOccurrences(of: "円", with: "")
                fareString = fareString!.replacingOccurrences(of: ",", with: "")
            }
            let fare: Int = Int(fareString!) ?? 0
            
            var departures = [Departure]()
            
            let rows = try timeTable.select(".time")
            for i in 0...(rows.size() - 1) {
                let row = rows.get(i)
                
                var company = try row.getElementsByClass("company").get(0).text()
                if Locale.current.languageCode != "ja" {
                    company = company.replacingOccurrences(of: "奈",  with: "Kotsu")
                    company = company.replacingOccurrences(of: "関", with: "KATE")
                }
                
                var time = try row.children().get(fromColumn + 1).text().components(separatedBy: ":")
                if time.count < 2 { continue }
                let departureTime = Calendar.current.date(bySettingHour: Int(time[0])!, minute: Int(time[1])!, second: 0, of: selectedDate!)
            
                time = try row.children().get(toColumn + 1).text().components(separatedBy: ":")
                if time.count < 2 { continue }
                let arrivalTime = Calendar.current.date(bySettingHour: Int(time[0])!, minute: Int(time[1])!, second: 0, of: selectedDate!)
                
                let duration = Int((arrivalTime?.timeIntervalSince(departureTime!))! / 60)
                
                departures.append(Departure(destination: (finalStop != nil) ? finalStop! : destination!, line: company, platform: 0, fare: fare, time: departureTime!, duration: duration));
            }
            
            if departures.count > 0 {
                self.delegate?.success(departures: departures.sorted(by: {$0.time.compare($1.time) == .orderedAscending}))
            } else {
                self.delegate?.failure()
            }
        } catch _ {
            self.delegate?.failure()
        }
    }
    
}
