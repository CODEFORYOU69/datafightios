//
//  FightDetailViewController.swift
//  datafight
//
//  Created by younes ouasmi on 23/09/2024.
//

import UIKit

class FightDetailViewController: UIViewController {

    @IBOutlet weak var blueImageView: UIImageView!
    @IBOutlet weak var redImageView: UIImageView!
    @IBOutlet weak var blueNameLabel: UILabel!
    @IBOutlet weak var redNameLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var roundsStackView: UIStackView!
    @IBOutlet weak var ResultView: UIView!
    
    var fight: Fight?
    var rounds: [Round] = []
    var fightResult: FightResult?
    var onDismiss: (() -> Void)?
    var blueFighter: Fighter?
    var redFighter: Fighter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundImage()
        styleResultView()
        styleFighterViews()
        styleResultLabel()
        configureRoundsStackView()
        configureFightResult()
        addSwipeGesture()
    }
    
    private func setupBackgroundImage() {
        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.image = UIImage(named: "fightbackground.jpeg")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(backgroundImageView, at: 0)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func styleResultView() {
        ResultView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        ResultView.layer.cornerRadius = 20
        ResultView.layer.shadowColor = UIColor.black.cgColor
        ResultView.layer.shadowOffset = CGSize(width: 0, height: 5)
        ResultView.layer.shadowRadius = 10
        ResultView.layer.shadowOpacity = 0.3
    }
    
    private func styleFighterViews() {
        [blueImageView, redImageView].forEach { imageView in
            imageView?.contentMode = .scaleAspectFill
            imageView?.layer.cornerRadius = (imageView?.frame.height ?? 0) / 2
            imageView?.layer.borderWidth = 3
            imageView?.layer.borderColor = UIColor.white.cgColor
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
        resultLabel.textColor = .black
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
            let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
            swipeDown.direction = .down
            self.view.addGestureRecognizer(swipeDown)
        }
        
        @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
            if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                switch swipeGesture.direction {
                case .down:
                    dismiss(animated: true, completion: nil)
                default:
                    break
                }
            }
        }
    func configureFightResult() {
        // Configurer les noms des combattants
        blueNameLabel.text = blueFighter?.fullName ?? fight?.blueFighterId ?? "Blue Fighter"
        redNameLabel.text = redFighter?.fullName ?? fight?.redFighterId ?? "Red Fighter"
        
        // Charger les images des combattants
        if let blueImageURL = URL(string: blueFighter?.profileImageURL ?? "") {
            loadImage(url: blueImageURL, into: blueImageView)
        }
        if let redImageURL = URL(string: redFighter?.profileImageURL ?? "") {
            loadImage(url: redImageURL, into: redImageView)
        }
        
        // Afficher le résultat final du combat
        var resultText = ""
        if let result = fightResult {
            let winnerName = result.winner == fight?.blueFighterId ? blueNameLabel.text : redNameLabel.text
            resultText += "Winner: \(winnerName ?? "Unknown")\n"
            resultText += "Method: \(result.method)\n"
            resultText += "Score: \(result.totalScore.blue) - \(result.totalScore.red)\n"
        } else {
            resultText += "Fight result not available\n"
        }
        
        if let fight = fight {
            resultText += "Category: \(fight.category)\n"
            resultText += "Weight: \(fight.weightCategory)\n"
            resultText += "Olympic: \(fight.isOlympic ? "Yes" : "No")\n"
        }
        
        resultLabel.text = resultText
        
        // Configurer les résultats des rounds
        roundsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for round in rounds {
            let roundView = createRoundResultView(for: round, fight: fight)
            roundsStackView.addArrangedSubview(roundView)
        }
    }
    
       
    private func createRoundResultView(for round: Round, fight: Fight?) -> UIView {
        let roundView = UIView()
        roundView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        roundView.layer.cornerRadius = 15
        roundView.layer.shadowColor = UIColor.black.cgColor
        roundView.layer.shadowOffset = CGSize(width: 0, height: 3)
        roundView.layer.shadowRadius = 6
        roundView.layer.shadowOpacity = 0.2
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        roundView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: roundView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: roundView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: roundView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: roundView.bottomAnchor, constant: -12)
        ])
        
        let labels: [(String, String)] = [
            ("Round \(round.roundNumber)", "title"),
            ("Score: Blue \(round.blueScore) - Red \(round.redScore)", "normal"),
            ("Gamjeons: Blue \(round.blueGamJeon) - Red \(round.redGamJeon)", "normal"),
            ("Hits: Blue \(round.blueHits) - Red \(round.redHits)", "normal"),
            ("Victory Decision: \(round.victoryDecision?.rawValue ?? "N/A")", "normal"),
            ("Winner: \(round.roundWinner == fight?.blueFighterId ? "Blue" : (round.roundWinner == fight?.redFighterId ? "Red" : "Unknown"))", "highlight"),
            ("Duration: \(formatDuration(round.duration))", "normal")
        ]
        
        labels.forEach { (text, style) in
            let label = UILabel()
            label.text = text
            label.textColor = .black
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
       
       private func formatDuration(_ duration: TimeInterval) -> String {
           let minutes = Int(duration) / 60
           let seconds = Int(duration) % 60
           return String(format: "%02d:%02d", minutes, seconds)
       }
        
        @IBAction func dismissTapped(_ sender: Any) {
            dismiss(animated: true) {
                self.onDismiss?()
            }
        }
        
        // Méthode pour charger une image à partir d'une URL
        private func loadImage(url: URL, into imageView: UIImageView) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }
            }.resume()
        }
        
       
    }
extension Fighter {
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}
