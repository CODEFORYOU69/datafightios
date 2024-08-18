//
//  EventListViewController.swift
//  datafight
//
//  Created by younes ouasmi on 18/08/2024.
//

//
//  EventListViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import UIKit
import Firebase
import SDWebImage
import FlagKit

class EventListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var events: [Event] = []
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        setupActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadEvents()
    }
    
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        // Assurez-vous que l'identifiant de réutilisation correspond à celui défini dans votre storyboard
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EventCell")
    }

    func setupNavigationBar() {
        navigationItem.title = "Events"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addEventTapped))
    }

    @objc func addEventTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let eventEditVC = storyboard.instantiateViewController(withIdentifier: "EventEditViewController") as? EventEditViewController {
            let navController = UINavigationController(rootViewController: eventEditVC)
            present(navController, animated: true, completion: nil)
        }
    }

    func loadEvents() {
        activityIndicator.startAnimating()
        FirebaseService.shared.getEvents { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                switch result {
                case .success(let events):
                    self?.events = events
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("Error loading events: \(error.localizedDescription)")
                    self?.showAlert(title: "Error", message: "Unable to load events")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
        let event = events[indexPath.row]
        
        configureCell(cell, with: event)
        
        return cell
    }

    private func configureCell(_ cell: UITableViewCell, with event: Event) {
        // Configurez les éléments de l'interface utilisateur de la cellule ici
        // Assurez-vous que les tags correspondent à ceux que vous avez définis dans le storyboard
        
        if let eventImageView = cell.viewWithTag(1) as? UIImageView {
            if let imageUrlString = event.imageURL, let imageUrl = URL(string: imageUrlString) {
                eventImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_event"))
            } else {
                eventImageView.image = UIImage(named: "placeholder_event")
            }
        }
        
        if let eventNameLabel = cell.viewWithTag(2) as? UILabel {
            eventNameLabel.text = event.eventName
        }
        
        if let eventTypeLabel = cell.viewWithTag(3) as? UILabel {
            eventTypeLabel.text = event.eventType
        }
        
        if let locationLabel = cell.viewWithTag(4) as? UILabel {
            locationLabel.text = event.location
        }
        
        if let dateLabel = cell.viewWithTag(5) as? UILabel {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateLabel.text = dateFormatter.string(from: event.date)
        }
        
        if let countryFlagImageView = cell.viewWithTag(6) as? UIImageView {
            if let flag = Flag(countryCode: event.country) {
                countryFlagImageView.image = flag.image(style: .roundedRect)
            } else {
                countryFlagImageView.image = nil
            }
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120 // Ajustez cette valeur selon vos besoins
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _ = events[indexPath.row]
        // Implémentez la logique pour afficher les détails de l'événement
        // Par exemple :
        // performSegue(withIdentifier: "showEventDetail", sender: event)
    }
}


