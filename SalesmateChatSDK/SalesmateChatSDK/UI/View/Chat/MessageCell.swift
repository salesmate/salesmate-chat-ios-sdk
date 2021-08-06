//
//  MessageCell.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 04/08/21.
//

import UIKit

class MessageCell: UITableViewCell {

    // MARK: - Properties
    var viewModel: MessageViewModel? {
        didSet { display() }
    }

    // MARK: - Outlets
    @IBOutlet fileprivate weak var profileView: CirculerProfileView!
    @IBOutlet fileprivate weak var viewChatContent: UIStackView!
    @IBOutlet fileprivate weak var textContainer: ChatAttributedTextsView!
    @IBOutlet fileprivate weak var lbltime: UILabel!

    private func display() {
        guard let viewModel = viewModel else { return }

        if let profileViewModel = viewModel.profileViewModel {
            profileView.superview?.isHidden = false
            profileView.viewModel = profileViewModel
        } else {
            profileView.superview?.isHidden = true
        }

        lbltime.text = viewModel.time

        textContainer.setAlignment(alignment: viewModel.alignment)
        textContainer.setBackgroundColor(code: viewModel.backgroundColorCode)

        for content in viewModel.contents {
            switch content {
            case .html(let text):
                textContainer.add(text)
            case .image:
                break
            case .file:
                break
            }
        }

        if case .yes(let message, let alpha) = viewModel.isDeleted {
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.italicSystemFont(ofSize: 15)]
            let attributedText = NSAttributedString(string: message, attributes: attributes)

            textContainer.setBackgroundColor(code: viewModel.backgroundColorCode)
            textContainer.add(attributedText)
            textContainer.alpha = CGFloat(alpha) / 100.0
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        clear()
    }

    private func clear() {
        textContainer.alpha = 1
        textContainer.removeAllTexts()

        for subview in viewChatContent.subviews where subview != textContainer {
            subview.removeFromSuperview()
        }
    }
}

class SendMessageCell: MessageCell {
    static let nib: UINib = UINib(nibName: "SendMessageCell", bundle: .salesmate)
    static let ID = "SendMessageCell"
}

class ReceivedMessageCell: MessageCell {
    static let nib: UINib = UINib(nibName: "ReceivedMessageCell", bundle: .salesmate)
    static let ID = "ReceivedMessageCell"
}
