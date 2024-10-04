import Firebase
import UIKit

class FightResultViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet weak var blueImageView: UIImageView!
    @IBOutlet weak var redImageView: UIImageView!
    @IBOutlet weak var blueNameLabel: UILabel!
    @IBOutlet weak var redNameLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var roundsStackView: UIStackView!
    @IBOutlet weak var resultView: UIView!

    // MARK: - Properties
    var fight: Fight?
    var rounds: [Round] = []
    var fightResult: FightResult?
    var onDismiss: (() -> Void)?
    var blueFighter: Fighter?
    var redFighter: Fighter?

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        styleResultView()
        styleFighterViews()
        styleResultLabel()
        configureRoundsStackView()
        configureFightResult()
        addSwipeGesture()

        // Log view controller appearance
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "Fight Result"
            ])
    }

    // MARK: - UI Setup Methods
    private func setupBackground() {
        view.backgroundColor = UIColor(
            red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)  // Dark background

        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.image = UIImage(named: "fightbackground.jpeg")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.2
        view.insertSubview(backgroundImageView, at: 0)
    }

    private func styleResultView() {
        resultView.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        resultView.layer.cornerRadius = 20
        resultView.layer.shadowColor = UIColor.systemBlue.cgColor
        resultView.layer.shadowOffset = CGSize(width: 0, height: 5)
        resultView.layer.shadowRadius = 10
        resultView.layer.shadowOpacity = 0.8
    }

    private func styleFighterViews() {
        [blueImageView, redImageView].forEach { imageView in
            imageView?.contentMode = .scaleAspectFill
            imageView?.layer.cornerRadius = (imageView?.frame.height ?? 0) / 2
            imageView?.layer.borderWidth = 4
            imageView?.layer.borderColor =
                UIColor.systemBlue.withAlphaComponent(0.7).cgColor  // Neon effect
            imageView?.clipsToBounds = true
        }

        [blueNameLabel, redNameLabel].forEach { label in
            label?.textColor = .white
            label?.font = UIFont.boldSystemFont(ofSize: 18)
            label?.shadowColor = .black
            label?.shadowOffset = CGSize(width: 1, height: 1)
        }
    }

    private func styleResultLabel() {
        resultLabel.textColor = .white
        resultLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        resultLabel.numberOfLines = 0
        resultLabel.textAlignment = .center
    }

    private func configureRoundsStackView() {
        roundsStackView.axis = .vertical
        roundsStackView.spacing = 10
        roundsStackView.distribution = .fillEqually
    }

    private func addSwipeGesture() {
        let swipeDown = UISwipeGestureRecognizer(
            target: self, action: #selector(respondToSwipeGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
    }

    // MARK: - Configuration Methods
    func configureFightResult() {
        guard let fight = fight,
            let result = fightResult,
            let blueFighter = blueFighter,
            let redFighter = redFighter
        else {
            return
        }

        blueNameLabel.text = "\(blueFighter.firstName) \(blueFighter.lastName)"
        redNameLabel.text = "\(redFighter.firstName) \(redFighter.lastName)"

        // Load fighter images
        if let blueImageURL = URL(string: blueFighter.profileImageURL ?? "") {
            loadImage(url: blueImageURL, into: blueImageView)
        }
        if let redImageURL = URL(string: redFighter.profileImageURL ?? "") {
            loadImage(url: redImageURL, into: redImageView)
        }

        // Display final fight result
        let winnerName =
            result.winner == fight.blueFighterId
            ? blueFighter.lastName : redFighter.lastName
        resultLabel.text = """
            Winner: \(winnerName)
            Method: \(result.method)
            Score: \(result.totalScore.blue) - \(result.totalScore.red)
            Category: \(fight.category)
            Weight: \(fight.weightCategory)
            Olympic: \(fight.isOlympic ? "Yes" : "No")
            """

        // Configure round results
        roundsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for round in rounds {
            let roundView = createRoundResultView(for: round, fight: fight)
            roundsStackView.addArrangedSubview(roundView)
        }
    }

    private func createRoundResultView(for round: Round, fight: Fight) -> UIView
    {
        let roundView = UIView()
        roundView.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
        roundView.layer.cornerRadius = 15
        roundView.layer.shadowColor = UIColor.systemBlue.cgColor
        roundView.layer.shadowOffset = CGSize(width: 0, height: 3)
        roundView.layer.shadowRadius = 6
        roundView.layer.shadowOpacity = 0.5

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        roundView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(
                equalTo: roundView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(
                equalTo: roundView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(
                equalTo: roundView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(
                equalTo: roundView.bottomAnchor, constant: -12),
        ])

        let labels: [(String, String)] = [
            ("Round \(round.roundNumber)", "title"),
            (
                "Score: Blue \(round.blueScore) - Red \(round.redScore)",
                "normal"
            ),
            (
                "Gamjeons: Blue \(round.blueGamJeon) - Red \(round.redGamJeon)",
                "normal"
            ),
            ("Hits: Blue \(round.blueHits) - Red \(round.redHits)", "normal"),
            (
                "Victory Decision: \(round.victoryDecision?.rawValue ?? "N/A")",
                "normal"
            ),
            (
                "Winner: \(round.roundWinner == fight.blueFighterId ? "Blue" : "Red")",
                "highlight"
            ),
            ("Duration: \(formatDuration(round.duration))", "normal"),
        ]

        labels.forEach { (text, style) in
            let label = UILabel()
            label.text = text
            label.textColor = .white
            switch style {
            case "title":
                label.font = UIFont.boldSystemFont(ofSize: 18)
            case "highlight":
                label.font = UIFont.boldSystemFont(ofSize: 16)
                label.textColor = .systemBlue
            default:
                label.font = UIFont.systemFont(ofSize: 14)
            }
            label.numberOfLines = 0
            stackView.addArrangedSubview(label)
        }

        return roundView
    }

    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func loadImage(url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }.resume()
    }

    // MARK: - Actions
    @IBAction func dismissTapped(_ sender: Any) {
        dismiss(animated: true) {
            self.onDismiss?()
        }

        // Log dismiss action
        Analytics.logEvent("fight_result_dismissed", parameters: nil)
    }

    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case .down:
                dismiss(animated: true, completion: nil)

                // Log swipe dismiss action
                Analytics.logEvent("fight_result_swiped_down", parameters: nil)
            default:
                break
            }
        }
    }
}
