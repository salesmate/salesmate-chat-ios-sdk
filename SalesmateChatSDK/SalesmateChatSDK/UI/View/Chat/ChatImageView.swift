//
//  ChatImageView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 11/08/21.
//

import UIKit

class ChatImageView: UIView {

    private let imageView: UIImageView = UIImageView(frame: .zero)

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
    }

    private func display() {
        if let link = viewModel?.url {
            imageView.loadImage(with: link)
        }
    }

    func setAlignment(alignment: Alignment) {
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
