//
//  GraphConfigurationTests.swift
//  datafight
//
//  Created by younes ouasmi on 02/10/2024.
//


import XCTest
import DGCharts
@testable import datafight

class GraphConfigurationTests: XCTestCase {

    func testGraphConfigurationInitializationForBarChart() {
        // Préparer des données fictives pour le graphique
        let entries = [BarChartDataEntry(x: 1.0, y: 10.0), BarChartDataEntry(x: 2.0, y: 20.0)]
        let dataSet = BarChartDataSet(entries: entries, label: "Sample Data")
        let chartData = BarChartData(dataSet: dataSet)

        // Initialiser GraphConfiguration pour un barChart
        let graphConfig = GraphConfiguration(title: "Sample Bar Chart", type: .barChart, data: chartData)

        // Assertions pour vérifier les propriétés
        XCTAssertEqual(graphConfig.title, "Sample Bar Chart")
        XCTAssertEqual(graphConfig.type, .barChart)
        XCTAssertTrue(graphConfig.data is BarChartData)
    }

    func testGraphConfigurationInitializationForPieChart() {
        // Préparer des données fictives pour le graphique
        let entries = [PieChartDataEntry(value: 30, label: "Section 1"), PieChartDataEntry(value: 70, label: "Section 2")]
        let dataSet = PieChartDataSet(entries: entries, label: "Sample Data")
        let chartData = PieChartData(dataSet: dataSet)

        // Initialiser GraphConfiguration pour un pieChart
        let graphConfig = GraphConfiguration(title: "Sample Pie Chart", type: .pieChart, data: chartData)

        // Assertions pour vérifier les propriétés
        XCTAssertEqual(graphConfig.title, "Sample Pie Chart")
        XCTAssertEqual(graphConfig.type, .pieChart)
        XCTAssertTrue(graphConfig.data is PieChartData)
    }

    func testGraphConfigurationInitializationForRadarChart() {
        // Préparer des données fictives pour le graphique
        let entries = [RadarChartDataEntry(value: 5), RadarChartDataEntry(value: 8)]
        let dataSet = RadarChartDataSet(entries: entries, label: "Sample Data")
        let chartData = RadarChartData(dataSet: dataSet)

        // Initialiser GraphConfiguration pour un radarChart
        let graphConfig = GraphConfiguration(title: "Sample Radar Chart", type: .radarChart, data: chartData)

        // Assertions pour vérifier les propriétés
        XCTAssertEqual(graphConfig.title, "Sample Radar Chart")
        XCTAssertEqual(graphConfig.type, .radarChart)
        XCTAssertTrue(graphConfig.data is RadarChartData)
    }

    func testGraphConfigurationInitializationForLineChart() {
        // Préparer des données fictives pour le graphique
        let entries = [ChartDataEntry(x: 1.0, y: 100.0), ChartDataEntry(x: 2.0, y: 200.0)]
        let dataSet = LineChartDataSet(entries: entries, label: "Sample Data")
        let chartData = LineChartData(dataSet: dataSet)

        // Initialiser GraphConfiguration pour un lineChart
        let graphConfig = GraphConfiguration(title: "Sample Line Chart", type: .lineChart, data: chartData)

        // Assertions pour vérifier les propriétés
        XCTAssertEqual(graphConfig.title, "Sample Line Chart")
        XCTAssertEqual(graphConfig.type, .lineChart)
        XCTAssertTrue(graphConfig.data is LineChartData)
    }

    func testInvalidChartDataType() {
        // Tester un cas invalide où le type de graphique ne correspond pas aux données (ex: utiliser BarChartData pour un pieChart)
        let entries = [BarChartDataEntry(x: 1.0, y: 10.0), BarChartDataEntry(x: 2.0, y: 20.0)]
        let dataSet = BarChartDataSet(entries: entries, label: "Invalid Data")
        let chartData = BarChartData(dataSet: dataSet)

        // Initialiser avec un mauvais type
        let graphConfig = GraphConfiguration(title: "Invalid Pie Chart", type: .pieChart, data: chartData)

        // S'assurer que les données sont incorrectes pour le type spécifié
        XCTAssertEqual(graphConfig.title, "Invalid Pie Chart")
        XCTAssertEqual(graphConfig.type, .pieChart)
        XCTAssertFalse(graphConfig.data is PieChartData)
    }
}
