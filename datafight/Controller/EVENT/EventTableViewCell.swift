//
//  EventTableViewCell.swift
//  datafight
//
//  Created by younes ouasmi on 18/08/2024.
//

import FlagKit
import UIKit

class EventTableViewCell: UITableViewCell {
    // MARK: - IBOutlets
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventTypeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        // Add spacing
        contentView.frame = contentView.frame.inset(
            by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))

        // Add rounded corners
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        // Add shadow and neon effect
        layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.3).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.5
        layer.masksToBounds = false
        layer.shadowPath =
            UIBezierPath(
                roundedRect: bounds,
                cornerRadius: contentView.layer.cornerRadius
            ).cgPath

        // Make sure the cell's background is clear so the shadow is visible
        backgroundColor = .clear
    }

    // MARK: - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()

        // Set background color for the content view
        contentView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)  // Darker background

        // Round corners of eventImageView
        eventImageView.layer.cornerRadius = 5
        eventImageView.clipsToBounds = true

        // Style labels
        eventNameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        eventNameLabel.textColor = .white

        eventTypeLabel.font = UIFont.systemFont(ofSize: 14)
        eventTypeLabel.textColor = UIColor(
            red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8)  // Neon red color

        locationLabel.font = UIFont.systemFont(ofSize: 14)
        locationLabel.textColor = .lightGray

        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textColor = .lightGray
    }

    // MARK: - Configuration
    func configure(with event: Event) {
        eventNameLabel.text = event.eventName
        eventTypeLabel.text = event.eventType.rawValue
        locationLabel.text = event.location

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateLabel.text = dateFormatter.string(from: event.date)

        if let imageUrlString = event.imageURL,
            let imageUrl = URL(string: imageUrlString)
        {
            eventImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "placeholder_event"))
        } else {
            eventImageView.image = UIImage(named: "placeholder_event")
        }

        if let flag = Flag(countryCode: event.country) {
            countryFlagImageView.image = flag.image(style: .roundedRect)
        } else {
            countryFlagImageView.image = nil
        }

        // Add neon border to eventImageView
        eventImageView.layer.borderWidth = 1.0
        eventImageView.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor
    }
}
