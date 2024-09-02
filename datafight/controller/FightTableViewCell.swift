import UIKit
import SDWebImage
import FlagKit

class FightTableViewCell: UITableViewCell {
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
    }

    private func setupCellStyle() {
        // Appliquer des coins arrondis à la vue de contenu
        self.contentView.layer.cornerRadius = 15
        self.contentView.layer.masksToBounds = true

        // Ajouter une ombre pour un effet moderne
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowOpacity = 0.2
        self.layer.shadowRadius = 6
        self.layer.masksToBounds = false
        self.layer.cornerRadius = 15

        // Rendre les images des combattants circulaires
        blueFighterImageView.layer.cornerRadius = blueFighterImageView.frame.height / 2
        blueFighterImageView.clipsToBounds = true

        redFighterImageView.layer.cornerRadius = redFighterImageView.frame.height / 2
        redFighterImageView.clipsToBounds = true
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
        configureAddRoundButton(roundCount: fight.roundIds?.count ?? 0)
    }

    private func configureRoundLabels(for rounds: [Round], roundIds: [String]) {
        let roundLabels = [round1Label, round2Label, round3Label]

        for (index, label) in roundLabels.enumerated() {
            if index < roundIds.count {
                let roundNumber = index + 1
                label?.text = "R\(roundNumber)"

                if let round = rounds.first(where: { $0.id == roundIds[index] }) {
                    if let winnerId = round.roundWinner {
                        label?.textColor = (winnerId == round.blueFighterId) ? .blue : .red
                    } else {
                        label?.textColor = .black
                    }
                } else {
                    label?.textColor = .black
                }
            } else {
                label?.text = "R\(index + 1)"
                label?.textColor = .lightGray
            }
        }
    }

    private func configureAddRoundButton(roundCount: Int) {
        addRoundButton.isEnabled = roundCount < 3
        addRoundButton.setTitle(roundCount < 3 ? "Add Round" : "Fight Complete", for: .normal)
    }

    @IBAction func addRoundButtonTapped(_ sender: UIButton) {
        addRoundAction?()
    }
}
