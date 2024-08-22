//
//  FightListViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import UIKit
import FirebaseAuth

class FightListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var fights: [Fight] = []
    var fighters: [String: Fighter] = [:]
    var events: [String: Event] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        print("FightListViewController viewDidLoad")

        print("TableView frame: \(tableView.frame)")
         print("TableView contentSize: \(tableView.contentSize)")
        print("Current user ID: \(Auth.auth().currentUser?.uid ?? "No user")")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("FightListViewController viewWillAppear")

        loadFights()
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UINib(nibName: "FightTableViewCell", bundle: nil), forCellReuseIdentifier: "FightCell")
        print("TableView setup complete")

    }
    
    func setupNavigationBar() {
        navigationItem.title = "Fights"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFightTapped))
    }
    
    @objc func addFightTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let fightEditVC = storyboard.instantiateViewController(withIdentifier: "FightEditViewController") as? FightEditViewController {
            let navController = UINavigationController(rootViewController: fightEditVC)
            present(navController, animated: true, completion: nil)
        }
    }
    
    func loadFights() {
        print("Starting loadFights")
        FirebaseService.shared.getFights { [weak self] result in
            print("getFights completed")
            switch result {
            case .success(let fights):
                print("Loaded \(fights.count) fights")
                self?.fights = fights
                self?.loadFightersAndEvents()
            case .failure(let error):
                print("Error loading fights: \(error.localizedDescription)")
            }
        }
    }

    func loadFightersAndEvents() {
        let fighterIds = Set(fights.flatMap { [$0.blueFighterId, $0.redFighterId] })
        let eventIds = Set(fights.map { $0.eventId })
        
        print("Loading \(fighterIds.count) fighters and \(eventIds.count) events")
        
        let group = DispatchGroup()
        
        for fighterId in fighterIds {
            group.enter()
            FirebaseService.shared.getFighter(id: fighterId) { [weak self] result in
                defer { group.leave() }
                switch result {
                case .success(let fighter):
                    self?.fighters[fighterId] = fighter
                    print("Loaded fighter: \(fighter.firstName) \(fighter.lastName)")
                case .failure(let error):
                    print("Error loading fighter \(fighterId): \(error.localizedDescription)")
                }
            }
        }
        
        for eventId in eventIds {
            group.enter()
            FirebaseService.shared.getEvent(id: eventId) { [weak self] result in
                defer { group.leave() }
                switch result {
                case .success(let event):
                    self?.events[eventId] = event
                    print("Loaded event: \(event.eventName)")
                case .failure(let error):
                    print("Error loading event \(eventId): \(error.localizedDescription)")
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            print("Finished loading fighters and events")
            print("Fighters loaded: \(self?.fighters.count ?? 0)")
            print("Events loaded: \(self?.events.count ?? 0)")
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberOfRowsInSection called, returning \(fights.count)")

        return fights.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAt called for row \(indexPath.row)")
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FightCell", for: indexPath) as? FightTableViewCell else {
            print("Failed to dequeue FightTableViewCell")
            return UITableViewCell()
        }
        
        let fight = fights[indexPath.row]
        if let blueFighter = fighters[fight.blueFighterId],
           let redFighter = fighters[fight.redFighterId],
           let event = events[fight.eventId] {
            cell.configure(with: fight, blueFighter: blueFighter, redFighter: redFighter, event: event)
        } 
        
        return cell
    }
    
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120 // Ajustez cette valeur selon vos besoins
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fight = fights[indexPath.row]
        // Implémentez la logique pour afficher les détails du combat
        // Par exemple :
        // performSegue(withIdentifier: "showFightDetail", sender: fight)
    }
}
