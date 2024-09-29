//
//  FighterListViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//


import UIKit
import Firebase
import SDWebImage
import FlagKit

class FighterListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var fighters: [Fighter] = []
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupNavigationBar()
        setupActivityIndicator()
        tableView.tableFooterView = UIView()
        
        // Set table view background color
            tableView.backgroundColor = UIColor.systemBackground
            
            // Remove separator lines
            tableView.separatorStyle = .none
            
            // Add some padding to the table view
            tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFighters()
    }
    
    private func setupActivityIndicator() {
        view.addSubview(loadingView)
        loadingView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        loadingView.isHidden = true
    }
    
    func setupTableView() {
        tableView.dataSource = self
          tableView.delegate = self
          tableView.register(UINib(nibName: "FighterTableViewCell", bundle: nil), forCellReuseIdentifier: "FighterCell")
          tableView.rowHeight = UITableView.automaticDimension
          tableView.estimatedRowHeight = FighterTableViewCell.preferredHeight
    }

    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFighterTapped))
    }

    @objc func addFighterTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let fighterEditVC = storyboard.instantiateViewController(withIdentifier: "FighterEditViewController") as? FighterEditViewController {
            let navController = UINavigationController(rootViewController: fighterEditVC)
            present(navController, animated: true, completion: nil)
        }
    }

    func loadFighters() {
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
                case .failure(let error):
                    print("Error loading fighters: \(error.localizedDescription)")
                    self?.showAlert(title: "Error", message: "Unable to load fighters: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private let loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fighters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FighterCell", for: indexPath) as? FighterTableViewCell else {
            return UITableViewCell()
        }
        let fighter = fighters[indexPath.row]
        cell.configure(with: fighter)
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FighterTableViewCell.preferredHeight + 20 // Add 20 points for spacing
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           let fighter = fighters[indexPath.row]
           showFighterDetails(fighter)
           tableView.deselectRow(at: indexPath, animated: true)
       }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layer.masksToBounds = true
        let radius = cell.contentView.layer.cornerRadius
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: radius).cgPath
    }
       func showFighterDetails(_ fighter: Fighter) {
           let storyboard = UIStoryboard(name: "Main", bundle: nil)
           if let detailVC = storyboard.instantiateViewController(withIdentifier: "FighterDetailViewController") as? FighterDetailViewController {
               detailVC.fighter = fighter
               navigationController?.pushViewController(detailVC, animated: true)
           }
       }
}
