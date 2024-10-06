import Firebase
import FirebaseAnalytics
import FlagKit
import SDWebImage
//  FighterListViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//
import UIKit

class FighterListViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties
    private var fighters: [Fighter] = []
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        // Log screen view
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "Fighter List"
            ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFighters()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(
            red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)  // Dark background
        setupTableView()
        setupNavigationBar()
        setupActivityIndicator()
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            UINib(nibName: "FighterTableViewCell", bundle: nil),
            forCellReuseIdentifier: "FighterCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = FighterTableViewCell.preferredHeight
        tableView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(
            top: 10, left: 0, bottom: 10, right: 0)
        tableView.tableFooterView = UIView()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self,
            action: #selector(addFighterTapped))
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
    }

    // MARK: - Data Loading
    private func loadFighters() {
        loadingView.isHidden = false
        activityIndicator.startAnimating()

        FirebaseService.shared.getFighters { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingView.isHidden = true
                self?.activityIndicator.stopAnimating()

                switch result {
                case .success(let fighters):
                    self?.fighters = fighters
                    self?.tableView.reloadData()

                    // Log successful fighters load
                    Analytics.logEvent(
                        "fighters_loaded",
                        parameters: [
                            "count": fighters.count as NSObject
                        ])

                case .failure(let error):
                    print(
                        "Error loading fighters: \(error.localizedDescription)")
                    self?.showAlert(
                        title: "Error",
                        message:
                            "Unable to load fighters: \(error.localizedDescription)"
                    )

                    // Log fighters load failure
                    Analytics.logEvent(
                        "fighters_load_failed",
                        parameters: [
                            "error": error.localizedDescription as NSObject
                        ])
                }
            }
        }
    }

    // MARK: - Actions
    @objc private func addFighterTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let fighterEditVC = storyboard.instantiateViewController(
            withIdentifier: "FighterEditViewController")
            as? FighterEditViewController
        {
            navigationController?.pushViewController(
                fighterEditVC, animated: true)
        }
    }

    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFighterDetail",
            let detailVC = segue.destination as? FighterDetailViewController,
            let indexPath = tableView.indexPathForSelectedRow
        {
            let selectedFighter = fighters[indexPath.row]
            detailVC.fighter = selectedFighter
        }
    }
}

// MARK: - UITableViewDataSource
extension FighterListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        return fighters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "FighterCell", for: indexPath)
                as? FighterTableViewCell
        else {
            return UITableViewCell()
        }
        let fighter = fighters[indexPath.row]
        cell.configure(with: fighter)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FighterListViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView, heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return FighterTableViewCell.preferredHeight
    }

    func tableView(
        _ tableView: UITableView, didSelectRowAt indexPath: IndexPath
    ) {
        performSegue(withIdentifier: "showFighterDetail", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
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
}
