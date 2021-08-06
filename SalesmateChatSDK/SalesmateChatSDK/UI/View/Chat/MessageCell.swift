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
    @IBOutlet private weak var profileView: CirculerProfileView!
    @IBOutlet private weak var viewChatContent: UIStackView!
    @IBOutlet private weak var textContainer: ChatAttributedTextsView!
    @IBOutlet private weak var lblTime: UILabel!
    @IBOutlet private weak var lblSeen: UILabel!

    // MARK: - Override
    override func prepareForReuse() {
        super.prepareForReuse()

        clear()
    }

    // MARK: - View
    private func display() {
        guard let viewModel = viewModel else { return }

        updateProfileView()

        textContainer.setAlignment(alignment: viewModel.alignment)

        switch viewModel.isDeleted {
        case .yes: showDeletedMessage()
        case .no: showContents()
        }

        lblTime.text = viewModel.time
    }

    private func updateProfileView() {
        guard let viewModel = viewModel else { return }

        if let profileViewModel = viewModel.profileViewModel {
            profileView.superview?.isHidden = false
            profileView.viewModel = profileViewModel
        } else {
            profileView.superview?.isHidden = true
        }
    }

    private func showDeletedMessage() {
        guard let viewModel = viewModel else { return }
        guard case .yes(let message, let alpha) = viewModel.isDeleted else { return }

        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.italicSystemFont(ofSize: 15)]
        let attributedText = NSAttributedString(string: message, attributes: attributes)

        textContainer.setBackgroundColor(code: viewModel.backgroundColorCode)
        textContainer.add(attributedText)
        textContainer.alpha = CGFloat(alpha) / 100.0
    }

    private func showContents() {
        guard let viewModel = viewModel else { return }

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
