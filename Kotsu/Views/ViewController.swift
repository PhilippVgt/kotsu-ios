//
//  ViewController.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/05/29.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import UIKit
import WebKit
import SwiftSoup


class ViewController: UIViewController, WKNavigationDelegate {
    
    //MARK: Properties
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    @IBOutlet weak var todayButton: UIButton!
    @IBOutlet weak var tomorrowButton: UIButton!
    @IBOutlet weak var otherButton: UIButton!
    
    @IBOutlet weak var listView: UIView!
    
    var webView: WKWebView!
    
    var currentDate: Date = Date()
    var fromStop: Stop = Stop.getStop(id: 560)!
    var toStop: Stop = Stop.getStop(id: 2610)!
    
    var departures: [Departure] = []
    var departureViewController: DepartureTableViewController?
    
    
    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fromButton.layer.masksToBounds = true
        fromButton.layer.cornerRadius = 8
        toButton.layer.masksToBounds = true
        toButton.layer.cornerRadius = 8
        
        todayButton.isSelected = true
        let weekday = Calendar(identifier: .gregorian).component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 {
            otherButton.setTitle("Weekdays", for: .normal)
        } else {
            otherButton.setTitle("Weekend", for: .normal)
        }
        
        updateTimeTable()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    //MARK: Actions
    @IBAction func swap(_ sender: UIButton) {
        let from: Stop = self.fromStop
        fromStop = toStop
        toStop = from
        updateTimeTable()
        
        fromButton.setTitle(fromStop.getName(), for: .normal)
        toButton.setTitle(toStop.getName(), for: .normal)
    }
    
    @IBAction func selectFrom(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Location", message: "Where do you depart from?", preferredStyle: UIAlertControllerStyle.actionSheet)
        for stop in Stop.getAll() {
            actionSheet.addAction(UIAlertAction(title: stop.getName(), style: UIAlertActionStyle.default) { (action) in
                self.fromStop = stop
                self.fromButton.setTitle(self.fromStop.getName(), for: .normal)
                self.updateTimeTable()
            })
        }
        actionSheet.popoverPresentationController?.sourceView = self.fromButton
        actionSheet.popoverPresentationController?.sourceRect = self.fromButton.bounds
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func selectTo(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Destination", message: "Where are you going?", preferredStyle: UIAlertControllerStyle.actionSheet)
        for stop in Stop.getAll() {
            actionSheet.addAction(UIAlertAction(title: stop.getName(), style: UIAlertActionStyle.default) { (action) in
                self.toStop = stop
                self.toButton.setTitle(self.toStop.getName(), for: .normal)
                self.updateTimeTable()
            })
        }
        actionSheet.popoverPresentationController?.sourceView = self.toButton
        actionSheet.popoverPresentationController?.sourceRect = self.toButton.bounds
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    
    @IBAction func todaySelected(_ sender: UIButton) {
        todayButton.isSelected = true
        tomorrowButton.isSelected = false
        otherButton.isSelected = false
        currentDate = Date()
        updateTimeTable()
    }
    
    @IBAction func tomorrowSelected(_ sender: UIButton) {
        todayButton.isSelected = false
        tomorrowButton.isSelected = true
        otherButton.isSelected = false
        currentDate = Date()
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        updateTimeTable()
    }
    
    @IBAction func otherSelected(_ sender: UIButton) {
        todayButton.isSelected = false
        tomorrowButton.isSelected = false
        otherButton.isSelected = true
        currentDate = Date()
        let weekday = Calendar(identifier: .gregorian).component(.weekday, from: currentDate)
        if weekday == 1 || weekday == 7 {
            currentDate = Calendar.current.date(bySetting: .weekday, value: 4, of: currentDate)!
        } else {
            currentDate = Calendar.current.date(bySetting: .weekday, value: 1, of: currentDate)!
        }
        updateTimeTable()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "departureTableSegue" {
            departureViewController = segue.destination as? DepartureTableViewController
        }
    }
    
    
    private func updateTimeTable() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let url = "https://navi.narakotsu.co.jp/result_timetable/?stop1=\(fromStop.id)&stop2=\(toStop.id)&date=\(dateFormatter.string(from: currentDate))"
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
                                        }
            })
            
            
        })
    }
    
    func parse(html: String) {
        let doc: Document = try! SwiftSoup.parse(html)
        let table: Element = try! doc.getElementsByTag("tbody").first()!
        
        let destinations: Elements = try! table.getElementsByClass("destination").first()!.children()
        let platforms: Elements = try! table.getElementsByClass("platform").first()!.children()
        let durations: Elements = try! table.getElementsByClass("required").first()!.children()
        let fares: Elements = try! table.getElementsByClass("fare").first()!.children()
        
        let minutes: Elements = try! doc.select(".minutes")
        
        var departures: [Departure] = []
        for minute: Element in minutes {
            let min: Int = try! Int(minute.text())!
            var hour: Int = try! Int(minute.parent()!.parent()!.getElementsByClass("timezone_link").text())!
            var date: Date = Date()
            if hour > 23 {
                date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
                hour = 0
            }
            let time: Date = Calendar.current.date(bySettingHour: hour, minute: min, second: 0, of: date)!
            
            let column: Int = try! minute.parent()!.elementSiblingIndex()
            let line: Int = try! Int(destinations.get(column).getElementsByClass("indicator_no").first()!.text())!
            let platform: Int = try! Int(platforms.get(column).text().replacingOccurrences(of: "[^\\d.]", with: "", options: .regularExpression))!
            let duration: Int = try! Int(durations.get(column).text().replacingOccurrences(of: "分", with: ""))!
            
            var destination: Stop? = Stop.getStop(jp: try! destinations.get(column).child(1).text())
            destination = destination != nil ? destination : toStop
            destination = destination != nil ? destination : Stop(id: 0, nameEN: "-", nameJP: "-")
            
            var fare = 0
            if(try! fares.get(column).getElementsByTag("a").size() > 0) {
                fare = try! Int(fares.get(column).getElementsByTag("a").first()!.text().replacingOccurrences(of: "円", with: ""))!
            } else {
                fare = try! Int(fares.get(column).text().replacingOccurrences(of: "円", with: ""))!
            }
            
            departures.append(Departure(destination: destination!, line: line, platform: platform, fare: fare, time: time, duration: duration))
        }
        
        if departures.count > 0 {
            self.departures = departures.sorted(by: {$0.time.compare($1.time) == .orderedAscending})
            updateList()
        }
    }
    
    func updateList() {
        departureViewController?.setDepartures(departures: departures)
    }
    
}

