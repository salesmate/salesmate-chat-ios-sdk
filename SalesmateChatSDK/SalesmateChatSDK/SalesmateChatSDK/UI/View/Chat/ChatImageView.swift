//
//  ChatImageView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 11/08/21.
//

import UIKit

class ChatImageView: UIView {

    private let imageView = UIImageView(frame: .zero)
    private let loading = UIActivityIndicatorView(frame: .zero)

    var didTapImage: ((URL) -> Void)?

    var viewModel: ChatAttachmentViewModel? {
        didSet { display() }
    }

    init() {
        super.init(frame: .zero)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        clipsToBounds = true
        layer.cornerRadius = 15

        imageView.addAndFill(in: self, with: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))

        let screenSize = UIScreen.main.bounds.size
        let width = screenSize.width * 0.80 - 30
        let height = width / 2

        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        imageView.backgroundColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: width).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        imageView.isUserInteractionEnabled = true

        loading.hidesWhenStopped = true
        loading.addAndFill(in: self)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))

        imageView.addGestureRecognizer(tap)
    }

    @objc private func didTap() {
        guard let url = viewModel?.url else { return }

        didTapImage?(url)
    }

    private func display() {
        if self.loading.isAnimating {
            self.loading.stopAnimating()
        }

        if let data = viewModel?.data, let image = UIImage(data: data) {
            imageView.image = image
        } else if let link = viewModel?.url {
            loading.startAnimating()

            imageView.loadImage(with: link) {
                self.loading.stopAnimating()
            }
        }
    }

    func setAlignment(alignment: CellAlignment) {
        switch alignment {
        case .left:
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        case .right:
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
            imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        }
    }

    func setBackgroundColor(code: String) {
        backgroundColor = UIColor(hex: code)
        loading.color = backgroundColor
    }
}
