//
//  ChatAttributedTextsView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 04/08/21.
//

import UIKit

class ChatAttributedTextsView: UIView {

    private let stackView = UIStackView()

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

        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 5

        stackView.addAndFill(in: self, with: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15))
    }

    func removeAllTexts() {
        stackView.subviews.forEach { $0.removeFromSuperview() }
    }

    func add(_ attributedText: NSAttributedString) {
        let label = UILabel()

        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.text = nil
        label.attributedText = attributedText
        label.textColor = backgroundColor?.foregroundColor ?? UIColor.darkForegroundColor

        stackView.addArrangedSubview(label)
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
        backgroundColor = UIColor(hex: code)
    }
}
