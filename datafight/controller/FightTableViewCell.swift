//
//  FightTableViewCell.swift
//  datafight
//
//  Created by younes ouasmi on 19/08/2024.
//

import UIKit
import SDWebImage
import FlagKit

class FightTableViewCell: UITableViewCell {
    @IBOutlet weak var blueFlagImageView: UIImageView!
    @IBOutlet weak var blueFighterImageView: UIImageView!
    @IBOutlet weak var blueFighterNameLabel: UILabel!
    @IBOutlet weak var fightInfoLabel: UILabel!
    @IBOutlet weak var redFighterImageView: UIImageView!
    @IBOutlet weak var redFighterNameLabel: UILabel!
    @IBOutlet weak var redFlagImageView: UIImageView!

    func configure(with fight: Fight, blueFighter: Fighter, redFighter: Fighter, event: Event) {
        // Blue Fighter
        if let flag = Flag(countryCode: blueFighter.country) {
            blueFlagImageView.image = flag.image(style: .roundedRect)
        }
        blueFighterImageView.sd_setImage(with: URL(string: blueFighter.profileImageURL ?? ""), placeholderImage: UIImage(named: "placeholder_fighter"))
        blueFighterNameLabel.text = "\(blueFighter.firstName) \(blueFighter.lastName)"

        // Fight Info
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dateString = dateFormatter.string(from: event.date)
        fightInfoLabel.text = "\(event.eventName) - \(dateString) - \(fight.category)   \(fight.weightCategory)kg  -  \(fight.round)"
       

        // Red Fighter
        if let flag = Flag(countryCode: redFighter.country) {
            redFlagImageView.image = flag.image(style: .roundedRect)
        }
        redFighterImageView.sd_setImage(with: URL(string: redFighter.profileImageURL ?? ""), placeholderImage: UIImage(named: "placeholder_fighter"))
        redFighterNameLabel.text = "\(redFighter.firstName) \(redFighter.lastName)"
    }
}
