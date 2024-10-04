import Firebase
import FirebaseAuth
import UIKit

class FightListViewController: UIViewController, UITableViewDataSource,
    UITableViewDelegate
{
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties
    var fights: [Fight] = []
    var fighters: [String: Fighter] = [:]
    var events: [String: Event] = [:]
    var rounds: [String: [Round]] = [:]
    var selectedFight: Fight?

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        setupActivityIndicator()
        applyNeonEffect(to: view)

        tableView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)  // Dark background

        // Log view controller appearance
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "Fight List"
            ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFightsAndRelatedData()
    }

    // MARK: - Setup Methods
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
    }

    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            UINib(nibName: "FightTableViewCell", bundle: nil),
            forCellReuseIdentifier: "FightCell")
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(
            top: 10, left: 0, bottom: 10, right: 0)
    }

    func setupNavigationBar() {
        navigationItem.title = "Fights"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self,
            action: #selector(addFightTapped))
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
    }

    private func applyNeonEffect(to view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.3).cgColor
        view.layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.3).cgColor
        view.layer.shadowRadius = 5.0
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
    // MARK: - Data Loading Methods
    func loadFightsAndRelatedData() {
        activityIndicator.startAnimating()

        loadFights { [weak self] in
            self?.loadFightersAndEvents()
            self?.loadRounds()
        }
    }

    func loadFights(completion: @escaping () -> Void) {
        FirebaseService.shared.getFights { [weak self] result in
            switch result {
            case .success(let fights):
                self?.fights = fights
                // Log number of fights loaded
                Analytics.logEvent(
                    "fights_loaded",
                    parameters: ["count": fights.count as NSNumber])
                completion()
            case .failure(let error):
                print("Error loading fights: \(error.localizedDescription)")
                self?.showAlert(
                    title: "Error",
                    message:
                        "Unable to load fights: \(error.localizedDescription)")
                completion()
            }
        }
    }

    func loadFightersAndEvents() {
        let fighterIds = Set(
            fights.flatMap { [$0.blueFighterId, $0.redFighterId] })
        let eventIds = Set(fights.map { $0.eventId })

        let group = DispatchGroup()

        for fighterId in fighterIds {
            group.enter()
            FirebaseService.shared.getFighter(id: fighterId) {
                [weak self] result in
                defer { group.leave() }
                switch result {
                case .success(let fighter):
                    self?.fighters[fighterId] = fighter
                case .failure(let error):
                    print(
                        "Error loading fighter \(fighterId): \(error.localizedDescription)"
                    )
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
                case .failure(let error):
                    print(
                        "Error loading event \(eventId): \(error.localizedDescription)"
                    )
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.tableView.reloadData()
            self?.activityIndicator.stopAnimating()
        }
    }

    func loadRounds() {
        let globalGroup = DispatchGroup()

        for fight in fights {
            guard let fightId = fight.id, let roundIds = fight.roundIds,
                !roundIds.isEmpty
            else {
                continue
            }

            globalGroup.enter()
            let group = DispatchGroup()
            var loadedRounds: [Round] = []

            for roundId in roundIds {
                group.enter()
                FirebaseService.shared.getRound(id: roundId, for: fight) {
                    result in
                    defer { group.leave() }
                    switch result {
                    case .success(let round):
                        loadedRounds.append(round)
                    case .failure(let error):
                        print(
                            "Failed to load round \(roundId) for fight \(fightId): \(error)"
                        )
                    }
                }
            }

            group.notify(queue: .main) { [weak self] in
                self?.rounds[fightId] = loadedRounds.sorted {
                    $0.roundNumber < $1.roundNumber
                }
                globalGroup.leave()
            }
        }

        globalGroup.notify(queue: .main) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    // MARK: - Action Methods
    @objc func addFightTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let fightEditVC = storyboard.instantiateViewController(
            withIdentifier: "FightEditViewController")
            as? FightEditViewController
        {
            let navController = UINavigationController(
                rootViewController: fightEditVC)
            present(navController, animated: true, completion: nil)

            // Log add fight action
            Analytics.logEvent("add_fight_tapped", parameters: nil)
        }
    }

    @IBAction func addRoundButtonTapped(_ sender: UIButton) {
        guard let selectedIndexPath = tableView.indexPathForSelectedRow,
            let fight = fights[safe: selectedIndexPath.row]
        else {
            showAlert(title: "Error", message: "Please select a fight first")
            return
        }

        // Log Firebase Analytics event for adding a round
        Analytics.logEvent(
            "add_round_tapped",
            parameters: [
                "fight_id": fight.id ?? "unknown_fight_id",
                "rounds_count": (fight.roundIds?.count ?? 0) as NSNumber,
            ])

        if let fightResult = fight.fightResult {
            showAlert(
                title: "Fight Completed",
                message:
                    "This fight has already ended with the following result:\nWinner: \(fightResult.winner)\nMethod: \(fightResult.method)"
            )
        } else if (fight.roundIds?.count ?? 0) >= 3 {
            showAlert(
                title: "Maximum Rounds Reached",
                message: "This fight already has the maximum number of rounds.")
        } else {
            selectedFight = fight
            performSegue(withIdentifier: "ShowAddRound", sender: nil)
        }
    }

    // MARK: - Helper Methods
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    func deleteFight(_ fight: Fight, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Delete Fight",
            message:
                "Are you sure you want to delete this fight? This action cannot be undone.",
            preferredStyle: .alert)

        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(
            UIAlertAction(
                title: "Delete", style: .destructive,
                handler: { [weak self] _ in
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

                    // Log fight deletion
                    Analytics.logEvent(
                        "fight_deleted",
                        parameters: [
                            "fight_id": fight.id ?? "unknown_fight_id"
                        ])
                }
            case .failure(let error):
                print("Failed to delete fight: \(error.localizedDescription)")
                self?.showAlert(
                    title: "Error",
                    message:
                        "Failed to delete fight: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowAddRound" {
            if let addRoundVC = segue.destination as? AddRoundViewController,
                let selectedIndexPath = tableView.indexPathForSelectedRow
            {
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
        return fights.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        return 1
    }
    func tableView(
        _ tableView: UITableView, heightForHeaderInSection section: Int
    ) -> CGFloat {
        return 10
    }

    func tableView(
        _ tableView: UITableView, viewForHeaderInSection section: Int
    ) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "FightCell", for: indexPath)
                as? FightTableViewCell
        else {
            return UITableViewCell()
        }

        let fight = fights[indexPath.section]

        if let blueFighter = fighters[fight.blueFighterId],
            let redFighter = fighters[fight.redFighterId],
            let event = events[fight.eventId]
        {

            let fightRounds = rounds[fight.id ?? ""] ?? []

            cell.configure(
                with: fight, blueFighter: blueFighter, redFighter: redFighter,
                event: event, rounds: fightRounds)

            cell.addRoundAction = { [weak self] in
                self?.addRoundForFight(fight)
            }
        } else {
            cell.configure(
                with: fight, blueFighter: nil, redFighter: nil, event: nil,
                rounds: [])
        }

        applyNeonEffect(to: cell.contentView)
        return cell
    }
    // MARK: - Helper Methods
    func addRoundForFight(_ fight: Fight) {
        // Check if the fight is already completed
        if let fightResult = fight.fightResult {
            showAlert(
                title: "Fight Completed",
                message:
                    "This fight has already ended with the following result:\nWinner: \(fightResult.winner)\nMethod: \(fightResult.method)"
            )
            return
        }

        // Check if the maximum number of rounds has been reached
        if (fight.roundIds?.count ?? 0) >= 3 {
            showAlert(
                title: "Maximum Rounds Reached",
                message: "This fight already has the maximum number of rounds.")
            return
        }

        // Initialize the AddRoundViewController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addRoundVC = storyboard.instantiateViewController(
            withIdentifier: "AddRoundViewController") as? AddRoundViewController
        {
            addRoundVC.fight = fight
            addRoundVC.blueFighter = fighters[fight.blueFighterId]
            addRoundVC.redFighter = fighters[fight.redFighterId]
            addRoundVC.event = events[fight.eventId]
            navigationController?.pushViewController(addRoundVC, animated: true)

            // Log Firebase Analytics event for adding a round
            Analytics.logEvent(
                "add_round_initiated",
                parameters: [
                    "fight_id": fight.id ?? "unknown_fight_id",
                    "current_rounds_count": (fight.roundIds?.count ?? 0)
                        as NSNumber,
                ])
        }
    }

    // MARK: - UITableViewDelegate
    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            let fight = fights[indexPath.row]
            deleteFight(fight, at: indexPath)
        }
    }

    func tableView(
        _ tableView: UITableView, heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return 160
    }

    func tableView(
        _ tableView: UITableView, didSelectRowAt indexPath: IndexPath
    ) {
        let fight = fights[indexPath.section]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(
            withIdentifier: "FightDetailViewController")
            as? FightDetailViewController
        {
            detailVC.fight = fight
            detailVC.rounds = rounds[fight.id ?? ""] ?? []
            detailVC.fightResult = fight.fightResult
            detailVC.blueFighter = fighters[fight.blueFighterId]
            detailVC.redFighter = fighters[fight.redFighterId]

            detailVC.modalPresentationStyle = .fullScreen
            present(detailVC, animated: true, completion: nil)

            // Log fight detail view
            Analytics.logEvent(
                "view_fight_detail",
                parameters: [
                    "fight_id": fight.id ?? "unknown_fight_id"
                ])
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
