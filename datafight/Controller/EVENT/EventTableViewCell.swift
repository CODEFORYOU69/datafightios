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
    
    override func layoutSubviews() {
           super.layoutSubviews()
           
           // Add spacing
           contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
           
           // Add rounded corners
           contentView.layer.cornerRadius = 10
           contentView.layer.masksToBounds = true
           
           // Add shadow
           layer.shadowColor = UIColor.black.cgColor
           layer.shadowOffset = CGSize(width: 0, height: 2)
           layer.shadowRadius = 4
           layer.shadowOpacity = 0.1
           layer.masksToBounds = false
           layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
           
           // Make sure the cell's background is clear so the shadow is visible
           backgroundColor = .clear
       }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set background color for the content view
        contentView.backgroundColor = .white
        
        // Round corners of eventImageView
        eventImageView.layer.cornerRadius = 5
        eventImageView.clipsToBounds = true
        
        // Style labels
        eventNameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        eventTypeLabel.font = UIFont.systemFont(ofSize: 14)
        eventTypeLabel.textColor = .gray
        locationLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textColor = .gray
    }
    
    func configure(with event: Event) {
        eventNameLabel.text = event.eventName
        eventTypeLabel.text = event.eventType.rawValue
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
