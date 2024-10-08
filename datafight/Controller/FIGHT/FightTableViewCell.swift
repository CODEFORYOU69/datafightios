import FlagKit
import SDWebImage
import UIKit

class FightTableViewCell: UITableViewCell {
    // MARK: - IBOutlets
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

    // MARK: - Properties
    var addRoundAction: (() -> Void)?

    // MARK: - Lifecycle Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellStyle()
        styleLabelsAndButtons()

        // Configure container view
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        containerView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Ajouter une marge autour du contenu de la cellule
        contentView.frame = contentView.frame.inset(
            by: UIEdgeInsets(top: 0, left: 10, bottom: 10, right: 10))
    }

    // MARK: - Private Methods
    private func setupCellStyle() {
        let verticalPadding: CGFloat = 10
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear

        let backgroundView = UIView(
            frame: self.bounds.inset(
                by: UIEdgeInsets(
                    top: verticalPadding / 2, left: 10,
                    bottom: verticalPadding / 2, right: 10)))
        backgroundView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)

        backgroundView.layer.borderWidth = 1.0
        backgroundView.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.3).cgColor
        backgroundView.layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.3).cgColor
        backgroundView.layer.shadowRadius = 5.0
        backgroundView.layer.shadowOpacity = 0.5
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 0)

        backgroundView.layer.cornerRadius = 15
        backgroundView.layer.masksToBounds = false

        self.backgroundView = backgroundView

        self.contentView.layer.zPosition = 1
        self.contentView.layoutMargins = UIEdgeInsets(
            top: verticalPadding / 2, left: 20, bottom: verticalPadding / 2,
            right: 20)

        [blueFighterImageView, redFighterImageView].forEach { imageView in
            imageView?.layer.cornerRadius = imageView!.frame.height / 2
            imageView?.clipsToBounds = true
            imageView?.layer.borderWidth = 2
            imageView?.layer.borderColor =
                UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor
        }

        addRoundButton.layer.shadowColor = UIColor.black.cgColor
        addRoundButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addRoundButton.layer.shadowOpacity = 0.1
        addRoundButton.layer.shadowRadius = 4
    }

    private func styleLabelsAndButtons() {
        // test workflows
        let labels = [
            blueFighterNameLabel, redFighterNameLabel, fightInfoLabel,
            round1Label, round2Label, round3Label,
        ]
        for label in labels {
            label?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label?.textColor = UIColor.lightGray
        }

        addRoundButton.layer.cornerRadius = 10
        addRoundButton.backgroundColor = UIColor(
            red: 0.8, green: 0.1, blue: 0.1, alpha: 0.8)
        addRoundButton.setTitleColor(.white, for: .normal)
        addRoundButton.titleLabel?.font = UIFont.systemFont(
            ofSize: 14, weight: .semibold)
    }

    // MARK: - Public Methods
    func configure(
        with fight: Fight, blueFighter: Fighter?, redFighter: Fighter?,
        event: Event?, rounds: [Round]
    ) {
        // Configure blue fighter
        if let blueFighter = blueFighter,
            let flag = Flag(countryCode: blueFighter.country)
        {
            blueFlagImageView.image = flag.image(style: .roundedRect)
        } else {
            blueFlagImageView.image = nil
        }
        blueFighterImageView.sd_setImage(
            with: URL(string: blueFighter?.profileImageURL ?? ""),
            placeholderImage: UIImage(named: "placeholder_fighter"))
        blueFighterNameLabel.text =
            blueFighter.map { "\($0.firstName) \($0.lastName)" } ?? "Unknown"

        // Configure fight info
        if let event = event {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            let dateString = dateFormatter.string(from: event.date)
            fightInfoLabel.text =
                "\(event.eventName) - \(dateString) - \(fight.category) \(fight.weightCategory)kg - \(fight.fightNumber)-\(fight.round ?? "")"
        } else {
            fightInfoLabel.text = "Fight information unavailable"
        }

        // Configure red fighter
        if let redFighter = redFighter,
            let flag = Flag(countryCode: redFighter.country)
        {
            redFlagImageView.image = flag.image(style: .roundedRect)
        } else {
            redFlagImageView.image = nil
        }
        redFighterImageView.sd_setImage(
            with: URL(string: redFighter?.profileImageURL ?? ""),
            placeholderImage: UIImage(named: "placeholder_fighter"))
        redFighterNameLabel.text =
            redFighter.map { "\($0.firstName) \($0.lastName)" } ?? "Unknown"

        configureRoundLabels(for: rounds, roundIds: fight.roundIds ?? [])
        configureAddRoundButton(
            roundCount: fight.roundIds?.count ?? 0,
            fightResult: fight.fightResult)
    }

    func configureRoundLabels(for rounds: [Round], roundIds: [String]) {
        let roundLabels = [round1Label, round2Label, round3Label]

        for (index, label) in roundLabels.enumerated() {
            if index < roundIds.count {
                let roundNumber = index + 1
                label?.text = "R\(roundNumber)"

                if let round = rounds.first(where: { $0.id == roundIds[index] })
                {
                    if let winnerId = round.roundWinner {
                        label?.textColor =
                            (winnerId == round.blueFighterId)
                            ? .systemBlue : .systemRed
                        label?.font = UIFont.boldSystemFont(ofSize: 16)
                    } else {
                        label?.textColor = .lightGray
                        label?.font = UIFont.systemFont(ofSize: 16)
                    }
                } else {
                    label?.textColor = .lightGray
                    label?.font = UIFont.systemFont(ofSize: 16)
                }
            } else {
                label?.text = "R\(index + 1)"
                label?.textColor = UIColor(white: 0.3, alpha: 1.0)  // Gris très foncé pour les rounds non joués
                label?.font = UIFont.systemFont(ofSize: 16)
            }

            label?.layer.shadowColor = UIColor.black.cgColor
            label?.layer.shadowRadius = 1.0
            label?.layer.shadowOpacity = 0.2
            label?.layer.shadowOffset = CGSize(width: 1, height: 1)
            label?.layer.masksToBounds = false
        }
    }

    private func configureAddRoundButton(
        roundCount: Int, fightResult: FightResult?
    ) {
        if fightResult != nil {
            addRoundButton.isEnabled = false
            addRoundButton.setTitle("Fight Complete", for: .normal)
            addRoundButton.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
            addRoundButton.setTitleColor(.black, for: .normal)
        } else if roundCount == 3 {
            addRoundButton.isEnabled = false
            addRoundButton.setTitle("Max Rounds", for: .normal)
            addRoundButton.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
            addRoundButton.setTitleColor(.black, for: .normal)
        } else {
            addRoundButton.isEnabled = true
            addRoundButton.setTitle("Add Round", for: .normal)
            addRoundButton.backgroundColor = UIColor(
                red: 0.8, green: 0.1, blue: 0.1, alpha: 0.8)
            addRoundButton.setTitleColor(.white, for: .normal)
        }

        addRoundButton.titleLabel?.alpha = addRoundButton.isEnabled ? 1.0 : 0.8
    }
    // MARK: - IBActions
    @IBAction func addRoundButtonTapped(_ sender: UIButton) {
        addRoundAction?()
    }
}
