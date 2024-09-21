        //
        //  GraphData.swift
        //  datafight
        //
        //  Created by younes ouasmi on 12/09/2024.
        //
        //
        //  GraphData.swift
        //  datafight
        //
        //  Created by younes ouasmi on 12/09/2024.
        //

        import UIKit
        import Foundation
        import FirebaseFirestore
        import Firebase
        import DGCharts


    struct GraphConfiguration: Codable {
        @DocumentID var id: String?
        var name: String
        var visualizationType: VisualizationType
        var dataConfigurations: [ConfiguredData]
        var userId: String?

        var chartOptions: ChartOptions = ChartOptions(title: "", xAxisLabel: "", yAxisLabel: "", legendEnabled: false, animationEnabled: false)
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case visualizationType
            case dataConfigurations
            case userId
            case chartOptions
        }

        init(id: String? = nil, name: String, visualizationType: VisualizationType, dataConfigurations: [ConfiguredData], userId: String? = nil, chartOptions: ChartOptions) {
            self.id = id
            self.name = name
            self.visualizationType = visualizationType
            self.dataConfigurations = dataConfigurations
            self.userId = userId
            self.chartOptions = chartOptions
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIfPresent(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            visualizationType = try container.decode(VisualizationType.self, forKey: .visualizationType)
            dataConfigurations = try container.decode([ConfiguredData].self, forKey: .dataConfigurations)
            userId = try container.decodeIfPresent(String.self, forKey: .userId)
            chartOptions = try container.decode(ChartOptions.self, forKey: .chartOptions)        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(visualizationType, forKey: .visualizationType)
            try container.encode(dataConfigurations, forKey: .dataConfigurations)
            try container.encodeIfPresent(userId, forKey: .userId)
        }
    }



struct ChartOptions: Codable {
    var title: String
    var xAxisLabel: String
    var yAxisLabel: String
    var legendEnabled: Bool
    var animationEnabled: Bool
    var barChartOptions: BarChartOptions?
    var lineChartOptions: LineChartOptions?
    var pieChartOptions: PieChartOptions?
    var scatterPlotOptions: ScatterPlotOptions?
    var radarChartOptions: RadarChartOptions?

    init(
        title: String = "",
        xAxisLabel: String = "",
        yAxisLabel: String = "",
        legendEnabled: Bool = false,
        animationEnabled: Bool = false,
        barChartOptions: BarChartOptions? = nil,
        lineChartOptions: LineChartOptions? = nil,
        pieChartOptions: PieChartOptions? = nil,
        scatterPlotOptions: ScatterPlotOptions? = nil,
        radarChartOptions: RadarChartOptions? = nil
    ) {
        self.title = title
        self.xAxisLabel = xAxisLabel
        self.yAxisLabel = yAxisLabel
        self.legendEnabled = legendEnabled
        self.animationEnabled = animationEnabled
        self.barChartOptions = barChartOptions
        self.lineChartOptions = lineChartOptions
        self.pieChartOptions = pieChartOptions
        self.scatterPlotOptions = scatterPlotOptions
        self.radarChartOptions = radarChartOptions
    }
}

    // Structures pour les options spécifiques à chaque type de graphique
struct BarChartOptions: Codable{
        var isHorizontal: Bool
        var groupSpacing: Double
        var showValuesOnBars: Bool
    }

struct LineChartOptions: Codable {
    var lineType: LineType
    var lineWidth: Double
    var fillEnabled: Bool

    // Initialiseur membre explicite
    init(lineType: LineType, lineWidth: Double, fillEnabled: Bool) {
        self.lineType = lineType
        self.lineWidth = lineWidth
        self.fillEnabled = fillEnabled
    }

    enum CodingKeys: String, CodingKey {
        case lineType
        case lineWidth
        case fillEnabled
    }

    // Méthodes d'encodage et de décodage personnalisées
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lineType = try container.decode(LineType.self, forKey: .lineType)
        lineWidth = try container.decode(Double.self, forKey: .lineWidth)
        fillEnabled = try container.decode(Bool.self, forKey: .fillEnabled)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lineType, forKey: .lineType)
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encode(fillEnabled, forKey: .fillEnabled)
    }
}



    struct PieChartOptions: Codable {
        var holeRadius: CGFloat
        var showPercentages: Bool
    }
