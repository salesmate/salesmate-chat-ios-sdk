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

    private let viewCircle = UIView()
    private let imageView = UIImageView()
    private let label = UILabel()
    private let viewStatusDot = UIView()

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

        viewCircle.layer.cornerRadius = frame.width / 2.0
    }

    private func setup() {
        viewCircle.clipsToBounds = true
        viewCircle.backgroundColor = .clear
        viewCircle.addAndFill(in: self)

        label.frame = self.bounds
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.addAndFill(in: viewCircle)

        imageView.frame = self.bounds
        imageView.backgroundColor = .clear
        imageView.addAndFill(in: viewCircle)

        viewStatusDot.translatesAutoresizingMaskIntoConstraints = false
        viewStatusDot.backgroundColor = UIColor(hex: "00D890")
        viewStatusDot.layer.cornerRadius = 6.0
        viewStatusDot.clipsToBounds = true

        addSubview(viewStatusDot)

        NSLayoutConstraint.activate([
            viewStatusDot.trailingAnchor.constraint(equalTo: viewCircle.trailingAnchor),
            viewStatusDot.bottomAnchor.constraint(equalTo: viewCircle.bottomAnchor),
            viewStatusDot.heightAnchor.constraint(equalToConstant: 12),
            viewStatusDot.widthAnchor.constraint(equalToConstant: 12)
        ])
    }

    private func display() {
        guard let viewModel = viewModel else { return }

        label.isHidden = true
        imageView.isHidden = true

        viewCircle.backgroundColor = UIColor(hex: viewModel.backgroundColorCode)

        if let string = viewModel.text {
            label.isHidden = false
            label.text = string
            label.font = UIFont.systemFont(ofSize: CGFloat(viewModel.textSize), weight: .bold)
            label.textColor = UIColor(hex: viewModel.textColorCode)
        }

        if let imageURL = viewModel.imageURL {
            imageView.isHidden = false
            imageView.image = nil
            imageView.loadImage(with: imageURL)
        }

        if viewModel.shouldShowStatus {
            viewStatusDot.isHidden = false
            viewStatusDot.backgroundColor = UIColor(hex: viewModel.statusColorCode ?? "")
            viewStatusDot.layer.borderColor = UIColor(hex: viewModel.statusBorderCode ?? "")?.cgColor
            viewStatusDot.layer.borderWidth = 2
        } else {
            viewStatusDot.isHidden = true
        }

        viewCircle.layer.borderWidth = CGFloat(viewModel.borderWidth)
        viewCircle.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
    }
}
