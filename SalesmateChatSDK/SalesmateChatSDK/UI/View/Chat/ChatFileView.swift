//
//  ChatFileView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 06/08/21.
//

import UIKit

class ChatFileView: UIView {

    private let stackView = UIStackView()
    private let imgvIcon: UIImageView = UIImageView(image: UIImage.smallAttachment)
    private let lblName: UILabel = UILabel(frame: .zero)

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

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.height / 2.0
    }

    private func setup() {
        clipsToBounds = true
        layer.cornerRadius = 15

        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 5

        stackView.addAndFill(in: self, with: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 20))
        stackView.addArrangedSubview(imgvIcon)
        stackView.addArrangedSubview(lblName)

        imgvIcon.tintColor = .white
        imgvIcon.translatesAutoresizingMaskIntoConstraints = false
        imgvIcon.clipsToBounds = true
        imgvIcon.layer.cornerRadius = 15
        imgvIcon.contentMode = .center

        lblName.translatesAutoresizingMaskIntoConstraints = false
        lblName.textColor = UIColor(hex: "172B4D")
        lblName.font = UIFont.systemFont(ofSize: 14)

        NSLayoutConstraint.activate([
            imgvIcon.widthAnchor.constraint(equalToConstant: 30),
            imgvIcon.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func display() {
        lblName.text = viewModel?.filename
    }

    func setAlignment(alignment: MessageViewModel.Alignment) {
        switch alignment {
        case .left:
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        case .right:
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        }
    }

    func setBackgroundColor(code: String) {
        layer.borderWidth = 2
        layer.borderColor = UIColor(hex: code)?.cgColor

        imgvIcon.backgroundColor = UIColor(hex: code)
        imgvIcon.tintColor = UIColor(hex: code)?.foregroundColor ?? .white
    }
}
