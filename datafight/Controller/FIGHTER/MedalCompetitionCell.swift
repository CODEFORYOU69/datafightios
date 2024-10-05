//
//  MedalCompetitionCell.swift
//  datafight
//
//  Created by younes ouasmi on 05/10/2024.
//
import UIKit

class MedalCompetitionCell: UITableViewCell {
    @IBOutlet weak var competitionNameLabel: UILabel?
    @IBOutlet weak var medalImageView: UIImageView?
    @IBOutlet weak var fightCountLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margin: CGFloat = 5
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin))
    }
    
    private func setupCell() {
        backgroundColor = .clear
        
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        
        
        let glowLayer = CALayer()
        glowLayer.frame = contentView.bounds
        glowLayer.cornerRadius = 10
        glowLayer.shadowColor = UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.7).cgColor
        glowLayer.shadowOffset = CGSize.zero
        glowLayer.shadowRadius = 10
        glowLayer.shadowOpacity = 1.0
        contentView.layer.insertSublayer(glowLayer, at: 0)
        
        [competitionNameLabel, fightCountLabel].forEach { label in
            label?.textColor = .white
            label?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        }
    }
    
    func configure(with competition: MedalCompetition) {
        competitionNameLabel?.text = competition.competitionName
        competitionNameLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        fightCountLabel?.text = "Fights: \(competition.fightCount)"
        
        switch competition.medalColor {
        case .gold:
            medalImageView?.image = UIImage(named: "gold_medal")
            contentView.backgroundColor = UIColor(red: 0.3, green: 0.2, blue: 0.0, alpha: 1.0)
        case .silver:
            medalImageView?.image = UIImage(named: "silver_medal")
            contentView.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        case .bronze:
            medalImageView?.image = UIImage(named: "bronze_medal")
            contentView.backgroundColor = UIColor(red: 0.2, green: 0.1, blue: 0.0, alpha: 1.0)
        }
        
        medalImageView?.contentMode = .scaleAspectFit
    }}
