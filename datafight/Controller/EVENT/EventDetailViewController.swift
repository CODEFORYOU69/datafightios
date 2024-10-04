//
//  EventDetailViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import FlagKit
import SDWebImage
import UIKit

class EventDetailViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventTypeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
    @IBOutlet weak var fightsCollectionView: UICollectionView!

    // MARK: - Properties
    var event: Event?
    var fights: [Fight] = []
    var fighters: [String: Fighter] = [:]
    var rounds: [String: [Round]] = [:]
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        loadFights()

        // Set dark background color
        view.backgroundColor = UIColor(
            red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
    }

    // MARK: - Setup Methods
    func setupCollectionView() {
        fightsCollectionView.delegate = self
        fightsCollectionView.dataSource = self
        fightsCollectionView.register(
            FightCollectionViewCell.self,
            forCellWithReuseIdentifier: "FightsCell")

        // Apply rounded corners and dark background to the collection view
        fightsCollectionView.layer.cornerRadius = 15
        fightsCollectionView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        fightsCollectionView.setCollectionViewLayout(layout, animated: false)
    }

    // MARK: - Data Loading
    func loadFights() {
        guard let eventId = event?.id else { return }
        
        FirebaseService.shared.getFightsForEvent(eventId: eventId) { [weak self] result in
            switch result {
            case .success(let fights):
                self?.fights = fights
                self?.loadFightersForFights(fights)
                self?.loadRounds() // Ajoutez cet appel ici
            case .failure(let error):
                print("Failed to load fights: \(error.localizedDescription)")
            }
        }
    }

    func loadFightersForFights(_ fights: [Fight]) {
        let fighterIds = Set(fights.flatMap { [$0.blueFighterId, $0.redFighterId] })
        let group = DispatchGroup()
        var fighters: [String: Fighter] = [:]
        
        for fighterId in fighterIds {
            group.enter()
            FirebaseService.shared.getFighter(id: fighterId) { result in
                defer { group.leave() }
                switch result {
                case .success(let fighter):
                    fighters[fighterId] = fighter
                case .failure(let error):
                    print("Failed to load fighter \(fighterId): \(error.localizedDescription)")
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.fighters = fighters
            self?.fightsCollectionView.reloadData()
        }
    }
    func loadRounds() {
        let globalGroup = DispatchGroup()

        for fight in fights {
            guard let fightId = fight.id else {
                continue
            }

            globalGroup.enter()
            FirebaseService.shared.getAllRoundsForFight(fight) { [weak self] result in
                defer { globalGroup.leave() }
                switch result {
                case .success(let loadedRounds):
                    self?.rounds[fightId] = loadedRounds.sorted { $0.roundNumber < $1.roundNumber }
                    print("Loaded \(loadedRounds.count) rounds for fight \(fightId)")
                case .failure(let error):
                    print("Failed to load rounds for fight \(fightId): \(error)")
                }
            }
        }

        globalGroup.notify(queue: .main) { [weak self] in
            self?.fightsCollectionView.reloadData()
        }
    }
    // MARK: - UI Setup
    func setupUI() {
        guard let event = event else { return }

        setupContentView()
        setupEventImage()
        setupLabels()
        populateData(with: event)
        setupCountryFlag(for: event.country)
        addParallaxEffect()
    }

    func setupContentView() {
        contentView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        contentView.layer.cornerRadius = 20
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 5)
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowRadius = 10
    }

    func setupEventImage() {
        eventImageView.layer.cornerRadius = 15
        eventImageView.clipsToBounds = true
        eventImageView.contentMode = .scaleAspectFill
    }

    func setupLabels() {
        // White text color for contrast on dark background
        eventNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        eventNameLabel.textColor = .white

        eventTypeLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        eventTypeLabel.textColor = .lightGray

        // Apply white text color for other labels
        [locationLabel, dateLabel, countryLabel].forEach { label in
            label?.font = UIFont.systemFont(ofSize: 16)
            label?.textColor = .white
        }
    }

    func populateData(with event: Event) {
        eventNameLabel.text = event.eventName
        eventTypeLabel.text = event.eventType.rawValue
        locationLabel.text = "📍 \(event.location)"
        countryLabel.text = "🌎 \(event.country)"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateLabel.text = "📅 \(dateFormatter.string(from: event.date))"

        if let imageUrlString = event.imageURL,
            let imageUrl = URL(string: imageUrlString)
        {
            eventImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "placeholder_event"))
        } else {
            eventImageView.image = UIImage(named: "placeholder_event")
        }
    }

    func setupCountryFlag(for countryCode: String) {
        if let flag = Flag(countryCode: countryCode) {
            countryFlagImageView.image = flag.image(style: .roundedRect)
        } else {
            countryFlagImageView.image = nil
        }
        countryFlagImageView.layer.cornerRadius = 5
        countryFlagImageView.layer.masksToBounds = true
        countryFlagImageView.layer.borderWidth = 1
        countryFlagImageView.layer.borderColor = UIColor.lightGray.cgColor
    }

    func addParallaxEffect() {
        let amount: CGFloat = 20

        let horizontalMotionEffect = UIInterpolatingMotionEffect(
            keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -amount
        horizontalMotionEffect.maximumRelativeValue = amount

        let verticalMotionEffect = UIInterpolatingMotionEffect(
            keyPath: "center.y", type: .tiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -amount
        verticalMotionEffect.maximumRelativeValue = amount

        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [
            horizontalMotionEffect, verticalMotionEffect,
        ]
        contentView.addMotionEffect(motionEffectGroup)
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension EventDetailViewController: UICollectionViewDelegate,
    UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(
        _ collectionView: UICollectionView, numberOfItemsInSection section: Int
    ) -> Int {
        return fights.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FightsCell", for: indexPath) as! FightCollectionViewCell
        let fight = fights[indexPath.item]
        
        let blueFighterName = fighters[fight.blueFighterId]?.fullName ?? "Unknown Blue"
        let redFighterName = fighters[fight.redFighterId]?.fullName ?? "Unknown Red"
        
        cell.configure(with: fight, blueFighterName: blueFighterName, redFighterName: redFighterName)
        
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = (collectionView.bounds.width - 30) / 2  // Two columns with spacing
        return CGSize(width: width, height: 120)
    }

    func collectionView(
        _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath
    ) {
        let selectedFight = fights[indexPath.item]
        presentFightDetailViewController(for: selectedFight)
    }

    func presentFightDetailViewController(for fight: Fight) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "FightDetailViewController") as? FightDetailViewController {
            detailVC.fight = fight
            detailVC.rounds = rounds[fight.id ?? ""] ?? []
            detailVC.fightResult = fight.fightResult
            detailVC.blueFighter = fighters[fight.blueFighterId]
            detailVC.redFighter = fighters[fight.redFighterId]
            
            detailVC.modalPresentationStyle = .fullScreen
            present(detailVC, animated: true, completion: nil)
            
           
        }
    }
}

