//
//  AskEmailView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 11/08/21.
//

import UIKit

class AskEmailView: XIBView {

    @IBOutlet private weak var viewEmail: UIView!

    override func setup() {
        super.setup()

        contentView?.layer.borderWidth = 1
        contentView?.layer.borderColor = UIColor(hex: "EBECF0")?.cgColor

        viewEmail.layer.borderWidth = 1
        viewEmail.layer.borderColor = UIColor(hex: "DFE1E6")?.cgColor
    }

    private func display() {

    }
}
