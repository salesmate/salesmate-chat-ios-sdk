//
//  ChatVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 02/08/21.
//

import UIKit
import QuickLook

protocol CloseConversationViewDelegate: AnyObject {
    func didTapStartChat()
}

class CloseConversationView: UIView {

    // MARK: - IBOutlets
    @IBOutlet private weak var btnStartChat: UIButton!

    // MARK: - Properties
    weak var delegate: CloseConversationViewDelegate?

    // MARK: - Interface
    func setActionColor(_ color: UIColor) {
        btnStartChat.backgroundColor = color
    }

    func shouldShowStartChat(_ show: Bool) {
        btnStartChat.isHidden = !show
    }

    // MARK: - Actions
    @IBAction private func btnStartNewChatPressed(_ sender: UIButton) {
        delegate?.didTapStartChat()
    }
}

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
    private var rows: [ChatRow] = []
    private let refreshControl = UIRefreshControl()
    private var previewFileURL: URL?
    private lazy var filePicker: FilePickerController = {
       FilePickerController(presenter: self)
    }()

    private let askEmailCell: AskContactDetailCell? = AskContactDetailCell.instantiate()
    private let ratingCell: AskRatingCell? = AskRatingCell.instantiate()

    private var _inputAccessoryView: UIView?
    
    // MARK: - IBOutlets
    @IBOutlet private weak var viewTopWithoutLogo: ChatTopWithoutLogo!
    @IBOutlet private weak var viewTopWithLogo: ChatTopWithLogo!
    @IBOutlet private weak var viewTopWithUser: ChatTopWithUser!

    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet private weak var typingAnimation: ChatTypingAnimationView!
    @IBOutlet private weak var messageInputBar: MessageComposeView!
    @IBOutlet private weak var closeConversationView: CloseConversationView!
    @IBOutlet private weak var askContactDetailView: UIView!

    // MARK: - Override
    override var canBecomeFirstResponder: Bool { true }
    override var canResignFirstResponder: Bool { true }
    override var inputAccessoryView: UIView? { _inputAccessoryView }

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

        viewModel.bottomBarUpdated = { bottom in
            self.updateBottomBar(to: bottom)
        }
    }
    

    // MARK: - View
    private func prepareView() {
        prepareTopBar()
        prepareTableView()
        prepareInputBar()
        prepareContactDetailView();
        updateBottomBar(to: viewModel.bottom)

        loading.loading.color = UIColor(hex: viewModel.actionColorCode)

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
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
    
    private func prepareContactDetailView(){
        
        guard let contactDetailForm = self.askContactDetailView.viewWithTag(1) as? ContactDetailForm else{
            return;
        }
        
        contactDetailForm.submitContactDetail = { name, email in
            //TODO: Send name via analytics
            self.sendEmail(email.rawValue)
        }
    }

    private func prepareInputBar() {
        if let actionColor = UIColor(hex: viewModel.actionColorCode) {
            messageInputBar.setActionColor(actionColor)
            closeConversationView.setActionColor(actionColor)
        }

        closeConversationView.delegate = self
        messageInputBar.delegate = self
        messageInputBar.showAttachmentOption(viewModel.allowAttachment)
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

    private func updateBottomBar(to bottom: ChatViewModel.Bottom) {
        switch bottom {
        case .message:
            if _inputAccessoryView == messageInputBar{
                return;
            }
            closeConversationView.isHidden = true
            _inputAccessoryView = messageInputBar
            self.becomeFirstResponder()
        case .askContactDetail:
            if _inputAccessoryView == askContactDetailView{
                return;
            }
            closeConversationView.isHidden = true
            _inputAccessoryView = askContactDetailView
            self.resignFirstResponder()
        case .startNewChat:
            closeConversationView.isHidden = false
            closeConversationView.shouldShowStartChat(viewModel.showStartNewChat)
            _inputAccessoryView = nil
            self.resignFirstResponder()
        }
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
        let newItemCount = viewModel.rows.count - rows.count
        let initialContentOffSet = tableView.contentOffset.y < 0 ? 0 : tableView.contentOffset.y

        rows = viewModel.rows

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
    }

    private func displayNewMessages() {
        let indexPathsLastRow = tableView.indexPathForLastRow
        let indexPathsLastVisibleRow = tableView.indexPathsForVisibleRows?.last

        let isLastVisiable: Bool = (indexPathsLastRow == indexPathsLastVisibleRow)
        let rowsCount = rows.count

        rows = viewModel.rows

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
        let row = rows[indexPath.row]

        switch row {
        case .message: return getMessageCell(for: row, at: indexPath)
        case .askEmail: return getAskEmailCell(for: row)
        case .askRating: return getAskRatingCell(for: row)
        }
    }

    private func getMessageCell(for row: ChatRow, at indexPath: IndexPath) -> UITableViewCell {
        guard case .message(let viewModel) = row else { return UITableViewCell() }

        switch viewModel.alignment {
        case .left: return getReceivedMessageCell(for: viewModel, for: indexPath)
        case .right: return getSendMessageCell(for: viewModel, for: indexPath)
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

    private func getAskEmailCell(for row: ChatRow) -> UITableViewCell {
        guard case .askEmail(let viewModel) = row else { return UITableViewCell() }

        if let email = self.viewModel.email?.rawValue {
            viewModel.email = email
        }

        askEmailCell?.viewModel = viewModel
        askEmailCell?.submitContactDetail = { _, email in
            self.sendEmail(email.rawValue)
        }

        return askEmailCell ?? UITableViewCell()
    }

    private func getAskRatingCell(for row: ChatRow) -> UITableViewCell {
        guard case .askRating(let viewModel) = row else { return UITableViewCell() }

        ratingCell?.viewModel = viewModel
        ratingCell?.sendRating = { rating in
            guard let rating = Int(rating) else { return }
            self.controller.sendRating(rating)
        }
        ratingCell?.sendRemark = { remark in
            self.controller.sendRemark(remark)
        }

        return ratingCell ?? UITableViewCell()
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

    func filePicker(_ picker: FilePickerController, errorOccured message: String) {
        showAlert(title: nil, message: message)
    }
}

// MARK: - MessageComposeViewDelegate
extension ChatVC: MessageComposeViewDelegate {

    func didTapSend(with text: String) {
        controller.sendMessage(with: text)
        messageInputBar.clear()
    }

    func didTapAttachment() {
        askAttachmentSource()
    }

    func textDidChange() {
        controller.visitorIsTyping()
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

        if #available(iOS 13.0, *) {
            sheet.overrideUserInterfaceStyle = .light
        }

        present(sheet, animated: true)
    }
}

// MARK: - Mail
extension ChatVC {

    private func sendEmail(_ email: String, asMessage: Bool = true) {
        if let email = EmailAddress(rawValue: email) {
            controller.send(email, asMessage: asMessage)
            messageInputBar.clear()
            self.viewModel.bottom = .message;
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

extension ChatVC: CloseConversationViewDelegate {

    func didTapStartChat() {
        let VC = ChatVC.create(with: viewModel.newChatViewModel)

        guard var viewControllers = navigationController?.viewControllers else { return }

        _ = viewControllers.popLast()
        viewControllers.append(VC)

        navigationController?.setViewControllers(viewControllers, animated: true)
    }
}
