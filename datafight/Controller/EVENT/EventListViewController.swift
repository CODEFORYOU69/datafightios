import Firebase
import FlagKit
import SDWebImage
//
//  EventListViewController.swift
//  datafight
//
//  Created by younes ouasmi on 18/08/2024.
//
import UIKit

class EventListViewController: UIViewController, UITableViewDataSource,
    UITableViewDelegate
{

    @IBOutlet weak var tableView: UITableView!

    var events: [Event] = []

    @IBOutlet var contentView: UIView!

    // Activity indicator to show while loading data
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        setupActivityIndicator()

        // Set dark background color
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        tableView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)  // Dark background for table view

        // Remove separator lines
        tableView.separatorStyle = .none

        // Add padding to the table view
        tableView.contentInset = UIEdgeInsets(
            top: 10, left: 0, bottom: 10, right: 0)

        // Log screen view with Firebase Analytics
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "Event List"
            ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadEvents()
    }

    // MARK: - Setup Methods

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
    }

    func setupNavigationBar() {
        navigationItem.title = "Events"

        // Configure the navigation bar's background color to match the table view's background
        navigationController?.navigationBar.barTintColor = UIColor(
            white: 0.1, alpha: 1.0)  // Same dark background as table view

        // Configure the title text color
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]

        // Ensure the bar style is set for white text and icons
        navigationController?.navigationBar.barStyle = .black

        // Configure right bar button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self,
            action: #selector(addEventTapped))
        navigationItem.rightBarButtonItem?.tintColor = .white  // White color for the add button
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Data Loading

    private func loadEvents() {
        activityIndicator.startAnimating()
        FirebaseService.shared.getEvents { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                switch result {
                case .success(let events):
                    self?.events = events
                    self?.tableView.reloadData()

                    // Log event load success with Firebase Analytics
                    Analytics.logEvent(
                        "events_loaded",
                        parameters: [
                            "event_count": events.count as NSNumber
                        ])

                case .failure(let error):
                    print("Error loading events: \(error.localizedDescription)")
                    self?.showAlert(
                        title: "Error", message: "Unable to load events")

                    // Log event load failure with Firebase Analytics
                    Analytics.logEvent(
                        "events_load_failed",
                        parameters: [
                            "error": error.localizedDescription as NSObject
                        ])
                }
            }
        }
    }

    // MARK: - UI Actions

    @objc func addEventTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let eventEditVC = storyboard.instantiateViewController(
            withIdentifier: "EventEditViewController")
            as? EventEditViewController
        {
            navigationController?.pushViewController(
                eventEditVC, animated: true)
        }
    }

    // MARK: - Helper Methods

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UITableViewDataSource Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        return events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "EventCell", for: indexPath)
                as? EventTableViewCell
        else {
            fatalError("Unable to dequeue EventTableViewCell")
        }
        let event = events[indexPath.row]
        cell.configure(with: event)
        return cell
    }

    // MARK: - UITableViewDelegate Methods

    func tableView(
        _ tableView: UITableView, heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return 140
    }

    func tableView(
        _ tableView: UITableView, willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cell.contentView.layer.masksToBounds = true
        let radius = cell.contentView.layer.cornerRadius
        cell.layer.shadowPath =
            UIBezierPath(roundedRect: cell.bounds, cornerRadius: radius).cgPath
    }

    func tableView(
        _ tableView: UITableView, didSelectRowAt indexPath: IndexPath
    ) {
        let event = events[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(
            withIdentifier: "EventDetailViewController")
            as? EventDetailViewController
        {
            detailVC.event = event
            navigationController?.pushViewController(detailVC, animated: true)

            // Log event detail view with Firebase Analytics
            Analytics.logEvent(
                "event_detail_viewed",
                parameters: [
                    "event_id": event.id ?? "unknown_event_id" as NSObject
                ])
        }
    }
}
