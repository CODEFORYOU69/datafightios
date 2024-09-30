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
        
        // Set table view background color
           tableView.backgroundColor = UIColor.systemBackground
           
           // Remove separator lines
           tableView.separatorStyle = .none
           
           // Add some padding to the table view
           tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
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
    }
    
    func setupNavigationBar() {
        navigationItem.title = "Events"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addEventTapped))
    }
    
    @objc func addEventTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let eventEditVC = storyboard.instantiateViewController(withIdentifier: "EventEditViewController") as? EventEditViewController {
            navigationController?.pushViewController(eventEditVC, animated: true)
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as? EventTableViewCell else {
            fatalError("Unable to dequeue EventTableViewCell")
        }
        let event = events[indexPath.row]
        cell.configure(with: event)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layer.masksToBounds = true
        let radius = cell.contentView.layer.cornerRadius
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: radius).cgPath
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = events[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "EventDetailViewController") as? EventDetailViewController {
            detailVC.event = event
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}


