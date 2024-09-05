//
//  EventTableViewCell.swift
//  datafight
//
//  Created by younes ouasmi on 18/08/2024.
//

import UIKit
import FlagKit

class EventTableViewCell: UITableViewCell {
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventTypeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
    
    func configure(with event: Event) {
        eventNameLabel.text = event.eventName
        eventTypeLabel.text = event.eventType
        locationLabel.text = event.location
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateLabel.text = dateFormatter.string(from: event.date)
        
        if let imageUrlString = event.imageURL, let imageUrl = URL(string: imageUrlString) {
            eventImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_event"))
        } else {
            eventImageView.image = UIImage(named: "placeholder_event")
        }
        
        if let flag = Flag(countryCode: event.country) {
            countryFlagImageView.image = flag.image(style: .roundedRect)
        } else {
            countryFlagImageView.image = nil
        }
    }
}
