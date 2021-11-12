//
//  ContactDetailForm.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 26/09/21.
//

import UIKit

class ContactDetailInputView: UIView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: bounds.width, height: 236)
    }
}

class ContactDetailForm: XIBView {

    // MARK: - Outlets
    @IBOutlet private weak var stackView: UIStackView!

    @IBOutlet private weak var lblName: UILabel!
    @IBOutlet private weak var txtName: UITextField!

    @IBOutlet private weak var lblEmail: UILabel!
    @IBOutlet private weak var txtEmail: UITextField!
    @IBOutlet private weak var lblEmailError: UILabel!

    @IBOutlet private weak var btnSubmit: UIButton!

    // MARK: - Properties
    var submitContactDetail: ((String, EmailAddress) -> Void)?

    // MARK: - Override
    override func setup() {
        super.setup()

        txtName.isHidden = false
        txtEmail.isHidden = false

        lblName.isHidden = true
        lblEmail.isHidden = true
        lblEmailError.isHidden = true

        txtName.clipsToBounds = true
        txtEmail.clipsToBounds = true

        txtName.layer.cornerRadius = 8
        txtEmail.layer.cornerRadius = 8

        txtName.layer.borderWidth = 1.0
        txtEmail.layer.borderWidth = 1.0

        txtName.layer.borderColor = UIColor(hex: "DFE1E6")?.cgColor
        txtEmail.layer.borderColor = UIColor(hex: "DFE1E6")?.cgColor

        txtName.leftViewMode = .always
        txtEmail.leftViewMode = .always

        txtName.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 40))
        txtEmail.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 40))

        btnSubmit.alpha = 0.5
        btnSubmit.clipsToBounds = true
        btnSubmit.layer.cornerRadius = 4.0

        updateSubmitButtonStatus()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: bounds.width, height: stackView.intrinsicContentSize.height + 40)
    }

    // MARK: - Functions
    func display(name: String, and email: EmailAddress) {
        txtName.isHidden = true
        txtEmail.isHidden = true

        lblName.isHidden = false
        lblEmail.isHidden = false

        lblName.text = name
        lblEmail.text = email.rawValue

        btnSubmit.superview?.isHidden = true
    }

    func setActionColor(_ color: UIColor) {
        btnSubmit.backgroundColor = color
    }

    // MARK: - Events
    @IBAction private func textDidChange(_ textField: UITextField) {
        updateSubmitButtonStatus()

        if textField === txtEmail, !lblEmailError.isHidden {
            hideInvalidEmailError()
        }
    }

    @IBAction private func btnSubmitPressed(_ button: UIButton) {
        guard let name = txtName.text, !name.isEmpty else { return }
        guard let email = txtEmail.text, !email.isEmpty else { return }
        guard let emailAddress = EmailAddress(rawValue: email) else {
            showInvalidEmailError()
            return
        }

        submitContactDetail?(name, emailAddress)
    }
}

extension ContactDetailForm {

    private func updateSubmitButtonStatus() {
        btnSubmit.isEnabled = !txtName.isEmpty && !txtEmail.isEmpty
        btnSubmit.alpha = btnSubmit.isEnabled ? 1.0 : 0.5
    }

    private func hideInvalidEmailError() {
        lblEmailError.isHidden = true
        txtEmail.layer.borderColor = UIColor(hex: "DFE1E6")?.cgColor
    }

    private func showInvalidEmailError() {
        lblEmailError.isHidden = false
        txtEmail.layer.borderColor = UIColor(hex: "DE350B")?.cgColor
    }
}
