//
//  AnalysisDashboardViewController.swift
//  datafight
//
//  Created by younes ouasmi on 21/09/2024.
//

import DGCharts
import Firebase
import UIKit

class AnalysisDashboardViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var thematicSegmentedControl: UISegmentedControl!
    @IBOutlet weak var graphCollectionView: UICollectionView!
    @IBOutlet weak var filterButton: UIButton!

    // MARK: - Properties
    private var currentThematic: Thematic = .results
    private var graphs: [GraphConfiguration] = []
    var filters: [String: Any] = [:]

    enum Thematic: Int {
        case results, action, fighter
    }

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        loadInitialData()
        setupNavigationBar()

        // Log screen view
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: "Analysis Dashboard"
            ])
    }
    func setupNavigationBar() {
        navigationItem.title = "Analyze"

        // Configuration des attributs de la barre de navigation pour le titre en blanc
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]

        // Assurez-vous que le style de la barre est défini pour un texte en blanc
        navigationController?.navigationBar.barStyle = .black
    }
    // MARK: - Private Methods
    private func loadInitialData() {
        Task {
            do {
                try await loadGraphs(for: .results)
            } catch {
                print("Error loading initial data: \(error)")
                await MainActor.run {
                    self.showAlert(
                        title: "Error", message: "Failed to load initial data")
                }
            }
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)  // Dark background

        thematicSegmentedControl.backgroundColor = .clear
        thematicSegmentedControl.selectedSegmentTintColor = UIColor(
            red: 0.8, green: 0.1, blue: 0.1, alpha: 0.8)
        thematicSegmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.white], for: .normal)
        thematicSegmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.black], for: .selected)
        thematicSegmentedControl.addTarget(
            self, action: #selector(thematicChanged), for: .valueChanged)

        filterButton.backgroundColor = UIColor(
            red: 0.8, green: 0.1, blue: 0.1, alpha: 0.8)
        filterButton.setTitleColor(.white, for: .normal)
        filterButton.layer.cornerRadius = 5
        filterButton.addTarget(
            self, action: #selector(showFilters), for: .touchUpInside)

        applyNeonEffect(to: filterButton)
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        layout.sectionInset = UIEdgeInsets(
            top: 20, left: 20, bottom: 20, right: 20)

        let totalWidth = view.bounds.width
        let cellWidth =
            (totalWidth - layout.minimumInteritemSpacing
                - layout.sectionInset.left - layout.sectionInset.right) / 2
        let cellHeight: CGFloat = 300

        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)

        graphCollectionView.collectionViewLayout = layout
        graphCollectionView.delegate = self
        graphCollectionView.dataSource = self
        graphCollectionView.register(
            GraphCollectionViewCell.self,
            forCellWithReuseIdentifier: "GraphCell")
        graphCollectionView.backgroundColor = .clear
    }

    private func applyNeonEffect(to view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor
        view.layer.shadowColor =
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.5).cgColor
        view.layer.shadowRadius = 5.0
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
    }

    @objc private func thematicChanged() {
        currentThematic =
            Thematic(rawValue: thematicSegmentedControl.selectedSegmentIndex)
            ?? .results
        Task {
            do {
                try await loadGraphs(for: currentThematic)

                // Log thematic change
                Analytics.logEvent(
                    "thematic_changed",
                    parameters: [
                        "new_thematic": String(describing: currentThematic)
                    ])
            } catch {
                print("Error changing thematic: \(error)")
                showAlert(
                    title: "Error",
                    message: "Failed to load graphs for the selected thematic")
            }
        }
    }

    @objc private func showFilters() {
        let filterVC = FilterViewController()
        filterVC.delegate = self
        present(filterVC, animated: true, completion: nil)

        // Log filter button tap
        Analytics.logEvent("show_filters_tapped", parameters: nil)
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

        // Log graphs loaded
        Analytics.logEvent(
            "graphs_loaded",
            parameters: [
                "thematic": String(describing: thematic),
                "graph_count": graphs.count,
            ])
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title, message: message, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension AnalysisDashboardViewController: UICollectionViewDelegate,
    UICollectionViewDataSource
{
    func collectionView(
        _ collectionView: UICollectionView, numberOfItemsInSection section: Int
    ) -> Int {
        return graphs.count
    }

    func collectionView(
        _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: "GraphCell", for: indexPath)
            as! GraphCollectionViewCell
        let graph = graphs[indexPath.item]
        cell.configure(with: graph)
        applyNeonEffect(to: cell.contentView)
        return cell
    }
}

