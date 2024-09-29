import UIKit
import SDWebImage
import FlagKit

class FightTableViewCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var blueFlagImageView: UIImageView!
    @IBOutlet weak var blueFighterImageView: UIImageView!
    @IBOutlet weak var blueFighterNameLabel: UILabel!
    @IBOutlet weak var fightInfoLabel: UILabel!
    @IBOutlet weak var redFighterImageView: UIImageView!
    @IBOutlet weak var redFighterNameLabel: UILabel!
    @IBOutlet weak var redFlagImageView: UIImageView!
    @IBOutlet weak var addRoundButton: UIButton!
    @IBOutlet weak var round1Label: UILabel!
    @IBOutlet weak var round2Label: UILabel!
    @IBOutlet weak var round3Label: UILabel!

    var addRoundAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellStyle()
        styleLabelsAndButtons()
        
        containerView.layer.cornerRadius = 10
                containerView.layer.masksToBounds = true
                containerView.backgroundColor = UIColor.systemGray6
    }
    

    private func setupCellStyle() {
        // Configuration de base
        let verticalPadding: CGFloat = 10
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        
        // Création d'une vue de fond pour appliquer les effets
        let backgroundView = UIView(frame: self.bounds.inset(by: UIEdgeInsets(top: verticalPadding/2, left: 10, bottom: verticalPadding/2, right: 10)))
        backgroundView.backgroundColor = .white
        
        // Ajout de l'ombre
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 4)
        backgroundView.layer.shadowOpacity = 0.1
        backgroundView.layer.shadowRadius = 8
        
        // Ajout de la bordure et des coins arrondis
        backgroundView.layer.cornerRadius = 15
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        
        // Assurez-vous que l'ombre est visible en dehors des limites de la vue
        backgroundView.layer.masksToBounds = false
        
        // Ajout de la vue de fond à la cellule
        self.backgroundView = backgroundView
        
        // Assurez-vous que le contenu de la cellule est au-dessus de la vue de fond
        self.contentView.layer.zPosition = 1
        
        // Ajustez les marges du contenu pour qu'il s'aligne avec la vue de fond
        self.contentView.layoutMargins = UIEdgeInsets(top: verticalPadding/2, left: 20, bottom: verticalPadding/2, right: 20)
        
        // Rendre les images des combattants circulaires avec une bordure
        [blueFighterImageView, redFighterImageView].forEach { imageView in
            imageView?.layer.cornerRadius = imageView!.frame.height / 2
            imageView?.clipsToBounds = true
            imageView?.layer.borderWidth = 2
            imageView?.layer.borderColor = UIColor.white.cgColor
        }
        
        // Ajouter un effet de profondeur au bouton "Add Round"
        addRoundButton.layer.shadowColor = UIColor.black.cgColor
        addRoundButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addRoundButton.layer.shadowOpacity = 0.1
        addRoundButton.layer.shadowRadius = 4
    }
    private func styleLabelsAndButtons() {
        // Style des labels
        let labels = [blueFighterNameLabel, redFighterNameLabel, fightInfoLabel, round1Label, round2Label, round3Label]
        for label in labels {
            label?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label?.textColor = UIColor.darkGray
        }

        // Style du bouton "Add Round"
        addRoundButton.layer.cornerRadius = 10
        addRoundButton.backgroundColor = UIColor.systemBlue
        addRoundButton.setTitleColor(.white, for: .normal)
        addRoundButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    }

    func configure(with fight: Fight, blueFighter: Fighter?, redFighter: Fighter?, event: Event?, rounds: [Round]) {
        // Blue Fighter
        if let blueFighter = blueFighter, let flag = Flag(countryCode: blueFighter.country) {
            blueFlagImageView.image = flag.image(style: .roundedRect)
        } else {
            blueFlagImageView.image = nil
        }
        blueFighterImageView.sd_setImage(with: URL(string: blueFighter?.profileImageURL ?? ""), placeholderImage: UIImage(named: "placeholder_fighter"))
        blueFighterNameLabel.text = blueFighter.map { "\($0.firstName) \($0.lastName)" } ?? "Unknown"

        // Fight Info
        if let event = event {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            let dateString = dateFormatter.string(from: event.date)
            fightInfoLabel.text = "\(event.eventName) - \(dateString) - \(fight.category) \(fight.weightCategory)kg - \(fight.fightNumber)-\(fight.round ?? "")"
        } else {
            fightInfoLabel.text = "Fight information unavailable"
        }

        // Red Fighter
        if let redFighter = redFighter, let flag = Flag(countryCode: redFighter.country) {
            redFlagImageView.image = flag.image(style: .roundedRect)
        } else {
            redFlagImageView.image = nil
        }
        redFighterImageView.sd_setImage(with: URL(string: redFighter?.profileImageURL ?? ""), placeholderImage: UIImage(named: "placeholder_fighter"))
        redFighterNameLabel.text = redFighter.map { "\($0.firstName) \($0.lastName)" } ?? "Unknown"

        configureRoundLabels(for: rounds, roundIds: fight.roundIds ?? [])
        configureAddRoundButton(roundCount: fight.roundIds?.count ?? 0, fightResult: fight.fightResult)
    }
    
    func configureRoundLabels(for rounds: [Round], roundIds: [String]) {
        let roundLabels = [round1Label, round2Label, round3Label]

        for (index, label) in roundLabels.enumerated() {
            if index < roundIds.count {
                let roundNumber = index + 1
                label?.text = "R\(roundNumber)"

                if let round = rounds.first(where: { $0.id == roundIds[index] }) {
                    if let winnerId = round.roundWinner {
                        label?.textColor = (winnerId == round.blueFighterId) ? .blue : .red
                        label?.font = UIFont.boldSystemFont(ofSize: 16) // Mettre en gras le label du round gagné
                    } else {
                        label?.textColor = .black
                        label?.font = UIFont.systemFont(ofSize: 16)
                    }
                } else {
                    label?.textColor = .black
                    label?.font = UIFont.systemFont(ofSize: 16)
                }
            } else {
                label?.text = "R\(index + 1)"
                label?.textColor = .lightGray
                label?.font = UIFont.systemFont(ofSize: 16)
            }
            
            // Ajouter une ombre au texte pour le faire ressortir
            label?.layer.shadowColor = UIColor.black.cgColor
            label?.layer.shadowRadius = 1.0
            label?.layer.shadowOpacity = 0.2
            label?.layer.shadowOffset = CGSize(width: 1, height: 1)
            label?.layer.masksToBounds = false
        }
    }


    private func configureAddRoundButton(roundCount: Int, fightResult: FightResult?) {
        // Désactiver le bouton si 3 rounds sont atteints ou si le combat est terminé
        if fightResult != nil {
            addRoundButton.isEnabled = false
            addRoundButton.setTitle("Fight Complete", for: .normal)
        } else if roundCount == 3 {
            addRoundButton.isEnabled = false
            addRoundButton.setTitle("Max Rounds", for: .normal)
        } else {
            addRoundButton.isEnabled = true
            addRoundButton.setTitle("Add Round", for: .normal)
        }
    }


    @IBAction func addRoundButtonTapped(_ sender: UIButton) {
        addRoundAction?()
    }
}
