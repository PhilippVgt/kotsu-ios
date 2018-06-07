//
//  ViewController.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/05/29.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    
    //MARK: Properties
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    @IBOutlet weak var todayButton: UIButton!
    @IBOutlet weak var tomorrowButton: UIButton!
    @IBOutlet weak var otherButton: UIButton!
    @IBOutlet weak var nextBusLabel: UILabel!
    @IBOutlet weak var nextBusHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextBusCaption: UILabel!
    
    
    var currentDate: Date = Date()
    var fromStop: Stop = Stop.getStop(id: 560)!
    var toStop: Stop = Stop.getStop(id: 2610)!
    
    var departureViewController: DepartureTableViewController?
    
    var updateNextBusTimer: Timer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fromButton.layer.masksToBounds = true
        fromButton.layer.cornerRadius = fromButton.frame.size.height / 2
        toButton.layer.masksToBounds = true
        toButton.layer.cornerRadius = toButton.frame.size.height / 2
        
        todayButton.isSelected = true
        let weekday = Calendar(identifier: .gregorian).component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 {
            otherButton.setTitle(NSLocalizedString("weekday", comment: ""), for: .normal)
        } else {
            otherButton.setTitle(NSLocalizedString("weekend", comment: ""), for: .normal)
        }
        
        fromButton.setTitle(fromStop.getName(), for: .normal)
        toButton.setTitle(toStop.getName(), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if updateNextBusTimer == nil {
            updateNextBusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: updateNextBus)
        }
        
        if currentDate < Date() {
            todaySelected(todayButton)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if updateNextBusTimer != nil {
            updateNextBusTimer?.invalidate()
            updateNextBusTimer = nil
        }
    }
    
    
    //MARK: Actions
    @IBAction func swap(_ sender: UIButton) {
        let from: Stop = self.fromStop
        fromStop = toStop
        toStop = from
        
        fromButton.setTitle(fromStop.getName(), for: .normal)
        toButton.setTitle(toStop.getName(), for: .normal)
        
        departureViewController?.set(from: self.fromStop, to: self.toStop)
    }
    
    @IBAction func selectFrom(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: NSLocalizedString("location_title", comment: ""), message: NSLocalizedString("location_text", comment: ""), preferredStyle: UIAlertControllerStyle.actionSheet)
        for stop in Stop.getAll() {
            actionSheet.addAction(UIAlertAction(title: stop.getName(), style: UIAlertActionStyle.default) { (action) in
                self.fromStop = stop
                self.fromButton.setTitle(self.fromStop.getName(), for: .normal)
                
                self.departureViewController?.set(from: self.fromStop, to: self.toStop)
            })
        }
        actionSheet.popoverPresentationController?.sourceView = self.fromButton
        actionSheet.popoverPresentationController?.sourceRect = self.fromButton.bounds
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func selectTo(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: NSLocalizedString("destination_title", comment: ""), message: NSLocalizedString("destination_text", comment: ""), preferredStyle: UIAlertControllerStyle.actionSheet)
        for stop in Stop.getAll() {
            actionSheet.addAction(UIAlertAction(title: stop.getName(), style: UIAlertActionStyle.default) { (action) in
                self.toStop = stop
                self.toButton.setTitle(self.toStop.getName(), for: .normal)
                
                self.departureViewController?.set(from: self.fromStop, to: self.toStop)
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
        currentDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        
        departureViewController?.set(when: currentDate)
    }
    
    @IBAction func tomorrowSelected(_ sender: UIButton) {
        todayButton.isSelected = false
        tomorrowButton.isSelected = true
        otherButton.isSelected = false
        currentDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        
        departureViewController?.set(when: currentDate)
    }
    
    @IBAction func otherSelected(_ sender: UIButton) {
        todayButton.isSelected = false
        tomorrowButton.isSelected = false
        otherButton.isSelected = true
        currentDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let weekday = Calendar(identifier: .gregorian).component(.weekday, from: currentDate)
        if weekday == 1 || weekday == 7 {
            currentDate = Calendar.current.date(bySetting: .weekday, value: 4, of: currentDate)!
        } else {
            currentDate = Calendar.current.date(bySetting: .weekday, value: 1, of: currentDate)!
        }
        
        departureViewController?.set(when: currentDate)
    }
    
    
    func updateNextBus(timer: Timer) {
        let next: Departure? = (departureViewController?.getNextBus())
        
        if next != nil {
            let seconds: Int = Calendar.current.dateComponents([.second], from: Date(), to: next!.time).second!
            if seconds > 0 && seconds < 60*60 {
                let components = Calendar.current.dateComponents([.minute, .second], from: Date(), to: next!.time)
                nextBusLabel.text = String(format: "%0.2d:%0.2d", components.minute!, components.second!)
                if self.nextBusHeightConstraint.constant < 46 {
                    UIView.animate(withDuration: Double(0.5), animations: {
                        self.nextBusHeightConstraint.constant = 46
                        self.nextBusCaption.alpha = 1
                        self.nextBusLabel.alpha = 1
                        self.view.layoutIfNeeded()
                    })
                }
            } else {
                if self.nextBusHeightConstraint.constant > 0 {
                    UIView.animate(withDuration: Double(0.5), animations: {
                        self.nextBusHeightConstraint.constant = 0
                        self.nextBusCaption.alpha = 0
                        self.nextBusLabel.alpha = 0
                        self.view.layoutIfNeeded()
                    })
                }
            }
        } else {
            if self.nextBusHeightConstraint.constant > 0 {
                UIView.animate(withDuration: Double(0.5), animations: {
                    self.nextBusHeightConstraint.constant = 0
                    self.nextBusCaption.alpha = 0
                    self.nextBusLabel.alpha = 0
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    @IBAction func scrollToNextBus(_ sender: UITapGestureRecognizer) {
        departureViewController?.scrollToNext()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DepartureTableViewSegue" {
            departureViewController = segue.destination as? DepartureTableViewController
            
            departureViewController?.set(from: fromStop, to: toStop, when: currentDate)
        }
    }
    
}

