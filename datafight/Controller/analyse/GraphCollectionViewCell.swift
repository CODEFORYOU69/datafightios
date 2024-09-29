import UIKit
import DGCharts

class GraphCollectionViewCell: UICollectionViewCell {
    
    let exportButton = UIButton(type: .system)

    
    private var chartView: ChartViewBase!
    private var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var chartContainerView: UIView!
    private var stackView: UIStackView!

    private func setupViews() {
           // Configurer titleLabel
           titleLabel = UILabel()
           titleLabel.translatesAutoresizingMaskIntoConstraints = false
           contentView.addSubview(titleLabel)

           // Configurer exportButton
        let downloadIcon = UIImage(systemName: "square.and.arrow.down")
            exportButton.setImage(downloadIcon, for: .normal)
            exportButton.tintColor = .systemBlue // Vous pouvez ajuster la couleur selon vos préférences
            exportButton.translatesAutoresizingMaskIntoConstraints = false
            exportButton.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
            contentView.addSubview(exportButton)

           // Ajouter les contraintes pour titleLabel
           NSLayoutConstraint.activate([
               titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
               titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
               titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
           ])
       }

    func configure(with graph: GraphConfiguration) {
           // Supprimer le chartView existant
           chartView?.removeFromSuperview()
        contentView.bringSubviewToFront(exportButton)


           // Créer un nouveau chartView en fonction du type
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

           // Configurer chartView
           chartView.translatesAutoresizingMaskIntoConstraints = false
           contentView.addSubview(chartView)
           contentView.sendSubviewToBack(chartView)

           // Ajouter les contraintes pour chartView
           NSLayoutConstraint.activate([
               chartView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
               chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
               chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
               chartView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
           ])

           // Mettre le exportButton au-dessus du chartView
           contentView.bringSubviewToFront(exportButton)

           // Ajouter les contraintes pour exportButton
        NSLayoutConstraint.activate([
            exportButton.topAnchor.constraint(equalTo: chartView.topAnchor, constant: 8),
            exportButton.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: 20),
            exportButton.widthAnchor.constraint(equalToConstant: 30),
            exportButton.heightAnchor.constraint(equalToConstant: 30)
        ])

           // Définir les données du graphique
           chartView.data = graph.data

           // Configurer le titre du graphique
           chartView.chartDescription.text = graph.title
           chartView.chartDescription.font = .systemFont(ofSize: 12)

           // Autres configurations spécifiques
           if let pieChart = chartView as? PieChartView {
               pieChart.entryLabelFont = .systemFont(ofSize: 10)
           }
       }

    @objc private func exportButtonTapped() {
        guard let pdfData = exportAsPDF(),
              let viewController = self.parentViewController() else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)

        // Définir le sourceView et le sourceRect pour iPad
        activityViewController.popoverPresentationController?.sourceView = exportButton
        activityViewController.popoverPresentationController?.sourceRect = exportButton.bounds

        viewController.present(activityViewController, animated: true, completion: nil)
    }


}

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
        UIGraphicsBeginImageContextWithOptions(chartView.bounds.size, false, 0.0)
        chartView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
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
