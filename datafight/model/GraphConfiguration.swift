//
//  GraphConfiguration.swift
//  datafight
//
//  Created by younes ouasmi on 21/09/2024.
//

import DGCharts
import Foundation

enum GraphType {
    case barChart, pieChart, radarChart, lineChart
}

struct GraphConfiguration {
    let title: String
    let type: GraphType
    let data: ChartData  // Ajoutez cette ligne

    init(title: String, type: GraphType, data: ChartData) {
        self.title = title
        self.type = type
        self.data = data
    }
}
