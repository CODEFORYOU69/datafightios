//
//  EventDetailViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import UIKit
import SDWebImage
import FlagKit

class EventDetailViewController: UIViewController {

    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventTypeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
    
    var event: Event?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        guard let event = event else { return }
        
        eventNameLabel.text = event.eventName
        eventTypeLabel.text = event.eventType.rawValue
        locationLabel.text = event.location
        countryLabel.text = event.country
        
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
