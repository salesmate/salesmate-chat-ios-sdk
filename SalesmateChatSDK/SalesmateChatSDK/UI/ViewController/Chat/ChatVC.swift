//
//  ChatVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 02/08/21.
//

import UIKit
import QuickLook

class ChatVC: UIViewController {

    // MARK: - Static Functions
    static func create(with viewModel: ChatViewModel) -> ChatVC {
        let storyboard = UIStoryboard(name: "Chat", bundle: Bundle(for: Self.self))
        let VC = storyboard.instantiateInitialViewController() as! Self

        VC.viewModel = viewModel
        VC.controller = viewModel.getController()

        return VC
    }

    // MARK: - Private Properties
    private var viewModel: ChatViewModel!
    private var controller: ChatController!

    private var shouldScrollToBottom: Bool = true
    private var shouldAdjustForKeyboard: Bool = false
    private let loading = ActivityIndicatorView(frame: .zero)
    private var rows: [MessageViewModelType] = []
    private let refreshControl = UIRefreshControl()
    private var previewFileURL: URL?
    private lazy var filePicker: FilePickerController = {
       FilePickerController(presenter: self)
    }()

    // MARK: - IBOutlets
    @IBOutlet private weak var viewTopWithoutLogo: ChatTopWithoutLogo!
    @IBOutlet private weak var viewTopWithLogo: ChatTopWithLogo!
    @IBOutlet private weak var viewTopWithUser: ChatTopWithUser!

    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet private weak var typingAnimation: ChatTypingAnimationView!
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

        if tableView.visibleCells.isEmpty {
            startLoading()
        }
    }

    // MARK: - ViewModel
    private func prepareViewModel() {
        viewModel.topBarUpdated = {
            self.prepareTopBar()
        }

        viewModel.messagesUpdated = {
            self.displayMessages()
        }

        viewModel.newMessagesUpdated = {
            self.displayNewMessages()
        }

        viewModel.sendingMessagesUpdated = {
            self.displayNewMessages()
        }

        viewModel.typing = { profileViewModel in
            self.typingAnimation.profileViewModel = profileViewModel
            self.showTypingAnimation()
        }
    }

    // MARK: - View
    private func prepareView() {
        prepareTopBar()
        prepareTableView()
        prepareInputBar()

        loading.loading.color = UIColor(hex: viewModel.actionColorCode)
    }

    private func prepareTopBar() {
        viewTopWithLogo.isHidden = true
        viewTopWithoutLogo.isHidden = true
        viewTopWithUser.isHidden = true

        let viewTop: ChatTopView?

        switch viewModel.topbar {
        case .withoutLogo:
            viewTop = viewTopWithoutLogo
        case .withLogo:
            viewTop = viewTopWithLogo
        case .assigned:
            viewTop = viewTopWithUser

            viewTopWithUser.didSelectExport = {
                self.downloadAndPreviewTranscript()
            }
        }

        viewTop?.viewModel = viewModel.topViewModel
        viewTop?.isHidden = false

        viewTop?.didSelectBack = {
            self.navigationController?.popViewController(animated: true)
        }

        viewTop?.didSelectClose = {
            self.resignFirstResponder()
            self.navigationController?.dismiss(animated: true)
        }
    }

    private func prepareInputBar() {
        if let actionColor = UIColor(hex: viewModel.actionColorCode) {
            messageInputBar.setActionColor(actionColor)
        }

        messageInputBar.delegate = self
        messageInputBar.showAttachmentOption(viewModel.allowAttachment)
        messageInputBar.enableEmailMode(viewModel.isEmailAddressMandatory)
    }

    private func prepareTableView() {
        tableView.contentInset.top = 20
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()

        tableView.register(nibWithCellClass: SendMessageCell.self)
        tableView.register(nibWithCellClass: ReceivedMessageCell.self)
    }

    private func addRefreshControl() {
        guard controller.page.size <= tableView.numberOfRows(inSection: 0) else { return }

        refreshControl.tintColor = UIColor(hex: viewModel.actionColorCode)
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(loadMoreMessages(_:)), for: .valueChanged)
    }

    // MARK: - Data
    private func startLoading() {
        guard viewModel.isNew == false else { return }

        tableView.tableFooterView = loading
        loading.frame = tableView.bounds

        controller.startLoadingDetails()
    }

    private func displayMessages() {
        let isFirst = (rows.count == 0)
        let newItemCount = viewModel.messageViewModels.count - rows.count
        let initialContentOffSet = tableView.contentOffset.y < 0 ? 0 : tableView.contentOffset.y

        rows = viewModel.messageViewModels

        hideTypingAnimation()
        tableView.removeTableFooterView()
        refreshControl.endRefreshing()

        tableView.reloadData {
            if isFirst {
                self.scrollToBottom(animated: false)
                self.addRefreshControl()
            } else {
                self.tableView.safeScrollToRow(at: IndexPath(row: newItemCount, section: 0), at: .top, animated: false)
                self.tableView.contentOffset.y += initialContentOffSet
                self.tableView.safeScrollToRow(at: IndexPath(row: newItemCount - 1, section: 0), at: .top, animated: true)
            }
        }

        messageInputBar.enableEmailMode(viewModel.isEmailAddressMandatory)
    }

    private func displayNewMessages() {
        let indexPathsLastRow = tableView.indexPathForLastRow
        let indexPathsLastVisibleRow = tableView.indexPathsForVisibleRows?.last

        let isLastVisiable: Bool = (indexPathsLastRow == indexPathsLastVisibleRow)
        let rowsCount = rows.count

        rows = viewModel.messageViewModels

        hideTypingAnimation()

        let newRowsCount = rows.count
        let diff = newRowsCount - rowsCount

        if diff > 0 {
            let indexPaths = (rowsCount..<newRowsCount).map { IndexPath(row: $0, section: 0) }

            tableView.performBatchUpdates {
                tableView.insertRows(at: indexPaths, with: .bottom)
            } completion: { _ in
                if isLastVisiable {
                    self.scrollToBottom(animated: true)
                }
            }
        } else {
            tableView.reloadData {
                if isLastVisiable && (rowsCount < self.rows.count) {
                    self.scrollToBottom(animated: true)
                }
            }
        }

        messageInputBar.enableEmailMode(viewModel.isEmailAddressMandatory)
    }

    @objc private func loadMoreMessages(_ sender: Any) {
        controller.getMessages()
    }
}

