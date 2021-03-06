//
//  RecentConversationsVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 29/07/21.
//

import UIKit

class RecentConversationsVC: UIViewController {

    // MARK: - Static Functions
    static func create(with viewModel: RecentConversationsViewModel) -> RecentConversationsVC {
        let storyboard = UIStoryboard(name: "RecentConversations", bundle: Bundle(for: Self.self))
        let VC = storyboard.instantiateInitialViewController() as! RecentConversationsVC

        VC.viewModel = viewModel

        return VC
    }

    // MARK: - Private Properties
    private var viewModel: RecentConversationsViewModel!

    // MARK: - IBOutlets
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var btnViewAll: UIButton!
    @IBOutlet private weak var lblPowerBy: UILabel!
    @IBOutlet private weak var btnStartChat: UIButton!

    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()

        prepareView()
    }

    // MARK: - View
    private func prepareView() {
        prepareTableView()

        lblPowerBy.isHidden = !viewModel.showPowerBy

        btnStartChat.isHidden = !viewModel.showStartNewChat
        btnStartChat.backgroundColor = UIColor(hex: viewModel.actionColorCode)

        btnViewAll.setTitleColor(UIColor(hex: viewModel.actionColorCode), for: .normal)
        btnViewAll.isHidden = !viewModel.shouldShowViewAll

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
    }

    private func prepareTableView() {
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "ConversationCell", bundle: .salesmate),
                           forCellReuseIdentifier: ConversationCell.ID)
    }

    // MARK: - Actions
    @IBAction private func btnViewAllPressed(_ sender: UIButton) {
        viewModel.didSelectViewAll()
    }

    @IBAction private func btnStartNewChatPressed(_ sender: UIButton) {
        viewModel.didSelecctStartNewChat()
    }
}

// MARK: - UITableViewDataSource
extension RecentConversationsVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.conversationViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.ID, for: indexPath) as! ConversationCell

        cell.viewModel = viewModel.conversationViewModels[indexPath.row]

        return cell
    }
}

// MARK: - UITableViewDelegate
extension RecentConversationsVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelecctConversation(at: indexPath.row)
    }
}
