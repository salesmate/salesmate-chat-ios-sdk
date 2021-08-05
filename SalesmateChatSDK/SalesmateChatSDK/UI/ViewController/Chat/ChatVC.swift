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
    private var shouldScrollToBottom: Bool = true
    private var shouldAdjustForKeyboard: Bool = false

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
        registerKeyboardNotifications()

        viewModel.getMessages()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if shouldScrollToBottom {
            shouldScrollToBottom = false
            scrollToBottom(animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        shouldAdjustForKeyboard = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        shouldAdjustForKeyboard = true
    }

    // MARK: - ViewModel
    private func prepareViewModel() {
        viewModel.messagesUpdated = {
            self.tableView.reloadData()
            self.scrollToBottom(animated: false)
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
        tableView.contentInset.top = 20
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

// MARK: - Scrolling
extension ChatVC {

    private var bottomOffset: CGPoint {
        CGPoint(x: 0, y: max(-tableView.contentInset.top, tableView.contentSize.height - (tableView.bounds.size.height - tableView.contentInset.bottom)))
    }

    private func scrollToBottom(animated: Bool) {
        view.layoutIfNeeded()
        tableView.setContentOffset(bottomOffset, animated: animated)
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc private func keyboardWillShow(_ notification: NSNotification) {
        adjustContentForKeyboard(shown: true, notification: notification)
    }

    @objc private func keyboardWillHide(_ notification: NSNotification) {
        adjustContentForKeyboard(shown: false, notification: notification)
    }

    private func adjustContentForKeyboard(shown: Bool, notification: NSNotification) {
        guard let payload = KeyboardInfo(notification as Notification) else { return }

        let keyboardHeight = shown ? payload.frameEnd.size.height : messageInputBar.bounds.size.height

        if tableView.contentInset.bottom == keyboardHeight { return }

        let distanceFromBottom = bottomOffset.y - tableView.contentOffset.y

        var insets = tableView.contentInset

        insets.bottom = keyboardHeight

        UIView.animate(withDuration: payload.animationDuration, delay: 0, options: [payload.animationCurveOption], animations: {

            self.tableView.contentInset = insets
            self.tableView.scrollIndicatorInsets = insets

            if distanceFromBottom < 10 {
                self.tableView.contentOffset = self.bottomOffset
            }
        }, completion: nil)
    }
}