//
//  NewVisitorVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
//

import UIKit

class NewVisitorVC: UIViewController {

    // MARK: - Static Functions
    static func create(with viewModel: NewVisitorViewModel) -> NewVisitorVC {
        let storyboard = UIStoryboard(name: "NewVisitor", bundle: Bundle(for: Self.self))
        let VC = storyboard.instantiateInitialViewController() as! NewVisitorVC

        VC.viewModel = viewModel

        return VC
    }

    // MARK: - Private Properties
    private var viewModel: NewVisitorViewModel!

    // MARK: - IBOutlets
    @IBOutlet private weak var lblResponseTime: UILabel!
    @IBOutlet private weak var userView: AvailableUsersView!
    @IBOutlet private weak var lblPowerBy: UILabel!
    @IBOutlet private weak var btnStartChat: UIButton!

    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()

        prepareView()
    }

    // MARK: - View
    private func prepareView() {
        lblResponseTime.text = viewModel.responseTime
        lblPowerBy.isHidden = !viewModel.showPowerBy
        userView.viewModel = viewModel.availableuserViewModel
        btnStartChat.backgroundColor = UIColor(hex: viewModel.buttonColorCode)
    }

    // MARK: - Actions
    @IBAction private func btnStartNewChatPressed(_ sender: UIButton) {
        viewModel.didSelecctStartNewChat()
    }
}
