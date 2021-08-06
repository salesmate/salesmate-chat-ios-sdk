//
//  ChatFileView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 06/08/21.
//

import UIKit

class ChatFileView: UIView {

    private let stackView = UIStackView()
    private let backgroundView: UIView = UIView(frame: .zero)
    private let imgvIcon: UIImageView = UIImageView(image: UIImage.attachment)
    private let lblName: UILabel = UILabel(frame: .zero)

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

        backgroundView.addAndFill(in: self)
        backgroundView.backgroundColor = .white

        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 5

        stackView.addAndFill(in: backgroundView, with: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15))

        imgvIcon.tintColor = .white
        imgvIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imgvIcon.widthAnchor.constraint(equalToConstant: 30),
            imgvIcon.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}
