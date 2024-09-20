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
    var rounds: [String: [Round]] = [:]
    var selectedFight: Fight?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        tableView.clipsToBounds = false  // Empêche la coupure des ombres
        tableView.separatorStyle = .none
    

        print("FightListViewController viewDidLoad")
        print("TableView frame: \(tableView.frame)")
        print("TableView contentSize: \(tableView.contentSize)")
        print("Current user ID: \(Auth.auth().currentUser?.uid ?? "No user")")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("FightListViewController viewWillAppear")
        loadFightsAndRelatedData()
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "FightTableViewCell", bundle: nil), forCellReuseIdentifier: "FightCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear // ou la couleur de fond que vous préférez
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
    
    func loadFightsAndRelatedData() {
        loadFights { [weak self] in
            self?.loadFightersAndEvents()
            self?.loadRounds()
        }
    }
    func loadRounds() {
        for (index, fight) in fights.enumerated() {
            guard let fightId = fight.id, let roundIds = fight.roundIds, !roundIds.isEmpty else {
                print("No round IDs for fight: \(fight.id ?? "Unknown")")
                continue
            }

            print("Loading rounds for fight: \(fightId), Round IDs: \(roundIds)")

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

                // Vérifiez si l'index de ce combat est encore visible dans la tableView
                if let cell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FightTableViewCell {
                    cell.configureRoundLabels(for: loadedRounds, roundIds: roundIds)
                }

                // Rechargez toute la tableView pour s'assurer que tout est à jour.
                self?.tableView.reloadData()
            }
        }
    }

    func loadFights(completion: @escaping () -> Void) {
        print("Starting loadFights")
        FirebaseService.shared.getFights { [weak self] result in
            print("getFights completed")
            switch result {
            case .success(let fights):
                print("Loaded \(fights.count) fights")
                self?.fights = fights
                completion()
            case .failure(let error):
                print("Error loading fights: \(error.localizedDescription)")
                completion()
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
    


    
    @IBAction func addRoundButtonTapped(_ sender: UIButton) {
         guard let selectedIndexPath = tableView.indexPathForSelectedRow,
               let fight = fights[safe: selectedIndexPath.row] else {
             showAlert(title: "Error", message: "Please select a fight first")
             return
         }

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
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // Un seul section pour tous les combats
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fights.count // Nombre total de combats
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10 // Espace en haut de la première cellule
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10 // Espace en bas de la dernière cellule
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180 // Ajustez cette valeur selon vos besoins
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _ = fights[indexPath.row]
        // Implémentez la logique pour afficher les détails du combat
        // Par exemple :
        // performSegue(withIdentifier: "showFightDetail", sender: fight)
    }
}
