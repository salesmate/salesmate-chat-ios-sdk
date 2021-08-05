//
//  CirculerProfileView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 29/07/21.
//

import UIKit

class CirculerProfileView: UIView {

    var viewModel: CirculerProfileViewModelType? {
        didSet { display()  }
    }

    private let imageView = UIImageView()
    private let label = UILabel()

    init(viewModel: CirculerProfileViewModelType) {
        super.init(frame: CGRect.zero)
        self.viewModel = viewModel

        setup()
        display()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.width / 2.0
    }

    private func setup() {
        label.backgroundColor = .clear
        imageView.backgroundColor = .clear

        label.frame = self.bounds
        imageView.frame = self.bounds

        label.addAndFill(in: self)
        imageView.addAndFill(in: self)

        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center

        clipsToBounds = true
    }

    private func display() {
        guard let viewModel = viewModel else { return }

        label.isHidden = true
        imageView.isHidden = true

        backgroundColor = UIColor(hex: viewModel.backgroundColorCode)

        if let string = viewModel.text {
            label.isHidden = false
            label.text = string
            label.font = UIFont.systemFont(ofSize: CGFloat(viewModel.textSize), weight: .bold)
            label.textColor = UIColor(hex: viewModel.textColorCode)
        }

        if let imageURL = viewModel.imageURL {
            imageView.isHidden = false
            imageView.image = nil
            imageView.setImage(from: imageURL)
        }

        layer.borderWidth = CGFloat(viewModel.borderWidth)
        layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
    }
}
