//
//  MWStripePurchaseCell.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 10/1/22.
//

import UIKit
import Foundation

class MWStripePurchaseCell: UITableViewCell {
    
    let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = 8
        
        self.contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -12)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stackView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    func configure(with item: PurchaseableItem) {
        
        var imageView: UIImageView?
        if let _ = item.imageURL {
            imageView = UIImageView()
            imageView!.contentMode = .scaleAspectFit
            imageView!.layer.cornerRadius = 4
            imageView!.layer.masksToBounds = true
            imageView!.translatesAutoresizingMaskIntoConstraints = false
            imageView!.widthAnchor.constraint(equalToConstant: 50).isActive = true
            imageView!.heightAnchor.constraint(equalToConstant: 50).isActive = true
            self.stackView.addArrangedSubview(imageView!)
        }
        
        let VStack = UIStackView()
        VStack.translatesAutoresizingMaskIntoConstraints = false
        VStack.alignment = .fill
        VStack.distribution = .fill
        VStack.axis = .vertical
        VStack.spacing = 4
        VStack.setContentCompressionResistancePriority(.required, for: .vertical)
        VStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.text = item.text
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        VStack.addArrangedSubview(titleLabel)
        
        var subtitleLabel: UILabel?
        if let detailText = item.detailText {
            subtitleLabel = UILabel()
            subtitleLabel!.translatesAutoresizingMaskIntoConstraints = false
            subtitleLabel!.numberOfLines = 0
            subtitleLabel!.text = detailText
            subtitleLabel!.font = .preferredFont(forTextStyle: .subheadline)
            subtitleLabel!.textColor = .secondaryLabel
            VStack.addArrangedSubview(subtitleLabel!)
        }
        
        self.stackView.addArrangedSubview(VStack)
        
        let amountLabel = UILabel()
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.numberOfLines = 1
        amountLabel.text = item.amount
        amountLabel.font = UIFont.preferredFont(forTextStyle: .title3, weight: .bold)
        amountLabel.sizeToFit()
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        amountLabel.textAlignment = .right
        self.stackView.addArrangedSubview(amountLabel)
    }
}
