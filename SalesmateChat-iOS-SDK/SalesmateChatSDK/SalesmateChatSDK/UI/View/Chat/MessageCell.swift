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

    var didSelectFile: ((URL) -> Void)?

    // MARK: - Outlets
    @IBOutlet fileprivate weak var viewChatContent: UIStackView!
    @IBOutlet private weak var lblBottomText: UILabel!

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

        showBottomText()

        viewModel.didUpdateBotton = {
            self.showBottomText()
        }
    }

    private func showBottomText() {
        guard let viewModel = viewModel else { return }

        if case .text(let bottomText) = viewModel.bottom {
            lblBottomText.text = bottomText
        } else {
            lblBottomText.text = nil
        }
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
        if let emoji = isEmojiOnly() {
            // If content is only one emoji then display it as a big emoji without bouble.
            addEmoji(emoji: emoji)
            return
        }

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

    private func isEmojiOnly() -> String? {
        guard viewModel?.contents.count == 1 else { return nil }
        guard case .html(let attributedText) = viewModel?.contents.first else { return nil }

        let text = attributedText.string.trim()

        guard text.count == 1 else { return nil }
        guard text.first?.unicodeScalars.first?.properties.isEmoji ?? false else { return nil }

        return text
    }

    private func addEmoji(emoji: String) {
        let emojiLabel = UILabel()

        emojiLabel.text = emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 38)

        viewChatContent.addArrangedSubview(emojiLabel)
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
        fileView.didTapImage = { self.didSelectFile?($0) }

        viewChatContent.addArrangedSubview(fileView)
    }

    private func addImage(viewModel: ChatAttachmentViewModel) {
        guard let messageViewModel = self.viewModel else { return }

        let fileView = ChatImageView(frame: .zero)

        fileView.setBackgroundColor(code: messageViewModel.backgroundColorCode)
        fileView.setAlignment(alignment: messageViewModel.alignment)
        fileView.viewModel = viewModel
        fileView.didTapImage = {
            self.didSelectFile?($0)
        }

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

    // MARK: - Constants
    static let nib: UINib = UINib(nibName: "SendMessageCell", bundle: .salesmate)
    static let ID = "SendMessageCell"

    // MARK: - Property
    var shouldRetry: ((SendingMessageViewModel) -> Void)?

    // MARK: - Outlets
    @IBOutlet private weak var retryView: UIView!
    @IBOutlet private weak var btnRetry: UIButton!

    // MARK: - Override
    override func awakeFromNib() {
        super.awakeFromNib()

        viewChatContent.alignment = .trailing

        setRetryTitle()
    }

    // MARK: - View
    private func setRetryTitle() {
        let retryTitle = "Retry"
        let titleRange = NSRange(location: 0, length: retryTitle.count)
        let attributedTitle = NSMutableAttributedString(string: retryTitle)

        attributedTitle.addAttribute(NSAttributedString.Key.underlineStyle,
                                     value: NSUnderlineStyle.single.rawValue,
                                     range: titleRange)

        btnRetry.setAttributedTitle(attributedTitle, for: .normal)
    }

    // MARK: - View
    override func display() {
        super.display()

        guard let viewModel = viewModel else { return }

        if case .retry = viewModel.bottom {
            retryView.isHidden = false
        } else {
            retryView.isHidden = true
        }
    }

    // MARK: - Event
    @IBAction private func btnRetryPressed(_ sender: UIButton) {
        guard let viewModel = viewModel as? SendingMessageViewModel else { return }

        shouldRetry?(viewModel)
    }
}

class ReceivedMessageCell: MessageCell {

    // MARK: - Constants
    static let nib: UINib = UINib(nibName: "ReceivedMessageCell", bundle: .salesmate)
    static let ID = "ReceivedMessageCell"

    // MARK: - Property
    var sendEmailAddress: ((String) -> Void)?

    // MARK: - Outlets
    @IBOutlet private weak var profileView: CirculerProfileView!

    // MARK: - Override
    override func awakeFromNib() {
        super.awakeFromNib()

        viewChatContent.alignment = .leading
    }

    override func display() {
        super.display()

        updateProfileView()
    }

    // MARK: - View
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
