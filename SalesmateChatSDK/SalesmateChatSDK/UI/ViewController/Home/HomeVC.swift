//
//  HomeVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
//

import UIKit

class HomeVC: UIViewController {

    // MARK: - Static Functions
    static func create(with viewModel: HomeViewModel) -> HomeVC {
        let storyboard = UIStoryboard(name: "Home", bundle: Bundle(for: Self.self))
        let homeVC = storyboard.instantiateInitialViewController() as! HomeVC

        homeVC.viewModel = viewModel

        return homeVC
    }

    // MARK: - Private Properties
    private var viewModel: HomeViewModel!

    // MARK: - IBOutlets
    @IBOutlet private weak var viewTop: UIView!
    @IBOutlet private weak var imgvTopPattern: UIImageView!
    @IBOutlet private weak var btnClose: UIButton!

    @IBOutlet private weak var imgvLogoContainer: UIView!
    @IBOutlet private weak var imgvLogo: UIImageView!

    @IBOutlet private weak var lblGreeting: UILabel!
    @IBOutlet private weak var lblTeamIntro: UILabel!

    @IBOutlet private weak var viewContainer: UIView!

    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()

        prepareView()
        viewModel.getRecentConversations()
    }

    // MARK: - View
    private func prepareView() {
        prepareViewModel()
        prepareTopView()

        viewContainer.layer.cornerRadius = 10
        viewContainer.clipsToBounds = true
    }

    private func prepareTopView() {
        let backgroundColor = UIColor(hex: viewModel.backgroundColorCode)
        let foregroundColor = backgroundColor?.foregroundColor

        viewTop.backgroundColor = backgroundColor
        imgvTopPattern.image = UIImage(viewModel.backgroundPatternName)

        if let link = viewModel.headerLogoURL {
            imgvLogoContainer.isHidden = false
            imgvLogo.setImage(from: link)
        } else {
            imgvLogoContainer.isHidden = true
        }

        btnClose.tintColor = foregroundColor
        lblGreeting.textColor = foregroundColor
        lblTeamIntro.textColor = foregroundColor

        lblGreeting.text = viewModel.greeting
        lblTeamIntro.text = viewModel.teamIntro
    }

    // MARK: - ViewModel
    private func prepareViewModel() {
        viewModel.showNewVisitorView = { viewModel in
            let VC = NewVisitorVC.create(with: viewModel)
            self.add(child: VC, in: self.viewContainer)
        }

        viewModel.showRecentConversationsView = { viewModel in
            let VC = RecentConversationsVC.create(with: viewModel)

            self.add(child: VC, in: self.viewContainer)
        }

        viewModel.showAllConversations = { viewModel in
            let VC = ConversationsVC.create(with: viewModel)

            self.navigationController?.pushViewController(VC, animated: true)
        }

        viewModel.startNewChat = { viewModel in
            let VC = ChatVC.create(with: viewModel)

            self.navigationController?.pushViewController(VC, animated: true)
        }

        viewModel.showConversation = { viewModel in
            let VC = ChatVC.create(with: viewModel)

            self.navigationController?.pushViewController(VC, animated: true)
        }
    }

    // MARK: - Event
    @IBAction private func btnClosePressed(_ sender: UIButton) {
        navigationController?.dismiss(animated: true)
    }
}
