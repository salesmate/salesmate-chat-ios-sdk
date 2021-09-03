//
//  AskEmailView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 11/08/21.
//

import UIKit

class AskEmailView: XIBView {

    var sendEmailAddress: ((String) -> Void)?

    @IBOutlet private weak var viewEmail: UIView!
    @IBOutlet private weak var txtEmail: UITextField!
    @IBOutlet private weak var btnSend: UIButton!

    private var enableActionColor: UIColor?
    private var disableActionColor: UIColor? = UIColor(hex: "EBECF0")

    override func setup() {
        super.setup()

        contentView?.layer.borderWidth = 1
        contentView?.layer.borderColor = UIColor(hex: "EBECF0")?.cgColor

        viewEmail.layer.borderWidth = 1
        viewEmail.layer.borderColor = UIColor(hex: "DFE1E6")?.cgColor
    }

    // MARK: - Customization
    func setActionColor(_ color: UIColor) {
        enableActionColor = color
        updateSendButton()
    }

    func setEmailAddress(_ email: String) {
        txtEmail.isUserInteractionEnabled = false
        txtEmail.isEnabled = false
        txtEmail.text = email

        btnSend.isHidden = true
    }

    // MARK: - Events
    @IBAction private func textDidChange(_ textField: UITextField) {
        updateSendButton()
    }

    @IBAction private func btnSendPressed(_ button: UIButton) {
        sendEmailAddress?(txtEmail.text ?? "")
    }
}

extension AskEmailView {

    private func updateSendButton() {
        if txtEmail.text?.isEmpty ?? true {
            btnSend.isEnabled = false
            btnSend.backgroundColor = disableActionColor
        } else {
            btnSend.isEnabled = true
            btnSend.backgroundColor = enableActionColor
        }
    }
}
