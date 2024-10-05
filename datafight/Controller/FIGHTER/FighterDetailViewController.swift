//
//  FighterDetailViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import FirebaseAnalytics
import FlagKit
import SDWebImage
import UIKit

class FighterDetailViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var birthdateLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var flagImageView: UIImageView!
    @IBOutlet weak var detailsView: UIView!

    @IBOutlet weak var statsView: UIView!
    @IBOutlet weak var viewIn: UIView!

    @IBOutlet weak var totalCompetitionsLabel: UILabel!

    @IBOutlet weak var totalFightsLabel: UILabel!

    @IBOutlet weak var totalWinsLabel: UILabel!
    @IBOutlet weak var winPercentageLabel: UILabel!
    @IBOutlet weak var goldMedalsLabel: UILabel!

    @IBOutlet weak var silverMedalsLabel: UILabel!
    @IBOutlet weak var bronzeMedalsLabel: UILabel!

    @IBOutlet weak var medalCompetitionsTableView: UITableView!
    var fighter: Fighter?
    private var fighterStats: FighterCompleteStats?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackground()
        setupUI()
        setupNavigationBar()
        addSwipeGesture()
        loadFighterStats()

        medalCompetitionsTableView.dataSource = self
        medalCompetitionsTableView.delegate = self
        medalCompetitionsTableView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        medalCompetitionsTableView.separatorStyle = .none
            medalCompetitionsTableView.layer.cornerRadius = 20
            medalCompetitionsTableView.layer.shadowColor = UIColor.systemBlue.cgColor
            medalCompetitionsTableView.layer.shadowOffset = CGSize(width: 0, height: 5)
            medalCompetitionsTableView.layer.shadowRadius = 10
            medalCompetitionsTableView.layer.shadowOpacity = 0.8
            medalCompetitionsTableView.clipsToBounds = true
       
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [AnalyticsParameterScreenName: "Fighter Detail"]
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("medalCompetitionsTableView frame: \(medalCompetitionsTableView.frame)")
        print("medalCompetitionsTableView isHidden: \(medalCompetitionsTableView.isHidden)")
    }

    // MARK: - Setup Background
    private func setupBackground() {
        view.backgroundColor = UIColor(
            red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)

        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.image = UIImage(named: "fighterbackground.jpeg")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.2
        view.insertSubview(backgroundImageView, at: 0)
    }

    // MARK: - Setup Navigation Bar
    private func setupNavigationBar() {
        navigationController?.navigationBar.barTintColor = UIColor(
            red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        navigationController?.navigationBar.tintColor = .white
        navigationItem.title =
            "\(fighter?.firstName ?? "") \(fighter?.lastName ?? "")"
    }

    // MARK: - Setup UI
    private func setupUI() {
        guard let fighter = fighter else { return }

        styleDetailsView()
        styleProfileImage()
        styleFighterInfo()

        nameLabel.text = "\(fighter.firstName) \(fighter.lastName)"
        genderLabel.text = "Gender: \(fighter.gender)"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        birthdateLabel.text =
            "Birthdate: \(fighter.birthdate.map { dateFormatter.string(from: $0) } ?? "Unknown")"

        countryLabel.text = "Country: \(fighter.country)"

        if let imageUrlString = fighter.profileImageURL,
            let imageUrl = URL(string: imageUrlString)
        {
            profileImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "placeholder_profile"))
        } else {
            profileImageView.image = UIImage(named: "placeholder_profile")
        }

        if let flag = Flag(countryCode: fighter.country) {
            flagImageView.image = flag.image(style: .roundedRect)
        } else {
            flagImageView.image = nil
        }
    }

    private func styleDetailsView() {

        viewIn.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        detailsView.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        detailsView.layer.cornerRadius = 20
        detailsView.layer.shadowColor = UIColor.systemBlue.cgColor
        detailsView.layer.shadowOffset = CGSize(width: 0, height: 5)
        detailsView.layer.shadowRadius = 10
        detailsView.layer.shadowOpacity = 0.8
    }

    private func styleProfileImage() {
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.layer.borderWidth = 4
        profileImageView.layer.borderColor =
            UIColor.systemBlue.withAlphaComponent(0.7).cgColor
        profileImageView.clipsToBounds = true
    }

    private func styleFighterInfo() {
        [nameLabel, genderLabel, birthdateLabel, countryLabel].forEach {
            label in
            label?.textColor = .white
            label?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label?.shadowColor = .black
            label?.shadowOffset = CGSize(width: 1, height: 1)
            applyNeonEffect(to: label!)
        }
    }

    private func applyNeonEffect(to view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor
        view.layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor
        view.layer.shadowRadius = 5.0
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.cornerRadius = 10.0

        if let label = view as? UILabel {
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.addPadding(left: 8, right: 8, top: 4, bottom: 4)
        }
    }

    private func loadFighterStats() {
        guard let fighterId = fighter?.id else {
            print("Fighter ID is nil")

            return }

        Task {
            do {
                let stats = try await FirebaseService.shared.getFighterCompleteStatsAsync(fighterId: fighterId)
                print("Received stats: \(stats)")

                await MainActor.run {
                    self.fighterStats = stats
                    updateStatsUI()
                    medalCompetitionsTableView.reloadData()
                    print("Medal competitions count: \(stats.medalCompetitions.count)")
                    print("TableView reloaded with \(fighterStats?.medalCompetitions.count ?? 0) items")



                }
            } catch {
                print(
                    "Error loading fighter stats: \(error.localizedDescription)"
                )
            }
        }
    }
    private func updateStatsUI() {
        guard let stats = fighterStats else { return }

        totalCompetitionsLabel.text =
            "Total Competitions: \(stats.totalCompetitions)"
        totalFightsLabel.text = "Total Fights: \(stats.totalFights)"
        totalWinsLabel.text = "Total Wins: \(stats.totalWins)"
        winPercentageLabel.text = String(
            format: "Win Percentage: %.1f%%", stats.winPercentage)
        goldMedalsLabel.text = "Gold Medals: \(stats.goldMedals)"
        silverMedalsLabel.text = "Silver Medals: \(stats.silverMedals)"
        bronzeMedalsLabel.text = "Bronze Medals: \(stats.bronzeMedals)"
    }
    // MARK: - Swipe Gesture
    private func addSwipeGesture() {
        let swipeDown = UISwipeGestureRecognizer(
            target: self, action: #selector(respondToSwipeGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
    }

    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer,
            swipeGesture.direction == .down
        {
            navigationController?.popViewController(animated: true)
            Analytics.logEvent("fighter_detail_swiped_down", parameters: nil)
        }
    }
}

