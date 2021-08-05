//
//  ChatVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 02/08/21.
//

import UIKit

class ChatVC: UIViewController {

    // MARK: - Static Functions
    static func create(with viewModel: ChatViewModel) -> ChatVC {
        let storyboard = UIStoryboard(name: "Chat", bundle: Bundle(for: Self.self))
        let VC = storyboard.instantiateInitialViewController() as! Self

        VC.viewModel = viewModel

        return VC
    }

    // MARK: - Private Properties
    private var viewModel: ChatViewModel!

    // MARK: - IBOutlets
    @IBOutlet private weak var viewTopWithoutLogo: ChatTopWithoutLogo!
    @IBOutlet private weak var viewTopWithLogo: ChatTopWithLogo!

    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet private weak var messageInputBar: MessageComposeView!

    // MARK: - Override
    override var canBecomeFirstResponder: Bool { true }
    override var canResignFirstResponder: Bool { true }
    override var inputAccessoryView: UIView? { messageInputBar }

    override func viewDidLoad() {
        super.viewDidLoad()

        prepareViewModel()
        prepareView()

        viewModel.getMessages()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.contentInset = UIEdgeInsets(top: 15,
                                              left: 0,
                                              bottom: messageInputBar.intrinsicContentSize.height + 15,
                                              right: 0)
    }
    // MARK: - ViewModel
    private func prepareViewModel() {
        viewModel.messagesUpdated = {
            self.tableView.reloadData()
        }
    }

    // MARK: - View
    private func prepareView() {
        prepareTopBar()
        prepareTableView()
        prepareInputBar()
    }

    private func prepareTopBar() {
        viewTopWithLogo.isHidden = true
        viewTopWithoutLogo.isHidden = true

        let viewTop: ChatTopView?

        switch viewModel.topbar {
        case .withoutLogo:
            viewTop = viewTopWithoutLogo
        case .withLogo:
            viewTop = viewTopWithLogo
        case .assigned:
            viewTop = nil
        }

        viewTop?.viewModel = viewModel.topViewModel
        viewTop?.isHidden = false

        viewTop?.didSelectBack = {
            self.navigationController?.popViewController(animated: true)
        }

        viewTop?.didSelectClose = {
            self.navigationController?.dismiss(animated: true)
        }
    }

    private func prepareInputBar() {

    }

    private func prepareTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.register(SendMessageCell.nib, forCellReuseIdentifier: SendMessageCell.ID)
        tableView.register(ReceivedMessageCell.nib, forCellReuseIdentifier: ReceivedMessageCell.ID)
    }
}

extension ChatVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messageViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let messageViewModel = viewModel.messageViewModels[indexPath.row]

        let cell: MessageCell

        switch messageViewModel.alignment {
        case .left:
            cell = tableView.dequeueReusableCell(withIdentifier: ReceivedMessageCell.ID, for: indexPath) as! MessageCell
        case .right:
            cell = tableView.dequeueReusableCell(withIdentifier: SendMessageCell.ID, for: indexPath) as! MessageCell
        }

        cell.viewModel = messageViewModel

        return cell
    }
}
