//
//  MessageComposeView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 02/08/21.
//

import UIKit

class MessageComposeView: UIView {

    // MARK: - Outlets
    @IBOutlet private weak var lblPlaceholder: UIView!
    @IBOutlet private weak var txtvMessage: UITextView!
    @IBOutlet private weak var btnSend: UIButton!
    @IBOutlet private weak var btnAttactment: UIButton!
    @IBOutlet private weak var textViewHeight: NSLayoutConstraint!

    // MARK: - Customization
    func setActionColor(_ color: UIColor) {
        btnSend.setTitleColor(color, for: .normal)
    }
    
    // MARK: - override
    override func awakeFromNib() {
        super.awakeFromNib()

        txtvMessage.textContainerInset = .zero
        txtvMessage.textContainer.lineFragmentPadding = 0
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard let windowBottomAnchor = window?.safeAreaLayoutGuide.bottomAnchor else { return }

        bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: windowBottomAnchor, multiplier: 1.0).isActive = true
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: frame.width, height: (10 + textViewContentSize().height + 10 + 25 + 10))
    }

    // MARK: - Helper
    private func textViewContentSize() -> CGSize {
        let size = CGSize(width: txtvMessage.bounds.width,
                          height: CGFloat.greatestFiniteMagnitude)
        let textSize = txtvMessage.sizeThatFits(size)
        return CGSize(width: bounds.width, height: textSize.height)
    }
}

// MARK: - UITextViewDelegate
extension MessageComposeView: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        lblPlaceholder.isHidden = !txtvMessage.text.isEmpty

        let contentHeight = textViewContentSize().height

        if textViewHeight.constant != contentHeight {
            textViewHeight.constant = contentHeight
            layoutIfNeeded()
        }
        
        btnSend.isEnabled = !textView.text.isEmpty
    }
}
