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

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFighters()
    }
    
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
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
        activityIndicator.startAnimating()
        FirebaseService.shared.getFighters { [weak self] result in
            DispatchQueue.main.async {
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
        return FighterTableViewCell.preferredHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           let fighter = fighters[indexPath.row]
           showFighterDetails(fighter)
           tableView.deselectRow(at: indexPath, animated: true)
       }

       func showFighterDetails(_ fighter: Fighter) {
           let storyboard = UIStoryboard(name: "Main", bundle: nil)
           if let detailVC = storyboard.instantiateViewController(withIdentifier: "FighterDetailViewController") as? FighterDetailViewController {
               detailVC.fighter = fighter
               navigationController?.pushViewController(detailVC, animated: true)
           }
       }
}
