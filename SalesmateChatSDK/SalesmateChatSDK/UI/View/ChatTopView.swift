//
//  ChatTopView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 03/08/21.
//

import UIKit

class ChatTopView: UIView {

    // MARK: - Outlets
    @IBOutlet fileprivate weak var imgvTopPattern: UIImageView!

    @IBOutlet fileprivate weak var btnBack: UIButton!
    @IBOutlet fileprivate weak var btnClose: UIButton!

    // MARK: - Properties
    var viewModel: ChatTopViewModel? {
        didSet { display() }
    }

    var didSelectBack: (() -> Void)?
    var didSelectClose: (() -> Void)?

    // MARK: - Override
    override func awakeFromNib() {
        super.awakeFromNib()

        btnBack.addTarget(self, action: #selector(btnBackPressed(_:)), for: .touchUpInside)
        btnClose.addTarget(self, action: #selector(btnClosePressed(_:)), for: .touchUpInside)
    }

    // MARK: - View
    fileprivate func display() {
        guard let viewModel = viewModel else { return }

        let backgroundColor = UIColor(hex: viewModel.backgroundColorCode)

        self.backgroundColor = backgroundColor

        btnBack.tintColor = backgroundColor?.foregroundColor
        btnClose.tintColor = backgroundColor?.foregroundColor

        imgvTopPattern.image = UIImage(viewModel.backgroundPatternName)
    }

    // MARK: - Event
    @objc private func btnBackPressed(_ sender: UIButton) {
        didSelectBack?()
    }

    @objc private func btnClosePressed(_ sender: UIButton) {
        didSelectClose?()
    }
}

class ChatTopWithoutLogo: ChatTopView {

    // MARK: - Outlets
    @IBOutlet private weak var userView: AvailableUsersView!
    @IBOutlet private weak var lblTitle: UILabel!
    @IBOutlet private weak var lblResponseTime: UILabel!

    // MARK: - Override
    fileprivate override func display() {
        super.display()

        guard let viewModel = viewModel else { return }

        let backgroundColor = UIColor(hex: viewModel.backgroundColorCode)

        userView.viewModel = viewModel.availableuserViewModel

        lblResponseTime.text = viewModel.responseTime
        lblTitle.textColor = backgroundColor?.foregroundColor
        lblResponseTime.textColor = backgroundColor?.secondaryForegroundColor
    }
}

class ChatTopWithLogo: ChatTopView {

    // MARK: - Outlets
    @IBOutlet private weak var imgvLogo: UIImageView!

    @IBOutlet private weak var userView: AvailableUsersView!

    @IBOutlet private weak var lblTeamIntro: UILabel!
    @IBOutlet private weak var lblResponseTime: UILabel!

    // MARK: - Override
    fileprivate override func display() {
        super.display()

        guard let viewModel = viewModel else { return }

        let backgroundColor = UIColor(hex: viewModel.backgroundColorCode)

        if let link = viewModel.headerLogoURL {
            imgvLogo.setImage(from: link)
        }

        userView.viewModel = viewModel.availableuserViewModel

        lblTeamIntro.text = viewModel.teamIntro
        lblTeamIntro.textColor = backgroundColor?.secondaryForegroundColor

        lblResponseTime.text = viewModel.responseTime
        lblResponseTime.textColor = backgroundColor?.secondaryForegroundColor
    }
}

class ChatTopWithUser: ChatTopView {

    // MARK: - Properties
    var didSelectExport: (() -> Void)?

    // MARK: - Outlets
    @IBOutlet private weak var viewProfile: CirculerProfileView!
    @IBOutlet private weak var lblUserName: UILabel!
    @IBOutlet private weak var lblStatus: UILabel!

    @IBOutlet private weak var btnExport: UIButton!

    // MARK: - Override
    override func awakeFromNib() {
        super.awakeFromNib()

        btnExport.addTarget(self, action: #selector(btnExportPressed(_:)), for: .touchUpInside)
    }

    fileprivate override func display() {
        super.display()

        guard let viewModel = viewModel else { return }

        let backgroundColor = UIColor(hex: viewModel.backgroundColorCode)

        viewProfile.viewModel = viewModel.profileViewModel

        lblUserName.text = viewModel.title
        lblStatus.text = (viewModel.isUserAvailable ?? false) ? "Available" : "Away"

        lblUserName.textColor = backgroundColor?.foregroundColor
        lblStatus.textColor = backgroundColor?.secondaryForegroundColor

        btnExport.tintColor = backgroundColor?.foregroundColor
    }

    // MARK: - Event
    @objc private func btnExportPressed(_ sender: UIButton) {
        didSelectExport?()
    }
}