enum LineType: String, Codable {
    case straight
    case curved
    case stepped
}

struct ScatterPlotOptions: Codable {
    private var shapeTypeRawValue: Int
    var showTrendLine: Bool
    
    var shapeType: ScatterChartDataSet.Shape {
        get {
            return ScatterChartDataSet.Shape(rawValue: shapeTypeRawValue) ?? .circle
        }
        set {
            shapeTypeRawValue = newValue.rawValue
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case shapeTypeRawValue = "shapeType"
        case showTrendLine
    }
    
    init(shapeType: ScatterChartDataSet.Shape, showTrendLine: Bool) {
        self.shapeTypeRawValue = shapeType.rawValue
        self.showTrendLine = showTrendLine
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        shapeTypeRawValue = try container.decode(Int.self, forKey: .shapeTypeRawValue)
        showTrendLine = try container.decode(Bool.self, forKey: .showTrendLine)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shapeTypeRawValue, forKey: .shapeTypeRawValue)
        try container.encode(showTrendLine, forKey: .showTrendLine)
    }
}

    struct RadarChartOptions: Codable {
        var fillEnabled: Bool
        var rotationEnabled: Bool
    }


        enum SelectionValue: Codable {
            case string(String)
            case int(Int)
            case double(Double)
            case bool(Bool)
            case date(Date)
            // Ajoutez d'autres types si nécessaire

            enum CodingKeys: String, CodingKey {
                case type
                case value
            }

            enum ValueType: String, Codable {
                case string
                case int
                case double
                case bool
                case date
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case .string(let value):
                    try container.encode(ValueType.string, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .int(let value):
                    try container.encode(ValueType.int, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .double(let value):
                    try container.encode(ValueType.double, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .bool(let value):
                    try container.encode(ValueType.bool, forKey: .type)
                    try container.encode(value, forKey: .value)
                case .date(let value):
                    try container.encode(ValueType.date, forKey: .type)
                    try container.encode(value, forKey: .value)
                }
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(ValueType.self, forKey: .type)
                switch type {
                case .string:
                    let value = try container.decode(String.self, forKey: .value)
                    self = .string(value)
                case .int:
                    let value = try container.decode(Int.self, forKey: .value)
                    self = .int(value)
                case .double:
                    let value = try container.decode(Double.self, forKey: .value)
                    self = .double(value)
                case .bool:
                    let value = try container.decode(Bool.self, forKey: .value)
                    self = .bool(value)
                case .date:
                    let value = try container.decode(Date.self, forKey: .value)
                    self = .date(value)
                }
            }
        }

            
    struct AnalysisParameter: Codable {
        var mainEntity: EntityType
        var specificEntityId: String?
        var relatedEntity: EntityType?
        var selections: [Selection] = []
        var filters: [Filter] = []
    }

        struct Selection: Codable {
            var attribute: Attribute
            var value: SelectionValue
        }

        struct Filter: Codable {
            var field: String
            var attribute: Attribute
            var operation: FilterOperation
            var value: SelectionValue
        }

        enum FilterOperation: String, Codable, CaseIterable {
            case equalTo = "Égal à"
            case notEqualTo = "Différent de"
            case greaterThan = "Supérieur à"
            case lessThan = "Inférieur à"
            case contains = "Contient"
        }

        struct Comparison: Codable {
            var parameters: [AnalysisParameter]
            var measure: Measure
            var dateRange: DateRange?
        }

        struct DateRange: Codable {
            var startDate: Date?
            var endDate: Date?
        }

    enum VisualizationType: String, Codable, CaseIterable {
        case barChart = "Graphique en barres"
        case lineChart = "Graphique en ligne"
        case pieChart = "Graphique circulaire"
        case scatterPlot = "Nuage de points"
        case radarChart = "Graphique radar"
        var imageName: String {
            switch self {
            case .barChart: return "bar_chart_example"
            case .lineChart: return "line_chart_example"
            case .pieChart: return "pie_chart_example"
            case .scatterPlot: return "scatter_plot_example"
            case .radarChart: return "radar_chart_example"
            }
        }
    }
        struct Measure: Codable {
            var type: MeasureType
            var field: Attribute?
            var groupBy: Attribute?
        }

        enum MeasureType: String, CaseIterable, Codable {
            case count = "Count"
            case sum = "Sum"
            case average = "Average"
        }

        enum EntityType: String, Codable, CaseIterable  {
            case fighter = "fighters"
            case fight = "fights"
            case category = "Category"
            case weightCategory = "weight Category"
            case gender = "gender"
            case eventType = "event type"
            case event = "event"
            case actionType = "action type"
            case round = "Round"
            case actionMoment = "actionmoment"
            case action = "action"
        }
        enum AgeCategoryAttribute: String, Codable, CaseIterable {
            case ageCategory = "Age category"
            
            var databaseKey: String {
                return "Category"
            }
        }
        enum WeightCategoryAttribute: String, Codable, CaseIterable {
            case weightCategory = "weight category"
            
            var databaseKey: String {
                return "weightCategory"
            }
        }
        enum GenderAttribute: String, Codable, CaseIterable {
            case gender = "Gender"
            
            var databaseKey: String {
                return "gender"
            }
        }
        enum EventTypeAttribute: String, Codable, CaseIterable {
            case eventType = "Event type"
            
            var databaseKey: String {
                return "eventType"
            }
        }
        enum ActionTypeAttribute: String, Codable, CaseIterable {
            case actionType = "Type d'action"
            
            var databaseKey: String {
                return "actionType"
            }
        }



        enum Attribute: Codable {
            
            
            case fighter(FighterAttribute)
                case event(EventAttribute)
                case fight(FightAttribute)
                case round(RoundAttribute)
                case action(ActionAttribute)
                case ageCategory(AgeCategoryAttribute)
                case weightCategory(WeightCategoryAttribute)
                case gender(GenderAttribute)
                case eventType(EventTypeAttribute)
                case actionType(ActionTypeAttribute)
            var displayName: String {
                    switch self {
                    case .fighter(let attr):
                        return attr.rawValue
                    case .event(let attr):
                        return attr.rawValue
                    case .fight(let attr):
                        return attr.rawValue
                    case .round(let attr):
                        return attr.rawValue
                    case .action(let attr):
                        return attr.rawValue
                    case .ageCategory(let attr):
                        return attr.rawValue
                    case .weightCategory(let attr):
                        return attr.rawValue
                    case .gender(let attr):
                        return attr.rawValue
                    case .eventType(let attr):
                        return attr.rawValue
                    case .actionType(let attr):
                        return attr.rawValue
                    }
                }

                var databaseKey: String {
                    switch self {
                    case .fighter(let attr):
                        return attr.databaseKey
                    case .event(let attr):
                        return attr.databaseKey
                    case .fight(let attr):
                        return attr.databaseKey
                    case .round(let attr):
                        return attr.databaseKey
                    case .action(let attr):
                        return attr.databaseKey
                    case .ageCategory(let attr):
                        return attr.databaseKey
                    case .weightCategory(let attr):
                        return attr.databaseKey
                    case .gender(let attr):
                        return attr.databaseKey
                    case .eventType(let attr):
                        return attr.databaseKey
                    case .actionType(let attr):
                        return attr.databaseKey
                    }
                    
                    
                }
            enum CodingKeys: String, CodingKey {
                case type
                case value
            }

            enum AttributeType: String, Codable {
                    case fighter
                    case event
                    case fight
                    case round
                    case action
                    case ageCategory
                    case weightCategory
                    case gender
                    case eventType
                    case actionType
                }

            func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    switch self {
                    case .fighter(let value):
                        try container.encode(AttributeType.fighter, forKey: .type)
                        try container.encode(value, forKey: .value)
                    case .event(let value):
                        try container.encode(AttributeType.event, forKey: .type)
                        try container.encode(value, forKey: .value)
                    case .fight(let value):
                        try container.encode(AttributeType.fight, forKey: .type)
                        try container.encode(value, forKey: .value)
                    case .round(let value):
                        try container.encode(AttributeType.round, forKey: .type)
                        try container.encode(value, forKey: .value)
                    case .action(let value):
                        try container.encode(AttributeType.action, forKey: .type)
                        try container.encode(value, forKey: .value)
                    case .ageCategory(let value):
                        try container.encode(AttributeType.ageCategory, forKey: .type)
                        try container.encode(value, forKey: .value)
                    case .weightCategory(let value):
                        try container.encode(AttributeType.weightCategory, forKey: .type)
                        try container.encode(value, forKey: .value)
                    case .gender(let value):
                        try container.encode(AttributeType.gender, forKey: .type)
                        try container.encode(value, forKey: .value)
                    case .eventType(let value):
                        try container.encode(AttributeType.eventType, forKey: .type)
                        try container.encode(value, forKey: .value)
                    case .actionType(let value):
                        try container.encode(AttributeType.actionType, forKey: .type)
                        try container.encode(value, forKey: .value)
                    }
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let type = try container.decode(AttributeType.self, forKey: .type)
                    switch type {
                    case .fighter:
                        let value = try container.decode(FighterAttribute.self, forKey: .value)
                        self = .fighter(value)
                    case .event:
                        let value = try container.decode(EventAttribute.self, forKey: .value)
                        self = .event(value)
                    case .fight:
                        let value = try container.decode(FightAttribute.self, forKey: .value)
                        self = .fight(value)
                    case .round:
                        let value = try container.decode(RoundAttribute.self, forKey: .value)
                        self = .round(value)
                    case .action:
                        let value = try container.decode(ActionAttribute.self, forKey: .value)
                        self = .action(value)
                    case .ageCategory:
                        let value = try container.decode(AgeCategoryAttribute.self, forKey: .value)
                        self = .ageCategory(value)
                    case .weightCategory:
                        let value = try container.decode(WeightCategoryAttribute.self, forKey: .value)
                        self = .weightCategory(value)
                    case .gender:
                        let value = try container.decode(GenderAttribute.self, forKey: .value)
                        self = .gender(value)
                    case .eventType:
                        let value = try container.decode(EventTypeAttribute.self, forKey: .value)
                        self = .eventType(value)
                    case .actionType:
                        let value = try container.decode(ActionTypeAttribute.self, forKey: .value)
                        self = .actionType(value)
                    }
                }
            }


        enum FighterAttribute: String, Codable, CaseIterable {
            case id  // Ajoutez ce cas si nécessaire
            case firstName = "Prénom"
            case lastName = "Nom"
            case gender = "Genre"
            case birthdate = "Date de naissance"
            case country = "Pays"
            case fightIds = "IDs des combats"
            // Ajoutez d'autres attributs si nécessaire

            var databaseKey: String {
                switch self {
                case .id:
                    return "fighter id"
                case .firstName:
                    return "firstName"
                case .lastName:
                    return "lastName"
                case .gender:
                    return "gender"
                case .birthdate:
                    return "birthdate"
                case .country:
                    return "country"
                case .fightIds:
                    return "fightIds"
                }
            }
        }

    struct ConfiguredData: Codable {
        var parameters: [AnalysisParameter] = []  // Regroupe les paramètres associés ensemble
    }

    class GraphConfigurationBuilder {
        var configuredData: [ConfiguredData] = []  // Liste des données configurées
        var currentData = ConfiguredData()  // La donnée en cours de configuration
        var visualizationType: VisualizationType?
        var name: String = "Configuration \(Date())"
        var chartOptions: ChartOptions = ChartOptions(title: "", xAxisLabel: "", yAxisLabel: "", legendEnabled: false, animationEnabled: false)
        
        func getMinimumRequiredDataCount() -> Int {
            guard let visualizationType = visualizationType else { return 1 }
            switch visualizationType {
            case .barChart, .lineChart, .pieChart:
                return 1
            case .scatterPlot:
                return 2
            case .radarChart:
                return 3
            }
        }

        func buildGraphConfiguration() -> GraphConfiguration? {
            guard let visualizationType = visualizationType else { return nil }
            return GraphConfiguration(
                name: name,
                visualizationType: visualizationType,
                dataConfigurations: configuredData,
                chartOptions: chartOptions
            )
        }

        func logConfiguredData() {
            print("===== LOG DES DONNÉES CONFIGURÉES =====")
            for (index, data) in configuredData.enumerated() {
                print("Donnée \(index + 1):")
                for (paramIndex, parameter) in data.parameters.enumerated() {
                    print("  Paramètre \(paramIndex + 1):")
                    print("    Entité: \(parameter.mainEntity.rawValue)")
                    print("    Sélections:")
                    for selection in parameter.selections {
                        print("    - \(selection.attribute.displayName) : \(selection.value)")
                    }
                    print("    Filtres:")
                    for filter in parameter.filters {
                        print("    - \(filter.attribute.displayName) \(filter.operation.rawValue) \(filter.value)")
                    }
                }
                print("=========================================\n")
            }
            
            print("===== OPTIONS DU GRAPHIQUE =====")
            print("Type de visualisation: \(visualizationType?.rawValue ?? "Non défini")")
            print("Titre: \(chartOptions.title)")
            print("Label axe X: \(chartOptions.xAxisLabel)")
            print("Label axe Y: \(chartOptions.yAxisLabel)")
            print("Légende activée: \(chartOptions.legendEnabled)")
            print("Animation activée: \(chartOptions.animationEnabled)")
            
            switch visualizationType {
            case .barChart:
                if let options = chartOptions.barChartOptions {
                    print("Options du graphique à barres:")
                    print("  Orientation: \(options.isHorizontal ? "Horizontale" : "Verticale")")
                    print("  Espacement des groupes: \(options.groupSpacing)")
                    print("  Afficher les valeurs sur les barres: \(options.showValuesOnBars)")
                }
            case .lineChart:
                if let options = chartOptions.lineChartOptions {
                    print("Options du graphique en ligne:")
                    print("  Type de ligne: \(options.lineType)")
                    print("  Épaisseur de la ligne: \(options.lineWidth)")
                    print("  Remplissage activé: \(options.fillEnabled)")
                }
            case .pieChart:
                if let options = chartOptions.pieChartOptions {
                    print("Options du graphique circulaire:")
                    print("  Rayon du trou: \(options.holeRadius)")
                    print("  Afficher les pourcentages: \(options.showPercentages)")
                }
            case .scatterPlot:
                if let options = chartOptions.scatterPlotOptions {
                    print("Options du nuage de points:")
                    print("  Forme des points: \(options.shapeType)")
                    print("  Afficher la ligne de tendance: \(options.showTrendLine)")
                }
            case .radarChart:
                if let options = chartOptions.radarChartOptions {
                    print("Options du graphique radar:")
                    print("  Remplissage activé: \(options.fillEnabled)")
                    print("  Rotation activée: \(options.rotationEnabled)")
                }
            case .none:
                break
            }
            print("=========================================\n")
        }
    }
    struct DataConfiguration {
        var entityType: EntityType
        var attribute: Attribute
        var filter: Filter?
    }
        


    class GraphGenerator {
        func generateBarChart(data: [DataConfiguration], options: ChartOptions) -> BarChartView {
            let chartView = BarChartView()
            chartView.dragEnabled = true
            chartView.pinchZoomEnabled = true
            chartView.drawBarShadowEnabled = false
            
            if let barOptions = options.barChartOptions {
                chartView.drawValueAboveBarEnabled = barOptions.showValuesOnBars
                
                // Définir l'orientation
                if barOptions.isHorizontal {
                    chartView.xAxis.labelPosition = .bottom
                } else {
                    chartView.xAxis.labelPosition = .bottomInside
                }
                
                // Configurer l'espacement entre les groupes
                let groupSpace = barOptions.groupSpacing
                let barSpace = (1 - groupSpace) / Double(data.count) / 2
                chartView.barData?.barWidth = barSpace
            }
            
            // Configurer les données
            var dataEntries: [[BarChartDataEntry]] = []
            for (_, config) in data.enumerated() {
                let values = fetchValuesForConfiguration(config)
                let entries = values.enumerated().map { (i, value) in
                    BarChartDataEntry(x: Double(i), y: value)
                }
                dataEntries.append(entries)
            }
            
            let dataSets = dataEntries.enumerated().map { (index, entries) in
                let set = BarChartDataSet(entries: entries, label: "Dataset \(index + 1)")
                set.colors = [ChartColorTemplates.material()[index % ChartColorTemplates.material().count]]
                return set
            }
            
            let chartData = BarChartData(dataSets: dataSets)
            chartView.data = chartData
            
            // Appliquer les options générales
            applyGeneralOptions(to: chartView, options: options)
            
            return chartView
        }

        func generateLineChart(data: [DataConfiguration], options: ChartOptions) -> LineChartView {
            let chartView = LineChartView()
            
            var dataEntries: [[ChartDataEntry]] = []
            for (_, config) in data.enumerated() {
                let values = fetchValuesForConfiguration(config)
                let entries = values.enumerated().map { (i, value) in
                    ChartDataEntry(x: Double(i), y: value)
                }
                dataEntries.append(entries)
            }
            
            let dataSets = dataEntries.enumerated().map { (index, entries) in
                let set = LineChartDataSet(entries: entries, label: "Dataset \(index + 1)")
                set.colors = [ChartColorTemplates.material()[index % ChartColorTemplates.material().count]]
                
                if let lineOptions = options.lineChartOptions {
                    set.lineWidth = lineOptions.lineWidth
                    set.mode = lineOptions.lineType == .curved ? .cubicBezier : .linear
                    set.drawFilledEnabled = lineOptions.fillEnabled
                }
                
                return set
            }
            
            let chartData = LineChartData(dataSets: dataSets)
            chartView.data = chartData
            
            // Appliquer les options générales
            applyGeneralOptions(to: chartView, options: options)
            
            return chartView
        }

        func generatePieChart(data: [DataConfiguration], options: ChartOptions) -> PieChartView {
            let chartView = PieChartView()
            
            let values = fetchValuesForConfiguration(data[0])
            let entries = values.enumerated().map { (index, value) in
                PieChartDataEntry(value: value, label: "Label \(index + 1)")
            }
            
            let dataSet = PieChartDataSet(entries: entries, label: "")
            dataSet.colors = ChartColorTemplates.vordiplom()
            
            if let pieOptions = options.pieChartOptions {
                chartView.holeRadiusPercent = pieOptions.holeRadius
                
                if pieOptions.showPercentages {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .percent
                    formatter.maximumFractionDigits = 1
                    formatter.multiplier = 1
                    dataSet.valueFormatter = DefaultValueFormatter(formatter: formatter)
                }
            }
            
            let chartData = PieChartData(dataSet: dataSet)
            chartView.data = chartData
            
            // Appliquer les options générales
            applyGeneralOptionsToChartView(chartView, options: options)

            return chartView
        }
        
        private func applyGeneralOptionsToChartView(_ chartView: ChartViewBase, options: ChartOptions) {
            chartView.chartDescription.text = options.title
            chartView.legend.enabled = options.legendEnabled
            
            if options.animationEnabled {
                chartView.animate(xAxisDuration: 1.5, yAxisDuration: 1.5)
            }
        }

        func generateScatterPlot(data: [DataConfiguration], options: ChartOptions) -> ScatterChartView {
            let chartView = ScatterChartView()
            
            guard data.count >= 2 else { return chartView }
            
            let xValues = fetchValuesForConfiguration(data[0])
            let yValues = fetchValuesForConfiguration(data[1])
            
            let entries = zip(xValues, yValues).map { ChartDataEntry(x: $0, y: $1) }
            
            let dataSet = ScatterChartDataSet(entries: entries, label: "Data")
            dataSet.colors = [.blue]
            
            if let scatterOptions = options.scatterPlotOptions {
                dataSet.setScatterShape(scatterOptions.shapeType)
                
                if scatterOptions.showTrendLine {
                    // Ajoutez ici la logique pour afficher la ligne de tendance
                }
            }
            
            let chartData = ScatterChartData(dataSet: dataSet)
            chartView.data = chartData
            
            // Appliquer les options générales
            applyGeneralOptions(to: chartView, options: options)
            
            return chartView
        }

        func generateRadarChart(data: [DataConfiguration], options: ChartOptions) -> RadarChartView {
            let chartView = RadarChartView()
            
            var dataEntries: [RadarChartDataEntry] = []
            for config in data {
                let values = fetchValuesForConfiguration(config)
                let entries = values.map { RadarChartDataEntry(value: $0) }
                dataEntries.append(contentsOf: entries)
            }
            
            let dataSet = RadarChartDataSet(entries: dataEntries, label: "Data")
            dataSet.colors = [.blue]
            dataSet.fillColor = .blue.withAlphaComponent(0.5)
            
            if let radarOptions = options.radarChartOptions {
                dataSet.drawFilledEnabled = radarOptions.fillEnabled
                chartView.rotationEnabled = radarOptions.rotationEnabled
            }
            
            let chartData = RadarChartData(dataSet: dataSet)
            chartView.data = chartData
            
            // Appliquer les options générales
            applyGeneralOptionsToChartView(chartView, options: options)

            return chartView
        }

        private func applyGeneralOptions(to chartView: BarLineChartViewBase, options: ChartOptions) {
            chartView.chartDescription.text = options.title
            chartView.xAxis.axisMinimum = 0
            chartView.leftAxis.axisMinimum = 0
            
            chartView.xAxis.labelPosition = .bottom
            chartView.xAxis.labelFont = .systemFont(ofSize: 10)
            chartView.leftAxis.labelFont = UIFont.systemFont(ofSize: 10)
            chartView.legend.enabled = options.legendEnabled
            
            if options.animationEnabled {
                chartView.animate(xAxisDuration: 1.5, yAxisDuration: 1.5)
            }
        }

        private func fetchValuesForConfiguration(_ config: DataConfiguration) -> [Double] {
            // Implémentez cette méthode pour récupérer les vraies données
            return (0..<10).map { _ in Double.random(in: 0...100) }
        }

        // Helper method to fetch value for a configuration
        private func fetchValueForConfiguration(_ config: DataConfiguration) -> Double {
            // Implement the logic to fetch the actual value based on the configuration
            // This might involve querying your data source (e.g., Firebase)
            return Double.random(in: 0...100) // Placeholder
        }

       
    }
        enum EventAttribute: String, CaseIterable, Codable {
            case id  // Ajoutez ce cas si nécessaire
            case eventName = "Nom de l'événement"
            case eventType = "Type d'événement"
            case location = "Lieu"
            case date = "Date"
            case fightIds = "IDs des combats"
            case country = "Pays"

            var databaseKey: String {
                switch self {
                case .id:
                    return " event Id "
                case .eventName:
                    return "eventName"
                case .eventType:
                    return "eventType"
                case .location:
                    return "location"
                case .date:
                    return "date"
                case .fightIds:
                    return "fightIds"
                case .country:
                    return "country"
                }
            }
        }


        enum FightAttribute: String, CaseIterable, Codable {
            case id  // Ajoutez ce cas si nécessaire
            case eventId = "ID de l'événement"
            case fightNumber = "Numéro du combat"
            case blueFighterId = "ID du combattant bleu"
            case redFighterId = "ID du combattant rouge"
            case category = "Catégorie"
            case weightCategory = "Catégorie de poids"
            case round = "Round"
            case isOlympic = "Est olympique"
            case roundIds = "IDs des rounds"
            case fightResult = "Résultat du combat"
            case blueVideoReplayUsed = "Replay vidéo utilisé (bleu)"
            case redVideoReplayUsed = "Replay vidéo utilisé (rouge)"
            case videoId = "ID de la vidéo"
            case creatorUserId = "ID du créateur"
            // Ajoutez d'autres attributs si nécessaire

            var databaseKey: String {
                switch self {
                case .id:
                    return "fight id"
                case .eventId:
                    return "eventId"
                case .fightNumber:
                    return "fightNumber"
                case .blueFighterId:
                    return "blueFighterId"
                case .redFighterId:
                    return "redFighterId"
                case .category:
                    return "category"
                case .weightCategory:
                    return "weightCategory"
                case .round:
                    return "round"
                case .isOlympic:
                    return "isOlympic"
                case .roundIds:
                    return "roundIds"
                case .fightResult:
                    return "fightResult"
                case .blueVideoReplayUsed:
                    return "blueVideoReplayUsed"
                case .redVideoReplayUsed:
                    return "isCompleted"
                case .videoId:
                    return "videoId"
                case .creatorUserId:
                    return "creatorUserId"
                }
            }
        }


        enum RoundAttribute: String, CaseIterable, Codable {
            case roundNumber = "Numéro du round"
            case chronoDuration = "Durée du chrono"
            case duration = "Durée réelle du round avec temps d'arret"
            case roundTime = "temps d'un round"
            case blueFighterId = "ID du combattant bleu"
            case redFighterId = "ID du combattant rouge"
            case isSynced = "Est synchronisé"
            case victoryDecision = "Décision de victoire"
            case roundWinner = "Gagnant du round"
            case blueHits = "Touches bleues"
            case redHits = "Touches rouges"
            case startTime = "Heure de début"
            case endTime = "Heure de fin"
            case blueScore = "Score bleu"
            case redScore = "Score rouge"
            case actions = "Actions"

            var databaseKey: String {
                switch self {
                case .roundNumber:
                    return "roundNumber"
                case .chronoDuration:
                    return "chronoDuration"
                case .duration:
                    return "duration"
                case .roundTime:
                    return "roundTime"
                case .blueFighterId:
                    return "blueFighterId"
                case .redFighterId:
                    return "redFighterId"
                case .isSynced:
                    return "isSynced"
                case .victoryDecision:
                    return "victoryDecision"
                case .roundWinner:
                    return "roundWinner"
                case .blueHits:
                    return "blueHits"
                case .redHits:
                    return "redHits"
                case .startTime:
                    return "startTime"
                case .endTime:
                    return "endTime"
                case .blueScore:
                    return "blueScore"
                case .redScore:
                    return "redScore"
                case .actions:
                    return "actions"
                }
            }
        }


        enum ActionAttribute: String, CaseIterable, Codable {
            case fighterId = "ID du combattant"
            case color = "Couleur"
            case actionType = "Type d'action"
            case technique = "Technique"
            case limbUsed = "Membre utilisé"
            case actionZone = "Zone d'action"
            case situation = "Situation de combat"
            case gamjeonType = "Type de Gamjeon"
            case guardPosition = "Position de garde"
            case isActive = "Est actif"
            case chronoTimestamp = "Horodatage chrono"
            case points = "points"  // Attribut virtuel

            // Ajoutez d'autres attributs si nécessaire

            var databaseKey: String {
                switch self {
                case .fighterId:
                    return "fighterId"
                case .points:
                    return "points"
                
                case .color:
                    
                    return "color"
                case .actionType:
                    return "actionType"
                case .technique:
                    return "technique"
                case .limbUsed:
                    return "limbUsed"
                case .actionZone:
                    return "actionZone"
                case .situation:
                    return "situation"
                case .gamjeonType:
                    return "gamjeonType"
                case .guardPosition:
                    return "guardPosition"
                case .isActive:
                    return "isActive"
                case .chronoTimestamp:
                    return "chronoTimestamp"
                }
            }
            
        }



        extension Attribute {
            static func from(entity: EntityType) -> Attribute? {
                switch entity {
                case .gender:
                    return .gender(.gender)
                case .eventType:
                    return .eventType(.eventType)
                case .actionType:
                    return .actionType(.actionType)
                default:
                    return nil
                }
            }
        }
    extension GraphConfigurationBuilder {
        func isValidDataCount(_ count: Int) -> Bool {
            return count >= getMinimumRequiredDataCount()
        }
    }
        extension SelectionValue {
        func toString() -> String? {
            switch self {
            case .string(let value):
                return value
            case .int(let value):
                return String(value)
            case .double(let value):
                return String(value)
            case .bool(let value):
                return String(value)
            case .date(let value):
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: value)
            }
        }

        func toBool() -> Bool? {
            switch self {
            case .bool(let value):
                return value
            case .string(let value):
                return value.lowercased() == "true"
            default:
                return nil
            }
        }
    }


