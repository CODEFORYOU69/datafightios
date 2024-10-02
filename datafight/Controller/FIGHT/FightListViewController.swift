//
//  FightListViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import UIKit
import FirebaseAuth
import Firebase


class FightListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var fights: [Fight] = []
    var fighters: [String: Fighter] = [:]
    var events: [String: Event] = [:]
    var rounds: [String: [Round]] = [:]
    var selectedFight: Fight?

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        setupActivityIndicator()
        
        // Set table view background color
        tableView.backgroundColor = UIColor.systemBackground
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFightsAndRelatedData()
    }
    
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "FightTableViewCell", bundle: nil), forCellReuseIdentifier: "FightCell")
        tableView.separatorStyle = .none
            tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
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
    
    func loadFightsAndRelatedData() {
        activityIndicator.startAnimating()

        loadFights { [weak self] in
            self?.loadFightersAndEvents()
            self?.loadRounds()
        }
    }
    func loadRounds() {
        let globalGroup = DispatchGroup()
        
        for (_, fight) in fights.enumerated() {
            guard let fightId = fight.id, let roundIds = fight.roundIds, !roundIds.isEmpty else {
                print("No round IDs for fight: \(fight.id ?? "Unknown")")
                continue
            }

            print("Loading rounds for fight: \(fightId), Round IDs: \(roundIds)")

            globalGroup.enter()
            let group = DispatchGroup()
            var loadedRounds: [Round] = []

            for roundId in roundIds {
                group.enter()
                FirebaseService.shared.getRound(id: roundId, for: fight) { result in
                    defer { group.leave() }
                    switch result {
                    case .success(let round):
                        loadedRounds.append(round)
                        print("Loaded round: \(roundId) for fight: \(fightId)")
                    case .failure(let error):
                        print("Failed to load round \(roundId) for fight \(fightId): \(error)")
                    }
                }
            }

            group.notify(queue: .main) { [weak self] in
                self?.rounds[fightId] = loadedRounds.sorted { $0.roundNumber < $1.roundNumber }
                print("Finished loading rounds for fight: \(fightId), Loaded rounds: \(loadedRounds.count)")
                globalGroup.leave()
            }
        }
        
        globalGroup.notify(queue: .main) { [weak self] in
            self?.tableView.reloadData()
            print("All rounds loaded, reloading table view")
        }
    }

    func loadFights(completion: @escaping () -> Void) {
        FirebaseService.shared.getFights { [weak self] result in
            switch result {
            case .success(let fights):
                self?.fights = fights
                completion()
            case .failure(let error):
                print("Error loading fights: \(error.localizedDescription)")
                self?.showAlert(title: "Error", message: "Unable to load fights: \(error.localizedDescription)")

                completion()
            }
        }
    }

    func loadFightersAndEvents() {
        let fighterIds = Set(fights.flatMap { [$0.blueFighterId, $0.redFighterId] })
        let eventIds = Set(fights.map { $0.eventId })
        

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
            self?.activityIndicator.stopAnimating()

        }
    }
    


    
    @IBAction func addRoundButtonTapped(_ sender: UIButton) {
         guard let selectedIndexPath = tableView.indexPathForSelectedRow,
               let fight = fights[safe: selectedIndexPath.row] else {
             showAlert(title: "Error", message: "Please select a fight first")
             return
         }
        // Log Firebase Analytics event for adding a round
            Analytics.logEvent("add_round", parameters: [
                "fight_id": fight.id ?? "unknown_fight_id",
                "rounds_count": (fight.roundIds?.count ?? 0) as NSObject
            ])
        if let fightResult = fight.fightResult {
             // Le combat est déjà terminé
             showAlert(title: "Fight Completed", message: "This fight has already ended with the following result:\nWinner: \(fightResult.winner)\nMethod: \(fightResult.method)")
         } else if (fight.roundIds?.count ?? 0) >= 3 {
             // Le combat a déjà 3 rounds, ce qui est généralement le maximum
             showAlert(title: "Maximum Rounds Reached", message: "This fight already has the maximum number of rounds.")
         } else {
             // Le combat n'est pas terminé et n'a pas atteint le nombre maximum de rounds
             selectedFight = fight
             performSegue(withIdentifier: "ShowAddRound", sender: nil)
         }
     }
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowAddRound" {
            if let addRoundVC = segue.destination as? AddRoundViewController,
               let selectedIndexPath = tableView.indexPathForSelectedRow {
                let selectedFight = fights[selectedIndexPath.row]
                addRoundVC.fight = selectedFight
                addRoundVC.blueFighter = fighters[selectedFight.blueFighterId]
                addRoundVC.redFighter = fighters[selectedFight.redFighterId]
                addRoundVC.event = events[selectedFight.eventId]
            }
        }
    }
    func deleteFight(_ fight: Fight, at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete Fight", message: "Are you sure you want to delete this fight? This action cannot be undone.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.performDeletion(of: fight, at: indexPath)
        }))
        
        present(alert, animated: true)
    }

    func performDeletion(of fight: Fight, at indexPath: IndexPath) {
        FirebaseService.shared.deleteFight(fight) { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.fights.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            case .failure(let error):
                print("Failed to delete fight: \(error.localizedDescription)")
                self?.showAlert(title: "Error", message: "Failed to delete fight: \(error.localizedDescription)")
            }
        }
    }
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // Un seul section pour tous les combats
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fights.count // Nombre total de combats
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20 // Espace en haut de la première cellule
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20 // Espace en bas de la dernière cellule
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        return footerView
    }

       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Essayer de déballer la cellule en tant que FightTableViewCell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FightCell", for: indexPath) as? FightTableViewCell else {
            // Retourner une cellule vide par défaut si le déballage échoue
            return UITableViewCell()
        }

        // Récupérer le combat correspondant à l'index actuel
        let fight = fights[indexPath.row]

        // Vérifier si les combattants et l'événement existent
        if let blueFighter = fighters[fight.blueFighterId],
           let redFighter = fighters[fight.redFighterId],
           let event = events[fight.eventId] {

            // Récupérer les rounds associés au combat
            let fightRounds = rounds[fight.id ?? ""] ?? []

            // Configurer la cellule avec les données récupérées
            cell.configure(with: fight, blueFighter: blueFighter, redFighter: redFighter, event: event, rounds: fightRounds)

            // Ajouter une action pour le bouton "Add Round"
            cell.addRoundAction = { [weak self] in
                self?.addRoundForFight(fight)
            }
        } else {
            // Si les données ne sont pas disponibles, configurer la cellule avec des valeurs par défaut
            cell.configure(with: fight, blueFighter: nil, redFighter: nil, event: nil, rounds: [])
        }

        return cell
    }
    func addRoundForFight(_ fight: Fight) {
        
        if let fightResult = fight.fightResult {
                showAlert(title: "Fight Completed", message: "This fight has already ended with the following result:\nWinner: \(fightResult.winner)\nMethod: \(fightResult.method)")
                return
            }

            // Vérification pour s'assurer qu'il y a moins de 3 rounds
            if (fight.roundIds?.count ?? 0) >= 3 {
                showAlert(title: "Maximum Rounds Reached", message: "This fight already has the maximum number of rounds.")
                return
            }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addRoundVC = storyboard.instantiateViewController(withIdentifier: "AddRoundViewController") as? AddRoundViewController {
            addRoundVC.fight = fight
            addRoundVC.blueFighter = fighters[fight.blueFighterId]
            addRoundVC.redFighter = fighters[fight.redFighterId]
            addRoundVC.event = events[fight.eventId]
            navigationController?.pushViewController(addRoundVC, animated: true)
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let fight = fights[indexPath.row]
            deleteFight(fight, at: indexPath)
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140 // Ajustez cette valeur selon vos besoins
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fight = fights[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "FightDetailViewController") as? FightDetailViewController {
            detailVC.fight = fight
            detailVC.rounds = rounds[fight.id ?? ""] ?? []
            detailVC.fightResult = fight.fightResult
            detailVC.blueFighter = fighters[fight.blueFighterId]
            detailVC.redFighter = fighters[fight.redFighterId]
            
            // Présenter le contrôleur de vue modalement
            detailVC.modalPresentationStyle = .fullScreen
            present(detailVC, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