// MARK: - FilterViewControllerDelegate
extension AnalysisDashboardViewController: FilterViewControllerDelegate {
    func didApplyFilters(_ filters: [String: Any]) {
        print("Applied filters: \(filters)")
        self.applyFilters(filters)

        // Log filter application
        Analytics.logEvent(
            "filters_applied",
            parameters: [
                "filter_count": filters.count
            ])
    }

    func applyFilters(_ newFilters: [String: Any]) {
        self.filters = newFilters
        Task {
            do {
                try await loadGraphs(for: currentThematic)
            } catch {
                print("Error applying filters: \(error)")
                showAlert(title: "Error", message: "Failed to apply filters")
            }
        }
    }

    // MARK: - Graph Generation Methods
    private func generateVictoryRatioGraph() async throws -> GraphConfiguration
    {
        print("Generating Victory Ratio Graph")
        let filteredFights = try await FirebaseService.shared
            .fetchFilteredFights(
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

        let victories = filteredFights.filter {
            $0.fightResult?.winner == filters["fighter"] as? String
        }.count
        let totalFights = filteredFights.count

        let victoryRatio =
            totalFights > 0 ? Double(victories) / Double(totalFights) : 0

        print("Victory Ratio: \(victoryRatio)")

        // Create chart data
        let dataEntry = PieChartDataEntry(
            value: victoryRatio * 100, label: "Victory")
        let lossEntry = PieChartDataEntry(
            value: (1 - victoryRatio) * 100, label: "Loss")
        let dataSet = PieChartDataSet(
            entries: [dataEntry, lossEntry], label: "Victory Ratio")
        dataSet.colors = [.systemBlue, .systemRed]
        let data = PieChartData(dataSet: dataSet)

        return GraphConfiguration(
            title: "Victory Ratio", type: .pieChart, data: data)
    }

    private func generateFirstRoundWinImpactGraph() async throws
        -> GraphConfiguration
    {
        print("Generating First Round Win Impact Graph")
        let filteredFights = try await FirebaseService.shared
            .fetchFilteredFights(
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
            if let result = fight.fightResult,
                result.winner == filters["fighter"] as? String
            {
                totalWins += 1
                if let firstRoundId = fight.roundIds?.first {
                    let rounds = try await FirebaseService.shared.fetchRounds(
                        for: fight)
                    if let firstRound = rounds.first(where: {
                        $0.id == firstRoundId
                    }),
                        firstRound.roundWinner == filters["fighter"] as? String
                    {
                        firstRoundWins += 1
                    }
                }
            }
        }

        let firstRoundWinRatio =
            totalWins > 0 ? Double(firstRoundWins) / Double(totalWins) : 0

        print("First Round Win Ratio: \(firstRoundWinRatio)")

        // Create chart data
        let dataEntry1 = BarChartDataEntry(x: 0, y: firstRoundWinRatio * 100)
        let dataEntry2 = BarChartDataEntry(
            x: 1, y: (1 - firstRoundWinRatio) * 100)
        let dataSet = BarChartDataSet(
            entries: [dataEntry1, dataEntry2], label: "First Round Win Impact")
        dataSet.colors = [.systemGreen, .systemRed]
        let data = BarChartData(dataSet: dataSet)

        return GraphConfiguration(
            title: "First Round Win Impact", type: .barChart, data: data)
    }
    private func generateVictoryTypesGraph() async throws -> GraphConfiguration
    {
        print("Generating Victory Types Graph")
        let filteredFights = try await FirebaseService.shared
            .fetchFilteredFights()

        print("Filtered Fights: \(filteredFights.count)")

        var victoryTypes: [String: Int] = [:]

        for fight in filteredFights {
            print("Processing fight: \(fight.id ?? "Unknown")")
            let rounds = try await FirebaseService.shared.fetchRounds(
                for: fight)
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
            return GraphConfiguration(
                title: "No Data Available", type: .pieChart,
                data: PieChartData())
        }

        let dataSet = PieChartDataSet(
            entries: dataEntries, label: "Victory Types")
        dataSet.colors = ChartColorTemplates.material()
        let data = PieChartData(dataSet: dataSet)

        return GraphConfiguration(
            title: "Victory Types", type: .pieChart, data: data)
    }

}
