//
//  ConversationsVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 30/07/21.
//

import UIKit

class ConversationsVC: UIViewController {

    // MARK: - Static Functions
    static func create(with viewModel: ConversationsViewModel) -> ConversationsVC {
        let storyboard = UIStoryboard(name: "Conversations", bundle: Bundle(for: Self.self))
        let VC = storyboard.instantiateInitialViewController() as! ConversationsVC

        VC.viewModel = viewModel

        return VC
    }

    // MARK: - Private Properties
    private var viewModel: ConversationsViewModel!

    // MARK: - IBOutlets
    @IBOutlet private weak var viewTop: UIView!
    @IBOutlet private weak var imgvTopPattern: UIImageView!
    @IBOutlet private weak var btnBack: UIButton!
    @IBOutlet private weak var lblTitle: UILabel!
    @IBOutlet private weak var btnClose: UIButton!

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var btnStartChat: UIButton!

    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()

        prepareView()
        viewModel.getRecentConversations()
    }

    // MARK: - View
    private func prepareView() {
        prepareViewModel()
        prepareTableView()
        applyCustomization()
    }

    private func prepareViewModel() {
        viewModel.conversationsUpdated = {
            self.tableView.reloadData()
        }
    }

    private func prepareTableView() {
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "ConversationCell", bundle: .salesmate),
                           forCellReuseIdentifier: ConversationCell.ID)
    }

    private func applyCustomization() {
        viewTop.backgroundColor = UIColor(hex: viewModel.backgroundColorCode)

        let backgroundColor = UIColor(hex: viewModel.backgroundColorCode)
        let foregroundColor: UIColor = {
            if backgroundColor?.isDark ?? true {
                return UIColor.white
            } else {
                return UIColor.black
            }
        }()

        viewTop.backgroundColor = backgroundColor
        btnBack.tintColor = foregroundColor
        btnClose.tintColor = foregroundColor
        lblTitle.textColor = foregroundColor
        btnStartChat.backgroundColor = UIColor(hex: viewModel.actionColorCode)

        imgvTopPattern.image = UIImage(viewModel.backgroundPatternName)
    }

    // MARK: - Actions
    @IBAction private func btnBackAllPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func btnCloseAllPressed(_ sender: UIButton) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension ConversationsVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.conversationViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.ID, for: indexPath) as! ConversationCell

        cell.viewModel = viewModel.conversationViewModels[indexPath.row]

        return cell
    }
}
