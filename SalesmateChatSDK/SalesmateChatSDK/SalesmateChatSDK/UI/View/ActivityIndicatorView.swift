//
//  ActivityIndicatorView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 06/08/21.
//

import UIKit

class ActivityIndicatorView: UIView {

    let loading = UIActivityIndicatorView(style: .whiteLarge)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        loading.color = .systemGray
        loading.translatesAutoresizingMaskIntoConstraints = false
        loading.startAnimating()
        loading.hidesWhenStopped = true

        addSubview(loading)

        NSLayoutConstraint.activate([
            loading.centerXAnchor.constraint(equalTo: centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        loading.startAnimating()
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()

        loading.stopAnimating()
    }
}
