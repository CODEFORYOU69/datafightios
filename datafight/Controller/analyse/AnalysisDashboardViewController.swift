//
//  AnalysisDashboardViewController.swift
//  datafight
//
//  Created by younes ouasmi on 21/09/2024.
//

import UIKit
import DGCharts

class AnalysisDashboardViewController: UIViewController {
    
    @IBOutlet weak var thematicSegmentedControl: UISegmentedControl!
    @IBOutlet weak var graphCollectionView: UICollectionView!
    @IBOutlet weak var filterButton: UIButton!
    
    private var currentThematic: Thematic = .results
    private var graphs: [GraphConfiguration] = []
    var filters: [String: Any] = [:]
    
    enum Thematic: Int {
        case results, action, fighter
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        loadInitialData()
        
    }
    
    private func loadInitialData() {
        Task {
            do {
                try await loadGraphs(for: .results)
            } catch {
                print("Error loading initial data: \(error)")
                // Handle the error, maybe show an alert to the user
                await MainActor.run {
                    // Show alert to user
                    let alert = UIAlertController(title: "Error", message: "Failed to load initial data", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    func applyFilters(_ newFilters: [String: Any]) {
        self.filters = newFilters
        Task {
            do {
                try await loadGraphs(for: currentThematic)
            } catch {
                print("Error applying filters: \(error)")
                // Handle error (e.g., show alert)
            }
        }
    }
    private func setupUI() {
        thematicSegmentedControl.addTarget(self, action: #selector(thematicChanged), for: .valueChanged)
        filterButton.addTarget(self, action: #selector(showFilters), for: .touchUpInside)
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Calculer la largeur des cellules pour avoir deux colonnes
        let totalWidth = view.bounds.width
        let cellWidth = (totalWidth - layout.minimumInteritemSpacing - layout.sectionInset.left - layout.sectionInset.right) / 2
        
        // Définir une hauteur fixe pour les cellules (ajustez selon vos besoins)
        let cellHeight: CGFloat = 300
        
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        
        graphCollectionView.collectionViewLayout = layout
        graphCollectionView.delegate = self
        graphCollectionView.dataSource = self
        graphCollectionView.register(GraphCollectionViewCell.self, forCellWithReuseIdentifier: "GraphCell")
    }
    
    @objc private func thematicChanged() {
        currentThematic = Thematic(rawValue: thematicSegmentedControl.selectedSegmentIndex) ?? .results
        Task {
            do {
                try await loadGraphs(for: currentThematic)
            } catch {
                print("Error changing thematic: \(error)")
                // Handle error (e.g., show alert)
            }
        }
    }
    
    @objc private func showFilters() {
        let filterVC = FilterViewController()
        filterVC.delegate = self
        present(filterVC, animated: true, completion: nil)
    }
    
    private func loadGraphs(for thematic: Thematic) async throws {
        graphs.removeAll()
        
        switch thematic {
        case .results:
            graphs.append(try await generateVictoryRatioGraph())
            graphs.append(try await generateFirstRoundWinImpactGraph())
            graphs.append(try await generateVictoryTypesGraph())
        case .action, .fighter:
            // Implement other thematics here
            break
        }
        
        await MainActor.run {
            self.graphCollectionView.reloadData()
        }
    }
}

extension AnalysisDashboardViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return graphs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GraphCell", for: indexPath) as! GraphCollectionViewCell
        let graph = graphs[indexPath.item]
        cell.configure(with: graph)
        return cell
    }
}

extension AnalysisDashboardViewController: FilterViewControllerDelegate {
    func didApplyFilters(_ filters: [String: Any]) {
        print("Applied filters: \(filters)")
        self.applyFilters(filters)
    }

    private func generateVictoryRatioGraph() async throws -> GraphConfiguration {
        print("Generating Victory Ratio Graph")
        let filteredFights = try await FirebaseService.shared.fetchFilteredFights(
            fighter: filters["fighter"] as? String,
            gender: filters["gender"] as? String,
            fighterNationality: filters["fighterNationality"] as? String,
            event: filters["event"] as? String,
            eventType: filters["eventType"] as? String,
            eventCountry: filters["eventCountry"] as? String,
            ageCategory: filters["ageCategory"] as? String,
            weightCategory: filters["weightCategory"] as? String,
            isOlympic: filters["isOlympic"] as? Bool,
            startDate: filters["startDate"] as? Date,
            endDate: filters["endDate"] as? Date
        )
        
        print("Filtered Fights: \(filteredFights.count)")
        
        let victories = filteredFights.filter { $0.fightResult?.winner == filters["fighter"] as? String }.count
        let totalFights = filteredFights.count
        
        let victoryRatio = totalFights > 0 ? Double(victories) / Double(totalFights) : 0
        
        print("Victory Ratio: \(victoryRatio)")
        
        // Create chart data
        let dataEntry = PieChartDataEntry(value: victoryRatio * 100, label: "Victory")
        let lossEntry = PieChartDataEntry(value: (1 - victoryRatio) * 100, label: "Loss")
        let dataSet = PieChartDataSet(entries: [dataEntry, lossEntry], label: "Victory Ratio")
        dataSet.colors = [.systemBlue, .systemRed]
        let data = PieChartData(dataSet: dataSet)
        
        return GraphConfiguration(title: "Victory Ratio", type: .pieChart, data: data)
    }

    private func generateFirstRoundWinImpactGraph() async throws -> GraphConfiguration {
        print("Generating First Round Win Impact Graph")
        let filteredFights = try await FirebaseService.shared.fetchFilteredFights(
            fighter: filters["fighter"] as? String,
            gender: filters["gender"] as? String,
            fighterNationality: filters["fighterNationality"] as? String,
            event: filters["event"] as? String,
            eventType: filters["eventType"] as? String,
            eventCountry: filters["eventCountry"] as? String,
            ageCategory: filters["ageCategory"] as? String,
            weightCategory: filters["weightCategory"] as? String,
            isOlympic: filters["isOlympic"] as? Bool,
            startDate: filters["startDate"] as? Date,
            endDate: filters["endDate"] as? Date
        )
        
        print("Filtered Fights: \(filteredFights.count)")
        
        var firstRoundWins = 0
        var totalWins = 0
        
        for fight in filteredFights {
            if let result = fight.fightResult, result.winner == filters["fighter"] as? String {
                totalWins += 1
                if let firstRoundId = fight.roundIds?.first {
                    let rounds = try await FirebaseService.shared.fetchRounds(for: fight)
                    if let firstRound = rounds.first(where: { $0.id == firstRoundId }),
                       firstRound.roundWinner == filters["fighter"] as? String {
                        firstRoundWins += 1
                    }
                }
            }
        }
        
        let firstRoundWinRatio = totalWins > 0 ? Double(firstRoundWins) / Double(totalWins) : 0
        
        print("First Round Win Ratio: \(firstRoundWinRatio)")
        
        // Create chart data
        let dataEntry1 = BarChartDataEntry(x: 0, y: firstRoundWinRatio * 100)
        let dataEntry2 = BarChartDataEntry(x: 1, y: (1 - firstRoundWinRatio) * 100)
        let dataSet = BarChartDataSet(entries: [dataEntry1, dataEntry2], label: "First Round Win Impact")
        dataSet.colors = [.systemGreen, .systemRed]
        let data = BarChartData(dataSet: dataSet)
        
        return GraphConfiguration(title: "First Round Win Impact", type: .barChart, data: data)
    }
    private func generateVictoryTypesGraph() async throws -> GraphConfiguration {
        print("Generating Victory Types Graph")
        let filteredFights = try await FirebaseService.shared.fetchFilteredFights()
        
        print("Filtered Fights: \(filteredFights.count)")
        
        var victoryTypes: [String: Int] = [:]
        
        for fight in filteredFights {
            print("Processing fight: \(fight.id ?? "Unknown")")
            let rounds = try await FirebaseService.shared.fetchRounds(for: fight)
            print("Rounds for fight: \(rounds.count)")
            
            for round in rounds {
                if let victoryDecision = round.victoryDecision {
                    victoryTypes[victoryDecision.rawValue, default: 0] += 1
                    print("Victory type counted: \(victoryDecision.rawValue)")
                }
            }
        }
        
        print("Victory Types: \(victoryTypes)")
        
        // Create chart data
        let dataEntries = victoryTypes.map { (key, value) in
            PieChartDataEntry(value: Double(value), label: key)
        }
        
        if dataEntries.isEmpty {
            print("No data entries for the chart")
            return GraphConfiguration(title: "No Data Available", type: .pieChart, data: PieChartData())
        }
        
        let dataSet = PieChartDataSet(entries: dataEntries, label: "Victory Types")
        dataSet.colors = ChartColorTemplates.material()
        let data = PieChartData(dataSet: dataSet)
        
        return GraphConfiguration(title: "Victory Types", type: .pieChart, data: data)
    }
   
}