// MARK: - FightCollectionViewCell
class FightCollectionViewCell: UICollectionViewCell {
    private let fighterNamesLabel = UILabel()
    private let categoryLabel = UILabel()
    private let fightNumberLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        // Cell styling for dark mode with rounded corners
        contentView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        contentView.layer.cornerRadius = 10
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowOpacity = 0.3

        // Labels styling with white text for contrast
        fighterNamesLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        fighterNamesLabel.textColor = .white

        categoryLabel.font = UIFont.systemFont(ofSize: 12)
        categoryLabel.textColor = .lightGray

        fightNumberLabel.font = UIFont.systemFont(ofSize: 12)
        fightNumberLabel.textColor = .lightGray

        // Add labels to content view
        [fighterNamesLabel, categoryLabel, fightNumberLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        // Constraints for labels
        NSLayoutConstraint.activate([
            fighterNamesLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor, constant: 8),
            fighterNamesLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 8),
            fighterNamesLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -8),

            categoryLabel.topAnchor.constraint(
                equalTo: fighterNamesLabel.bottomAnchor, constant: 4),
            categoryLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 8),
            categoryLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -8),

            fightNumberLabel.topAnchor.constraint(
                equalTo: categoryLabel.bottomAnchor, constant: 4),
            fightNumberLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 8),
            fightNumberLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -8),
            fightNumberLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    func configure(
        with fight: Fight, blueFighterName: String, redFighterName: String
    ) {
        fighterNamesLabel.text = "\(blueFighterName) vs \(redFighterName)"
        categoryLabel.text = "\(fight.category) - \(fight.weightCategory)"
        fightNumberLabel.text = "Fight \(fight.fightNumber)"
    }
}
