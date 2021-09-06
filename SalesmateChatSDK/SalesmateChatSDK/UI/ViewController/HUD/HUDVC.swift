//
//  HUDVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 06/09/21.
//

import UIKit

class HUDViewModel {

    var foregroundColorCode: String

    init(look: Configeration.LookAndFeel) {
        foregroundColorCode = look.actionColor
    }
}

class HUDVC: UIViewController {

    // MARK: - Static Functions
    static func create(with viewModel: HUDViewModel) -> HUDVC {
        let storyboard = UIStoryboard(name: "HUD", bundle: Bundle(for: Self.self))
        let hudVC = storyboard.instantiateInitialViewController() as! HUDVC

        hudVC.viewModel = viewModel

        return hudVC
    }

    static var shared: HUDVC?
    var viewModel: HUDViewModel!

    @IBOutlet private weak var loading: UIActivityIndicatorView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loading.color = UIColor(hex: viewModel.foregroundColorCode)
    }
}
