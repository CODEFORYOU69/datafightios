    //
    //  GraphConfigurationViewController.swift
    //  datafight
    //
    //  Created by younes ouasmi on 12/09/2024.
    //


import UIKit

protocol GraphConfigurationDelegate: AnyObject {
    func didSaveGraphConfiguration(_ config: GraphConfiguration)
}

class GraphConfigurationViewController: UIViewController {

    // Délégué pour transmettre la configuration
    weak var delegate: GraphConfigurationDelegate?
    
    // Outlets pour les éléments de l'interface
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var dataConfigurationsStackView: UIStackView!
    
    // Tableau pour stocker les configurations de données (entités, filtres, mesures)
    private var dataConfigurations: [DataConfiguration] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "Configurer le Graphique"
        // Configuration supplémentaire de l'UI si nécessaire
    }

    // Action pour ajouter une nouvelle configuration d'entité
    @IBAction func addDataButtonTapped(_ sender: UIButton) {
        let dataConfig = DataConfiguration(
            entityType: .fighter,
            filters: [],
            measure: Measure(type: .count, field: nil)
        )
        
        dataConfigurations.append(dataConfig)
        
        let dataConfigView = DataConfigurationView()
        dataConfigView.configure(with: dataConfig)
        dataConfigView.translatesAutoresizingMaskIntoConstraints = false
        dataConfigurationsStackView.addArrangedSubview(dataConfigView)
    }



    // Action pour prévisualiser les entités sélectionnées
    @IBAction func previewButtonTapped(_ sender: UIButton) {
        // Préparer un aperçu des entités sélectionnées
        let previewData = dataConfigurations.map { $0.entityType.rawValue }.joined(separator: ", ")
        let alert = UIAlertController(title: "Prévisualisation", message: "Vous avez sélectionné : \(previewData)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // Action pour sauvegarder la configuration complète
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        // Assurez-vous que le nom du graphique est bien défini
        guard let graphName = nameTextField.text, !graphName.isEmpty else {
            let alert = UIAlertController(title: "Erreur", message: "Veuillez donner un nom au graphique.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        // Crée une configuration de graphique à partir des configurations de données
        let graphConfig = GraphConfiguration(name: graphName, dataConfigurations: dataConfigurations, entityType: .fighter)
        
        // Notifie le délégué (AnalyticsViewController) que la configuration est prête
        delegate?.didSaveGraphConfiguration(graphConfig)
        
        // Ferme la vue après la sauvegarde
        self.dismiss(animated: true, completion: nil)
    }
    func calculateMeasure<T: Attributable>(for data: [T], measure: Measure) -> [String: Double] {
        guard let groupBy = measure.groupBy else {
            // Pas de groupement, calculer la mesure globale
            let result = computeMeasure(for: data, measure: measure)
            return ["Total": result]
        }

        // Groupement
        var groupedData = [String: [T]]()

        for item in data {
            if let key = item.getStringValue(for: groupBy) {
                groupedData[key, default: []].append(item)
            }
        }

        var results = [String: Double]()
        for (key, group) in groupedData {
            let result = computeMeasure(for: group, measure: measure)
            results[key] = result
        }

        return results
    }

    func computeMeasure<T: Attributable>(for data: [T], measure: Measure) -> Double {
        switch measure.type {
        case .count:
            return Double(data.count)
        case .sum, .average:
            guard let field = measure.field else { return 0 }
            let values = data.compactMap { item in
                item.getNumericValue(for: field)
            }
            let sum = values.reduce(0, +)
            if measure.type == .sum {
                return sum
            } else {
                return sum / Double(values.count)
            }
        }
    }
}

