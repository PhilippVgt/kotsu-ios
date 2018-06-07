//
//  MealTableViewCell.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/06/01.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import UIKit

class DepartureTableViewCell: UITableViewCell {

    //MARK: Properties
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var remainingLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var lineLabel: UILabel!
    @IBOutlet weak var platformLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var fareLabel: UILabel!
    
    @IBOutlet weak var mainView: UIView!
    
    var departure: Departure!

}
