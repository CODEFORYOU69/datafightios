import DGCharts
import Firebase
import UIKit

class GraphCollectionViewCell: UICollectionViewCell {

    // MARK: - Properties
    let exportButton = UIButton(type: .system)
    private var chartView: ChartViewBase!
    private var titleLabel: UILabel!
    private var chartContainerView: UIView!
    private var stackView: UIStackView!

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Methods

    private func setupViews() {
        contentView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)

        // Configure titleLabel
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)

        // Configure exportButton
        let downloadIcon = UIImage(systemName: "square.and.arrow.down")
        exportButton.setImage(downloadIcon, for: .normal)
        exportButton.tintColor = UIColor(
            red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.addTarget(
            self, action: #selector(exportButtonTapped), for: .touchUpInside)
        contentView.addSubview(exportButton)

        // Add constraints for titleLabel and exportButton
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(
                equalTo: exportButton.leadingAnchor, constant: -8),

            exportButton.centerYAnchor.constraint(
                equalTo: titleLabel.centerYAnchor),
            exportButton.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -8),
            exportButton.widthAnchor.constraint(equalToConstant: 30),
            exportButton.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    // MARK: - Configuration
    func configure(with graph: GraphConfiguration) {
        // Remove existing chartView
        chartView?.removeFromSuperview()
        contentView.bringSubviewToFront(exportButton)

        // Create a new chartView based on the type
        switch graph.type {
        case .barChart:
            chartView = BarChartView()
        case .pieChart:
            chartView = PieChartView()
        case .lineChart:
            chartView = LineChartView()
        case .radarChart:
            chartView = RadarChartView()
        }

        // Configure chartView
        chartView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartView)
        contentView.sendSubviewToBack(chartView)

        // Add constraints for chartView
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: 8),
            chartView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 8),
            chartView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -8),
            chartView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor, constant: -8),
        ])

        // Bring exportButton to front
        contentView.bringSubviewToFront(exportButton)

        // Set chart data
        chartView.data = graph.data

        // Configure chart title
        titleLabel.text = graph.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white

        // Set chart background color to white
        chartView.backgroundColor = .white

        // Configure chart description
        chartView.chartDescription.text = ""
        chartView.chartDescription.font = .systemFont(ofSize: 12)
        chartView.chartDescription.textColor = .black

        // Other specific configurations
        if let pieChart = chartView as? PieChartView {
            pieChart.entryLabelFont = .systemFont(ofSize: 10)
            pieChart.entryLabelColor = .black
        }

        // Set legend text color to black for better visibility on white background
        chartView.legend.textColor = .black

        // Handle different chart types
        if let barLineChartView = chartView as? BarLineChartViewBase {
            barLineChartView.leftAxis.labelTextColor = .black
            barLineChartView.rightAxis.labelTextColor = .black
            barLineChartView.xAxis.labelTextColor = .black
            barLineChartView.xAxis.labelPosition = .bottom

            // Set grid lines to light gray for better visibility on white background
            barLineChartView.leftAxis.gridColor = .lightGray
            barLineChartView.rightAxis.gridColor = .lightGray
            barLineChartView.xAxis.gridColor = .lightGray
        }

        // Log chart configuration
        Analytics.logEvent(
            "chart_configured",
            parameters: [
                "chart_type": String(describing: graph.type),
                "chart_title": graph.title,
            ])
    }

    // MARK: - Export Actions
    @objc private func exportButtonTapped() {
        guard let pdfData = exportAsPDF(),
            let viewController = self.parentViewController()
        else {
            return
        }

        let activityViewController = UIActivityViewController(
            activityItems: [pdfData], applicationActivities: nil)

        // Set sourceView and sourceRect for iPad
        activityViewController.popoverPresentationController?.sourceView =
            exportButton
        activityViewController.popoverPresentationController?.sourceRect =
            exportButton.bounds

        viewController.present(
            activityViewController, animated: true, completion: nil)

        // Log export action
        Analytics.logEvent(
            "chart_export_tapped",
            parameters: [
                "export_format": "PDF",
                "chart_type": chartView.description,
            ])
    }
}

// MARK: - Export Extensions
extension GraphCollectionViewCell {
    func exportAsPDF() -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: chartView.bounds)
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            chartView.layer.render(in: context.cgContext)
        }
        return pdfData
    }

    func exportAsImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            chartView.bounds.size, false, 0.0)
        chartView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - UIView Extension
extension UIView {
    func parentViewController() -> UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
