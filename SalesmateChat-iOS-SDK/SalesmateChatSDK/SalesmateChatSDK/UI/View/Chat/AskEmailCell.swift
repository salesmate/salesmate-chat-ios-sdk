//
//  AskEmailView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 11/08/21.
//

import UIKit

class AskEmailCell: UITableViewCell {

    // MARK: - Constants
    private static let nib: UINib = UINib(nibName: "AskEmailCell", bundle: .salesmate)

    static func instantiate() -> AskEmailCell? {
        nib.instantiate(withOwner: self, options: nil)[0] as? AskEmailCell
    }

    private var enableActionColor: UIColor?
    private var disableActionColor: UIColor? = UIColor(hex: "EBECF0")

    // MARK: - Properties
    var viewModel: AskEmailViewModel? {
        didSet { display() }
    }

    var sendEmailAddress: ((String) -> Void)?

    // MARK: - Outlets
    @IBOutlet private weak var profileView: CirculerProfileView!
    @IBOutlet private weak var viewMainContainer: UIView!
    @IBOutlet private weak var viewEmail: UIView!
    @IBOutlet private weak var txtEmail: UITextField!
    @IBOutlet private weak var btnSend: UIButton!

    // MARK: - Override
    override func awakeFromNib() {
        super.awakeFromNib()

        viewMainContainer.layer.cornerRadius = 10
        viewMainContainer.layer.borderWidth = 1
        viewMainContainer.layer.borderColor = UIColor(hex: "EBECF0")?.cgColor

        viewEmail.layer.cornerRadius = 8
        viewEmail.layer.borderWidth = 1
        viewEmail.layer.borderColor = UIColor(hex: "DFE1E6")?.cgColor
    }

    // MARK: - View
    private func display() {
        guard let viewModel = viewModel else { return }

        updateProfileView()

        if let color = UIColor(hex: viewModel.actionColorCode) {
            setActionColor(color)
        }

        if let email = viewModel.email, !email.isEmpty {
            setEmailAddress(email)
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

    private func setActionColor(_ color: UIColor) {
        enableActionColor = color
        updateSendButton()
    }

    private func setEmailAddress(_ email: String) {
        txtEmail.isUserInteractionEnabled = false
        txtEmail.isEnabled = false
        txtEmail.text = email

        btnSend.isHidden = true
    }

    private func updateSendButton() {
        if txtEmail.text?.isEmpty ?? true {
            btnSend.isEnabled = false
            btnSend.backgroundColor = disableActionColor
        } else {
            btnSend.isEnabled = true
            btnSend.backgroundColor = enableActionColor
        }
    }

    // MARK: - Events
    @IBAction private func textDidChange(_ textField: UITextField) {
        updateSendButton()
    }

    @IBAction private func btnSendPressed(_ button: UIButton) {
        sendEmailAddress?(txtEmail.text ?? "")
    }
}
