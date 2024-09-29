//
//  EventDetailViewController.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import UIKit
import SDWebImage
import FlagKit

class EventDetailViewController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventTypeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
    @IBOutlet weak var fightsCollectionView: UICollectionView!

    
    var event: Event?
    var fights: [Fight] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        loadFights()
    }
    func setupCollectionView() {
        fightsCollectionView.delegate = self
        fightsCollectionView.dataSource = self
        fightsCollectionView.register(FightCollectionViewCell.self, forCellWithReuseIdentifier: "FightsCell")
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        fightsCollectionView.setCollectionViewLayout(layout, animated: false)
    }
    
    func loadFights() {
        guard let eventId = event?.id else { return }
        
        FirebaseService.shared.getFightsForEvent(eventId: eventId) { [weak self] result in
            switch result {
            case .success(let fights):
                self?.fights = fights
                DispatchQueue.main.async {
                    self?.fightsCollectionView.reloadData()
                }
            case .failure(let error):
                print("Failed to load fights: \(error.localizedDescription)")
            }
        }
    }
    
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
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 20
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 5)
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowRadius = 10
    }
    
    func setupEventImage() {
        eventImageView.layer.cornerRadius = 15
        eventImageView.clipsToBounds = true
        eventImageView.contentMode = .scaleAspectFill
    }
    
    func setupLabels() {
        eventNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        eventNameLabel.textColor = .darkText
        
        eventTypeLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        eventTypeLabel.textColor = .systemBlue
        
        [locationLabel, dateLabel, countryLabel].forEach { label in
            label?.font = UIFont.systemFont(ofSize: 16)
            label?.textColor = .darkGray
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
        
        if let imageUrlString = event.imageURL, let imageUrl = URL(string: imageUrlString) {
            eventImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_event"))
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
        
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -amount
        horizontalMotionEffect.maximumRelativeValue = amount

        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -amount
        verticalMotionEffect.maximumRelativeValue = amount

        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        contentView.addMotionEffect(motionEffectGroup)
    }
}
extension EventDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fights.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FightsCell", for: indexPath) as! FightCollectionViewCell
        let fight = fights[indexPath.item]
        
        // Configuration initiale avec les IDs (en attendant les noms)
        cell.configure(with: fight, blueFighterName: fight.blueFighterId, redFighterName: fight.redFighterId)
        
        // Récupération asynchrone des noms des combattants
        loadFighterNames(for: fight) { [weak self] blueName, redName in
            DispatchQueue.main.async {
                // Vérifier si la cellule est toujours visible
                if let visibleCell = self?.fightsCollectionView.cellForItem(at: indexPath) as? FightCollectionViewCell {
                    visibleCell.configure(with: fight, blueFighterName: blueName, redFighterName: redName)
                }
            }
        }
        
        return cell
    }
    private func loadFighterNames(for fight: Fight, completion: @escaping (String, String) -> Void) {
        let group = DispatchGroup()
        var blueName = ""
        var redName = ""
        
        group.enter()
        FirebaseService.shared.getFighter(id: fight.blueFighterId) { result in
            if case .success(let fighter) = result {
                blueName = "\(fighter.firstName) \(fighter.lastName)"
            }
            group.leave()
        }
        
        group.enter()
        FirebaseService.shared.getFighter(id: fight.redFighterId) { result in
            if case .success(let fighter) = result {
                redName = "\(fighter.firstName) \(fighter.lastName)"
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(blueName, redName)
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 30) / 2 // 2 colonnes avec un espace de 10 entre elles
        return CGSize(width: width, height: 120)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedFight = fights[indexPath.item]
        presentFightResultViewController(for: selectedFight)
    }
    
    func presentFightResultViewController(for fight: Fight) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let fightResultVC = storyboard.instantiateViewController(withIdentifier: "FightDetailViewController") as? FightDetailViewController {
            fightResultVC.fight = fight
            
            // Chargez les détails supplémentaires nécessaires (rounds, fighters, etc.)
            loadFightDetails(for: fight) { [weak self] rounds, blueFighter, redFighter, fightResult in
                fightResultVC.rounds = rounds
                fightResultVC.blueFighter = blueFighter
                fightResultVC.redFighter = redFighter
                fightResultVC.fightResult = fightResult
                
                DispatchQueue.main.async {
                    self?.present(fightResultVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    func loadFightDetails(for fight: Fight, completion: @escaping ([Round], Fighter?, Fighter?, FightResult?) -> Void) {
        let group = DispatchGroup()
        var rounds: [Round] = []
        var blueFighter: Fighter?
        var redFighter: Fighter?
        var fightResult: FightResult?
        
        // Charger les rounds
        group.enter()
        FirebaseService.shared.getRoundsForFight(fight) { result in
            if case .success(let fetchedRounds) = result {
                rounds = fetchedRounds
            }
            group.leave()
        }
        
        // Charger le combattant bleu
        group.enter()
        FirebaseService.shared.getFighter(id: fight.blueFighterId) { result in
            if case .success(let fighter) = result {
                blueFighter = fighter
            }
            group.leave()
        }
        
        // Charger le combattant rouge
        group.enter()
        FirebaseService.shared.getFighter(id: fight.redFighterId) { result in
            if case .success(let fighter) = result {
                redFighter = fighter
            }
            group.leave()
        }
        
        // Récupérer le résultat du combat
        fightResult = fight.fightResult
        
        group.notify(queue: .main) {
            completion(rounds, blueFighter, redFighter, fightResult)
        }
    }
}

class FightCollectionViewCell: UICollectionViewCell {
    private let fighterNamesLabel = UILabel()
    private let categoryLabel = UILabel()
    private let fightNumber = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowOpacity = 0.1
        
        fighterNamesLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        categoryLabel.font = UIFont.systemFont(ofSize: 12)
        fightNumber.font = UIFont.systemFont(ofSize: 12)

        
        [fighterNamesLabel, categoryLabel, fightNumber].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            fighterNamesLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            fighterNamesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            fighterNamesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            categoryLabel.topAnchor.constraint(equalTo: fighterNamesLabel.bottomAnchor, constant: 4),
            categoryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            categoryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            categoryLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            
            fightNumber.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 4),
            fightNumber.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            fightNumber.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            fightNumber.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with fight: Fight, blueFighterName: String, redFighterName: String) {
           fighterNamesLabel.text = "\(blueFighterName) vs \(redFighterName)"
           categoryLabel.text = "\(fight.category) - \(fight.weightCategory)"
           fightNumber.text = "\(fight.fightNumber)"

           
       }
}
