    import UIKit

    class FightResultViewController: UIViewController {
        @IBOutlet weak var blueImageView: UIImageView!
        @IBOutlet weak var redImageView: UIImageView!
        @IBOutlet weak var blueNameLabel: UILabel!
        @IBOutlet weak var redNameLabel: UILabel!
        @IBOutlet weak var resultLabel: UILabel!
        @IBOutlet weak var roundsStackView: UIStackView!

        var fight: Fight?
        var rounds: [Round] = []
        var fightResult: FightResult?
        var onDismiss: (() -> Void)?
        
        // Ajoutez ces propriétés pour stocker les objets Fighter
        var blueFighter: Fighter?
        var redFighter: Fighter?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            configureFightResult()
            addSwipeGesture()
            setupBackgroundImage()


        }
        
        private func setupBackgroundImage() {
            // Créez une UIImageView avec l'image de fond
            let backgroundImageView = UIImageView(frame: view.bounds)
            backgroundImageView.image = UIImage(named: "fightbackground.jpeg") // Nom de votre image
            backgroundImageView.contentMode = .scaleAspectFill
            backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
            
            // Ajoutez l'image de fond à la vue principale
            view.insertSubview(backgroundImageView, at: 0)  // Insérez l'image à l'arrière-plan

            // Ajoutez des contraintes pour que l'image occupe tout l'écran
            NSLayoutConstraint.activate([
                backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
                backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
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
            guard let fight = fight,
                  let result = fightResult,
                  let blueFighter = blueFighter,
                  let redFighter = redFighter else {
                return
            }
            
            blueNameLabel.text = "\(blueFighter.firstName) \(blueFighter.lastName)"
            redNameLabel.text = "\(redFighter.firstName) \(redFighter.lastName)"
            
            // Charger les images des combattants
            if let blueImageURL = URL(string: blueFighter.profileImageURL ?? "") {
                loadImage(url: blueImageURL, into: blueImageView)
            }
            if let redImageURL = URL(string: redFighter.profileImageURL ?? "") {
                loadImage(url: redImageURL, into: redImageView)
            }
            
            // Configurer les résultats des rounds
            for round in rounds {
                let roundView = createRoundResultView(for: round)
                roundsStackView.addArrangedSubview(roundView)
            }
            
            // Afficher le résultat final du combat
            let winnerName = result.winner == fight.blueFighterId ? blueFighter.lastName : redFighter.lastName
            resultLabel.text = "Winner: \(winnerName)\nMethod: \(result.method)\nScore: \(result.totalScore.blue) - \(result.totalScore.red)"
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
        
        // Méthode pour créer une vue de résultat de round
        private func createRoundResultView(for round: Round) -> UIView {
            // Implémentez cette méthode pour créer une vue de résultat de round
            // Exemple simple :
            let label = UILabel()
            label.text = "Round \(round.roundNumber): Blue \(round.blueScore) - Red \(round.redScore)"
            return label
        }
    }