// MARK: - Extension for UILabel padding
extension UILabel {
    func addPadding(
        left: CGFloat = 8, right: CGFloat = 8, top: CGFloat = 4,
        bottom: CGFloat = 4
    ) {
        let insets = UIEdgeInsets(
            top: top, left: left, bottom: bottom, right: right)
        self.frame = self.frame.inset(by: insets)
    }
}
extension FighterDetailViewController: UITableViewDataSource,UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = fighterStats?.medalCompetitions.count ?? 0
        print("numberOfRowsInSection called, returning \(count)")
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAt called for index \(indexPath.row)")
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MedalCompetitionCell", for: indexPath) as? MedalCompetitionCell else {
            print("Failed to dequeue MedalCompetitionCell")
            return UITableViewCell()
        }
        
        guard let competition = fighterStats?.medalCompetitions[indexPath.row] else {
            print("No competition data for index \(indexPath.row)")
            return cell
        }

        cell.configure(with: competition)
        print("Cell configured: \(cell.competitionNameLabel?.text ?? "No name"), \(cell.fightCountLabel?.text ?? "No count")")
        
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
           return 60
       }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 2
    }
       func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
           cell.contentView.layer.masksToBounds = true
           let radius = cell.contentView.layer.cornerRadius
           cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: radius).cgPath
       }
}
