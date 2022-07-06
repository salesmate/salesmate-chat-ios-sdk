//
//  SalesmateChatHomeVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
//

import UIKit

class SalesmateChatHomeVC: UIViewController {

    // MARK: - Static Functions
    static func create(with viewModel: HomeViewModel) -> SalesmateChatHomeVC {
        let storyboard = UIStoryboard(name: "Home", bundle: Bundle(for: Self.self))
        let homeVC = storyboard.instantiateInitialViewController() as! SalesmateChatHomeVC

        homeVC.viewModel = viewModel

        return homeVC
    }

    // MARK: - Private Properties
    private var viewModel: HomeViewModel!
    private let loading = ActivityIndicatorView(frame: .zero)

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
        startLoading()
    }

    // MARK: - View
    private func prepareView() {
        prepareViewModel()
        prepareTopView()

        viewContainer.layer.cornerRadius = 10
        viewContainer.clipsToBounds = true

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
    }

    private func prepareTopView() {
        let backgroundColor = UIColor(hex: viewModel.backgroundColorCode)
        let foregroundColor = backgroundColor?.foregroundColor

        viewTop.backgroundColor = backgroundColor

        if let patternImage = UIImage(viewModel.backgroundPatternName) {
            imgvTopPattern.backgroundColor = UIColor.init(patternImage: patternImage)
        }

        if let link = viewModel.headerLogoURL {
            imgvLogoContainer.isHidden = false
            imgvLogo.loadImage(with: link)
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
            self.loading.removeFromSuperview()
            let VC = NewVisitorVC.create(with: viewModel)
            self.add(child: VC, in: self.viewContainer)
        }

        viewModel.showRecentConversationsView = { viewModel in
            self.loading.removeFromSuperview()
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

    // MARK: - Loading
    private func startLoading() {
        viewContainer.addSubview(loading)
        loading.frame = viewContainer.bounds
        viewModel.getRecentConversations()
    }

    // MARK: - Event
    @IBAction private func btnClosePressed(_ sender: UIButton) {
        navigationController?.dismiss(animated: true)
    }
}
