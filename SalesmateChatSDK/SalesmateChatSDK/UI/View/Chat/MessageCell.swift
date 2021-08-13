//
//  MessageCell.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 04/08/21.
//

import UIKit

class MessageCell: UITableViewCell {

    // MARK: - Properties
    var viewModel: MessageViewModelType? {
        didSet { display() }
    }

    // MARK: - Outlets
    @IBOutlet fileprivate weak var viewChatContent: UIStackView!
    @IBOutlet private weak var lblTime: UILabel!
    @IBOutlet private weak var lblSeen: UILabel!

    private var textContainer = ChatAttributedTextsView()

    // MARK: - Override
    override func prepareForReuse() {
        super.prepareForReuse()

        clear()
    }

    // MARK: - View
    fileprivate func display() {
        guard let viewModel = viewModel else { return }

        textContainer.setAlignment(alignment: viewModel.alignment)

        switch viewModel.isDeleted {
        case .yes: showDeletedMessage()
        case .no: showContents()
        }

        lblTime.text = viewModel.time
    }

    private func showDeletedMessage() {
        guard let viewModel = viewModel else { return }
        guard case .yes(let message, let alpha) = viewModel.isDeleted else { return }

        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.italicSystemFont(ofSize: 15)]
        let attributedText = NSAttributedString(string: message, attributes: attributes)

        textContainer.setBackgroundColor(code: viewModel.backgroundColorCode)
        textContainer.alpha = CGFloat(alpha) / 100.0

        addText(text: attributedText)
    }

    private func showContents() {
        guard let viewModel = viewModel else { return }

        textContainer.setBackgroundColor(code: viewModel.backgroundColorCode)

        for content in viewModel.contents {
            switch content {
            case .html(let text):
                addText(text: text)
            case .image(let viewModel):
                addImage(viewModel: viewModel)
            case .file(let viewModel):
                addFile(viewModel: viewModel)
            }
        }
    }

    private func addText(text: NSAttributedString) {
        if textContainer.superview == nil {
            viewChatContent.addArrangedSubview(textContainer)
        }

        textContainer.add(text)
    }

    private func addFile(viewModel: ChatAttachmentViewModel) {
        guard let messageViewModel = self.viewModel else { return }

        let fileView = ChatFileView(frame: .zero)

        fileView.setBackgroundColor(code: messageViewModel.backgroundColorCode)
        fileView.setAlignment(alignment: messageViewModel.alignment)
        fileView.viewModel = viewModel

        viewChatContent.addArrangedSubview(fileView)
    }

    private func addImage(viewModel: ChatAttachmentViewModel) {
        guard let messageViewModel = self.viewModel else { return }

        let fileView = ChatImageView(frame: .zero)

        fileView.setBackgroundColor(code: messageViewModel.backgroundColorCode)
        fileView.setAlignment(alignment: messageViewModel.alignment)
        fileView.viewModel = viewModel

        viewChatContent.addArrangedSubview(fileView)
    }

    private func clear() {
        textContainer.alpha = 1
        textContainer.removeAllTexts()

        for subview in viewChatContent.subviews {
            subview.removeFromSuperview()
        }
    }
}

class SendMessageCell: MessageCell {

    static let nib: UINib = UINib(nibName: "SendMessageCell", bundle: .salesmate)
    static let ID = "SendMessageCell"

    override func awakeFromNib() {
        super.awakeFromNib()

        viewChatContent.alignment = .trailing
    }
}

class ReceivedMessageCell: MessageCell {

    @IBOutlet private weak var profileView: CirculerProfileView!

    static let nib: UINib = UINib(nibName: "ReceivedMessageCell", bundle: .salesmate)
    static let ID = "ReceivedMessageCell"

    override func awakeFromNib() {
        super.awakeFromNib()

        viewChatContent.alignment = .leading
    }

    override func display() {
        super.display()

        updateProfileView()

        if viewModel?.askEmail ?? false {
            viewChatContent.addArrangedSubview(AskEmailView())
        }
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
}
