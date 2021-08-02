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
    @IBOutlet private weak var viewTop: UIView!
    @IBOutlet private weak var imgvTopPattern: UIImageView!
    @IBOutlet private weak var btnBack: UIButton!
    @IBOutlet private weak var userView: AvailableUsersView!
    @IBOutlet private weak var lblTitle: UILabel!
    @IBOutlet private weak var lblResponseTime: UILabel!
    @IBOutlet private weak var btnClose: UIButton!

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
        imgvTopPattern.image = UIImage(viewModel.backgroundPatternName)

        btnBack.tintColor = foregroundColor
        btnClose.tintColor = foregroundColor

        userView.viewModel = viewModel.availableuserViewModel

        lblResponseTime.text = viewModel.responseTime
        lblTitle.textColor = foregroundColor
        lblResponseTime.textColor = foregroundColor
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
