    //
    //  AnalyticsViewController.swift
    //  datafight
    //
    //  Created by younes ouasmi on 04/08/2024.
    //

    import UIKit

    class AnalyticsViewController: UIViewController {

        @IBOutlet weak var tableView: UITableView!
        
        var graphConfigurations: [GraphConfiguration] = []
        private let nameLabel = UILabel()
            private let visualizationTypeLabel = UILabel()

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            setupTableView()
            
            // Charger les configurations existantes depuis Firebase si nécessaire
            loadGraphConfigurations()
        }

        func setupUI() {
            title = "Analyse"
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Ajouter Graphique", style: .plain, target: self, action: #selector(addGraphButtonTapped))
        }

        func setupTableView() {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(GraphConfigurationCell.self, forCellReuseIdentifier: "GraphConfigurationCell")
        }

        @objc func addGraphButtonTapped() {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let chatBotVC = storyboard.instantiateViewController(withIdentifier: "ChatBotViewController") as? ChatBotViewController {
                chatBotVC.delegate = self
                let navController = UINavigationController(rootViewController: chatBotVC)
                present(navController, animated: true, completion: nil)
            }
        }
        
        func loadGraphConfigurations() {
            FirebaseService.shared.getGraphConfigurations { [weak self] result in
                switch result {
                case .success(let configurations):
                    self?.graphConfigurations = configurations
                    self?.tableView.reloadData()
                case .failure(let error):
                    // Gérer l'erreur
                    print("Erreur lors du chargement des configurations : \(error.localizedDescription)")
                    // Vous pouvez afficher une alerte ou un message à l'utilisateur
                }
            }
        }

    }

    extension AnalyticsViewController: UITableViewDataSource, UITableViewDelegate {
        // MARK: - UITableViewDataSource
        func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return graphConfigurations.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            if let cell = tableView.dequeueReusableCell(withIdentifier: "GraphConfigurationCell", for: indexPath) as? GraphConfigurationCell {
                cell.configure(with: graphConfigurations[indexPath.row])
                return cell
            } else {
                return UITableViewCell()
            }
        }

        // MARK: - UITableViewDelegate
        // Suppression d'une configuration
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                let config = graphConfigurations[indexPath.row]
                FirebaseService.shared.deleteGraphConfiguration(id: config.id ?? "") { [weak self] result in
                    switch result {
                    case .success:
                        self?.graphConfigurations.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    case .failure(let error):
                        // Gérer l'erreur
                        print("Erreur lors de la suppression : \(error.localizedDescription)")
                        // Vous pouvez afficher une alerte à l'utilisateur
                    }
                }
            }
        }

        // Configuration de la cellule
        func configure(with config: GraphConfiguration) {
            nameLabel.text = config.name
            visualizationTypeLabel.text = config.visualizationType.rawValue
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // Afficher le graphique correspondant à la configuration sélectionnée
            let config = graphConfigurations[indexPath.row]
            displayGraph(for: config)
        }

        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 80 // Ajustez selon vos besoins
        }
    }

    extension AnalyticsViewController: ChatBotViewControllerDelegate {
        func didSaveGraphConfiguration(_ config: GraphConfiguration) {
            graphConfigurations.append(config)
            tableView.reloadData()
            
            // Enregistrer la configuration dans Firebase si nécessaire
            // Exemple :
            /*
            FirebaseService.shared.saveGraphConfiguration(config) { result in
                switch result {
                case .success:
                    print("Configuration sauvegardée avec succès.")
                case .failure(let error):
                    print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
                }
            }
            */
        }
    }

    extension AnalyticsViewController {
        func displayGraph(for config: GraphConfiguration) {
            // En fonction du type de visualisation, affichez le graphique approprié
            switch config.visualizationType {
            case .barChart:
                displayBarChart(with: config)
            case .radarChart:
                displayRadarChart(with: config)
            case .lineChart:
                displayLineChart(with: config)
            case .pieChart:
                displayPiechart(with: config)
            case .scatterPlot:
                displayScatterPlotChart(with: config)
                
            // Ajoutez d'autres cas si nécessaire
            }
        }

        func displayBarChart(with config: GraphConfiguration) {
          
        }

        
        func displayRadarChart(with config: GraphConfiguration) {
            // Implémentez la logique pour afficher un graphique radar avec les données de config
            // Vous pouvez présenter un nouveau ViewController qui affiche le graphique
        }
        func displayLineChart(with config: GraphConfiguration) {
            // Implémentez la logique pour afficher un graphique radar avec les données de config
            // Vous pouvez présenter un nouveau ViewController qui affiche le graphique
        }
        func displayPiechart(with config: GraphConfiguration) {
            // Implémentez la logique pour afficher un graphique radar avec les données de config
            // Vous pouvez présenter un nouveau ViewController qui affiche le graphique
        }
        func displayScatterPlotChart(with config: GraphConfiguration) {
            // Implémentez la logique pour afficher un graphique radar avec les données de config
            // Vous pouvez présenter un nouveau ViewController qui affiche le graphique
        }
        
    }
    class GraphConfigurationCell: UITableViewCell {
        private let nameLabel = UILabel()
        private let visualizationTypeLabel = UILabel()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupUI()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupUI()
        }

        private func setupUI() {
            contentView.addSubview(nameLabel)
            contentView.addSubview(visualizationTypeLabel)

           
            nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
            visualizationTypeLabel.font = UIFont.systemFont(ofSize: 14)
            visualizationTypeLabel.textColor = .gray
        }

        func configure(with config: GraphConfiguration) {
            nameLabel.text = config.name
            visualizationTypeLabel.text = config.visualizationType.rawValue
        }
    }

