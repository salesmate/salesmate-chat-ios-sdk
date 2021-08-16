//
//  StartVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 06/08/21.
//

import UIKit

class StartVC: UIViewController {

    // MARK: - Static Functions
    static func create(with viewModel: StartViewModel) -> Self {
        let storyboard = UIStoryboard(name: "Start", bundle: Bundle(for: Self.self))
        let startVC = storyboard.instantiateInitialViewController() as! Self

        startVC.viewModel = viewModel

        return startVC
    }

    var viewModel: StartViewModel!

    @IBOutlet private weak var loading: UIActivityIndicatorView!
}
