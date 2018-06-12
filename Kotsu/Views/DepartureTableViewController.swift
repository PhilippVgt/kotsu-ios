//
//  MealTableViewController.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/06/01.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import UIKit


class DepartureTableViewController: UITableViewController, ParserDelegate {
    
    //MARK: Properties
    var departures = [Departure]()
    
    var fromStop, toStop : Stop?
    var currentDate : Date?
    
    var updateCellContentsTimer: Timer?
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if updateCellContentsTimer == nil {
            updateCellContentsTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: updateCells)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if updateCellContentsTimer != nil {
            updateCellContentsTimer?.invalidate()
            updateCellContentsTimer = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func set(from: Stop, to: Stop) {
        fromStop = from
        toStop = to
        update()
    }
    
    func set(when: Date) {
        currentDate = when
        update()
    }
    
    func set(from: Stop, to: Stop, when: Date) {
        fromStop = from
        toStop = to
        currentDate = when
        update()
    }
    
    func getNextBus() -> Departure? {
        return departures.count > 0 ? departures[getNext()] : nil
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return departures.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DepartureTableViewCell", for: indexPath) as? DepartureTableViewCell else {
            fatalError("Incompatible cell")
        }
        
        let departure = departures[indexPath.row]
        
        cell.departure = departure
        cell.destinationLabel.text = departure.destination.getName()
        cell.lineLabel.text = departure.line == "" ? "-" : String(departure.line)
        cell.platformLabel.text = departure.platform == 0 ? "-" : String(departure.platform)
        cell.durationLabel.text = departure.duration == 0 ? "-" : String(format: NSLocalizedString("minutes", comment: ""), departure.duration)
        cell.fareLabel.text = departure.fare == 0 ? "-" : String(format: NSLocalizedString("fare", comment: ""), departure.fare)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        cell.timeLabel.text = dateFormatter.string(from: departure.time)
        
        updateCell(cell: cell)
        return cell
    }
    
    
    @IBAction func refresh(_ sender: UIRefreshControl) {
        update()
    }
    
    func update() {
        if fromStop != nil && toStop != nil && currentDate != nil {
            if departures.count > 0 {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
            tableView.setContentOffset(CGPoint(x: 0, y: -(refreshControl?.frame.size.height)!), animated: true)
            refreshControl?.beginRefreshing()
            TimeTableParser.getParser(from: fromStop!, to: toStop!, delegate: self)
                .parse(from: fromStop!, to: toStop!, when: currentDate!)
        }
    }
    
    func success(departures: [Departure]) {
        self.departures = departures
        DispatchQueue.main.sync {
            tableView.reloadData()
            if refreshControl?.isRefreshing == true {
                refreshControl?.endRefreshing()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.scrollToNext()
        })
    }
    
    func scrollToNext() {
        let indexPath = IndexPath(row: getNext(), section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    func failure() {
        self.departures = []
        DispatchQueue.main.sync {
            tableView.reloadData()
            if refreshControl?.isRefreshing == true {
                refreshControl?.endRefreshing();
            }
        }
    }
    
    
    func updateCells(timer: Timer) {
        let indexPathsArray = tableView.indexPathsForVisibleRows
        for indexPath in indexPathsArray! {
            let cell = tableView.cellForRow(at: indexPath) as! DepartureTableViewCell
            updateCell(cell: cell)
        }
    }
    
    func updateCell(cell: DepartureTableViewCell) {
        let seconds: Int = Calendar.current.dateComponents([.second], from: Date(), to: cell.departure.time).second!
        let minutes: Int = seconds / 60
        
        if minutes > 0 && minutes < 60 {
            cell.remainingLabel.text = String(format: NSLocalizedString("minutes", comment: ""), minutes)
        } else if seconds > 0 && seconds < 60 {
            cell.remainingLabel.text = String(format: NSLocalizedString("seconds", comment: ""), seconds)
        } else {
            cell.remainingLabel.text = ""
        }
        
        if seconds < 0 {
            cell.destinationLabel.textColor = UIColor.darkGray
            cell.timeLabel.textColor = UIColor.darkGray
            cell.lineLabel.textColor = UIColor.black
        } else {
            cell.destinationLabel.textColor = UIColor(red: 0.259, green: 0.337, blue: 0.773, alpha: 1.0)
            cell.timeLabel.textColor = UIColor.black
            cell.lineLabel.textColor = UIColor(red: 0.91, green: 0.320, blue: 0.106, alpha: 1.0)
        }
    }
    
    
    func getNext() -> Int {
        for (i, d) in departures.enumerated() {
            if Int(d.time.timeIntervalSince(Date())) > 0 {
                return i
            }
        }
        return 0
    }
}
