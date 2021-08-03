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

    @IBOutlet private weak var messageInputBar: MessageComposeView!

    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()

        prepareView()
        becomeFirstResponder()
    }

    override var canBecomeFirstResponder: Bool { true }
    override var canResignFirstResponder: Bool { true }
    override var inputAccessoryView: UIView? { messageInputBar }

    // MARK: - View
    private func prepareView() {
        prepareTopBar()
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

    // MARK: - Actions
    @IBAction private func btnBackAllPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func btnCloseAllPressed(_ sender: UIButton) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
