//
//  Parser.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/05/31.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import Foundation
import WebKit
import SwiftSoup


class NaraKotsuParser : TimeTableParser, WKNavigationDelegate {
    
    var webView: WKWebView!
    
    var destination : Stop?
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
        
        self.destination = to
        self.selectedDate = when
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let url = "https://navi.narakotsu.co.jp/result_timetable/?stop1=\(from.id)&stop2=\(to.id)&date=\(dateFormatter.string(from: when))"
        print("Loading \(url)")
        
        webView.load(URLRequest(url: URL(string: url)!))
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            webView.evaluateJavaScript("document.getElementsByClassName('timetable')[0].outerHTML;",
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
            let table: Element = try doc.getElementsByTag("tbody").first()!
            
            let destinations: Elements = try table.getElementsByClass("destination").first()!.children()
            let platforms: Elements = try table.getElementsByClass("platform").first()!.children()
            let durations: Elements = try table.getElementsByClass("required").first()!.children()
            let fares: Elements = try table.getElementsByClass("fare").first()!.children()
            
            let minutes: Elements = try doc.select(".minutes")
            
            var departures: [Departure] = []
            for minute: Element in minutes {
                let min: Int = try Int(minute.text())!
                var hour: Int = try Int(minute.parent()!.parent()!.getElementsByClass("timezone_link").text())!
                var date: Date = Date(timeInterval: 0, since: selectedDate!)
                if hour > 23 {
                    date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
                    hour = 0
                }
                let time: Date = Calendar.current.date(bySettingHour: hour, minute: min, second: 0, of: date)!
                
                let column: Int = try minute.parent()!.elementSiblingIndex()
                let line: String = try destinations.get(column).getElementsByClass("indicator_no").first()!.text()
                let platform: Int = try Int(platforms.get(column).text().replacingOccurrences(of: "[^\\d.]", with: "", options: .regularExpression)) ?? 0
                let duration: Int = try Int(durations.get(column).text().replacingOccurrences(of: "分", with: "")) ?? 0
                
                var destination: Stop? = Stop.getStop(jp: try destinations.get(column).child(1).text())
                destination = destination != nil ? destination : self.destination
                destination = destination != nil ? destination : Stop(id: 0, nameEN: "-", nameJP: "-")
                
                var fare = 0
                if(try fares.get(column).getElementsByTag("a").size() > 0) {
                    fare = try Int(fares.get(column).getElementsByTag("a").first()!.text().replacingOccurrences(of: "円", with: "")) ?? 0
                } else {
                    fare = try Int(fares.get(column).text().replacingOccurrences(of: "円", with: "")) ?? 0
                }
                
                departures.append(Departure(destination: destination!, line: line, platform: platform, fare: fare, time: time, duration: duration))
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
