//
//  AskEmailView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 11/08/21.
//

import UIKit

class AskContactDetailCell: UITableViewCell {

    // MARK: - Constants
    private static let nib: UINib = UINib(nibName: "AskContactDetailCell", bundle: .salesmate)

    static func instantiate() -> AskContactDetailCell? {
        nib.instantiate(withOwner: self, options: nil)[0] as? AskContactDetailCell
    }

    private var enableActionColor: UIColor?
    private var disableActionColor: UIColor? = UIColor(hex: "EBECF0")

    // MARK: - Properties
    var viewModel: AskContactDetailViewModel? {
        didSet { display() }
    }

    var submitContactDetail: ((String, EmailAddress) -> Void)? {
        didSet { form.submitContactDetail = submitContactDetail }
    }

    // MARK: - Outlets
    @IBOutlet private weak var profileView: CirculerProfileView!
    @IBOutlet private weak var viewMainContainer: UIView!
    @IBOutlet private weak var form: ContactDetailForm!
    @IBOutlet private weak var lblNotifiedName: UILabel!

    // MARK: - Override
    override func awakeFromNib() {
        super.awakeFromNib()

        viewMainContainer.layer.cornerRadius = 10
        viewMainContainer.layer.borderWidth = 1
        viewMainContainer.layer.borderColor = UIColor(hex: "EBECF0")?.cgColor
    }

    // MARK: - View
    private func display() {
        guard let viewModel = viewModel else { return }

        updateProfileView()

        if let color = UIColor(hex: viewModel.actionColorCode) {
            form.setActionColor(color)
        }

        if let name = viewModel.name, let email = viewModel.email, let emailAddres = EmailAddress(rawValue: email) {
            lblNotifiedName.text = "You will be notified on the below email"
            lblNotifiedName.font = UIFont.systemFont(ofSize: 12)
            form.display(name: name, and: emailAddres)
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