// MARK: - UITableViewDataSource
extension ChatVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let messageViewModel = rows[indexPath.row]

        switch messageViewModel.alignment {
        case .left: return getReceivedMessageCell(for: messageViewModel, for: indexPath)
        case .right: return getSendMessageCell(for: messageViewModel, for: indexPath)
        }
    }

    private func getReceivedMessageCell(for viewModel: MessageViewModelType, for indexPath: IndexPath) -> MessageCell {
        let cell = tableView.dequeueReusableCell(withClass: ReceivedMessageCell.self, for: indexPath)

        cell.viewModel = viewModel
        cell.sendEmailAddress = { email in
            self.sendEmail(email, asMessage: false)
        }
        cell.didSelectFile = {
            self.downloadAndPreviewFile(at: $0)
        }

        return cell
    }

    private func getSendMessageCell(for viewModel: MessageViewModelType, for indexPath: IndexPath) -> MessageCell {
        let cell = tableView.dequeueReusableCell(withClass: SendMessageCell.self, for: indexPath)

        cell.viewModel = viewModel
        cell.shouldRetry = { messageViewModel in
            self.controller.retryMessage(of: messageViewModel)
        }
        cell.didSelectFile = {
            self.downloadAndPreviewFile(at: $0)
        }

        return cell
    }
}

// MARK: - Scrolling
extension ChatVC {

    private var bottomOffset: CGPoint {
        CGPoint(x: 0, y: max(-tableView.contentInset.top, tableView.contentSize.height - (tableView.bounds.size.height - tableView.contentInset.bottom)))
    }

    private func scrollToBottom(animated: Bool) {
        guard let indexPath = tableView.indexPathForLastRow else { return }

        view.layoutIfNeeded()

        tableView.safeScrollToRow(at: indexPath, at: .bottom, animated: animated)
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

// MARK: - FilePickerControllerPresenter
extension ChatVC: FilePickerControllerPresenter {

    func filePicker(_ picker: FilePickerController, didSelecte file: FileToUpload) {
        controller.sendMessage(with: file)
    }
}

// MARK: - MessageComposeViewDelegate
extension ChatVC: MessageComposeViewDelegate {

    func didTapSend(with text: String) {
        if viewModel.isEmailAddressMandatory {
            sendEmail(text)
        } else {
            controller.sendMessage(with: text)
            messageInputBar.clear()
        }
    }

    func didTapAttachment() {
        askAttachmentSource()
    }

    private func askAttachmentSource() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let photos = UIAlertAction(title: "Take from photos", style: .default) { _ in
            self.filePicker.showMediaPicker()
        }

        let camera = UIAlertAction(title: "Capture from camera", style: .default) { _ in
            self.filePicker.showCamera()
        }

        let document = UIAlertAction(title: "Select document", style: .default) { _ in
            self.filePicker.showDocumentPicker()
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)

        sheet.addAction(photos)
        sheet.addAction(camera)
        sheet.addAction(document)
        sheet.addAction(cancel)

        present(sheet, animated: true)
    }
}

// MARK: - Mail
extension ChatVC {

    private func sendEmail(_ email: String, asMessage: Bool = true) {
        if let email = EmailAddress(rawValue: email) {
            controller.send(email, asMessage: asMessage)
            messageInputBar.clear()
        } else {
            showAlert(title: "Email", message: "That email doesn't look quite right.")
        }
    }
}

// MARK: - Typing Animation
extension ChatVC {

    private func showTypingAnimation() {
        guard !typingAnimation.isAnimating else { return }

        tableView.tableFooterView = typingAnimation

        typingAnimation.frame.size = CGSize(width: tableView.bounds.width, height: 45)

        typingAnimation.start()

        tableView.scrollRectToVisible(tableView.tableFooterView!.frame, animated: true)

        run(afterDelay: 5) { [weak self] in
            self?.hideTypingAnimation()
        }
    }

    private func hideTypingAnimation() {
        typingAnimation.stop()
        tableView.removeTableFooterView()
    }
}

// MARK: - File Preview
extension ChatVC {

    private func downloadAndPreviewTranscript() {
        showHUD()

        controller.getTranscript { location in
            self.hideHUD()

            if let location = location {
                self.previewFile(at: location)
            } else {
                // TODO: Show error.
            }
        }
    }

    private func downloadAndPreviewFile(at url: URL) {
        url.downloadAndSave { result in
            switch result {
            case .success(let filePath):
                self.previewFile(at: filePath)
            case .failure:
                break
            }
        }
    }

    private func previewFile(at url: URL) {
        previewFileURL = url

        runOnMain {
            let VC = QLPreviewController()
            VC.dataSource = self
            self.present(VC, animated: true, completion: nil)
        }
    }
}

extension ChatVC: QLPreviewControllerDataSource {

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        previewFileURL! as NSURL
    }
}
