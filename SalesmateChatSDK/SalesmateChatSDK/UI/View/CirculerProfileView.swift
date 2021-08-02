//
//  CirculerProfileView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 29/07/21.
//

import UIKit

protocol CirculerProfileViewModelType {
    var borderWidth: CGFloat { get }
    var backgroundColorCode: String { get }

    var imageURL: URL? { get }

    var text: String? { get }
    var textColorCode: String { get }
    var textSize: CGFloat { get }
}

extension CirculerProfileViewModelType {

    private static var colorCodesForProfilePicBG: [String] {[
        "ff5622", "8157ff", "4d88ff",
        "ff416a", "683ab7", "03a8f4",
        "26c5da", "00ac7c", "c0ca33",
        "ffb301", "00cc88"
    ]}

    static func profileBackgroundColorCode(for name: String) -> String {
        var totalValue: Int = 0

        for character in name.utf8 {
            let stringSegment = "\(character)"
            let intValue = Int(stringSegment)!
            totalValue += intValue
        }

        let index = totalValue % colorCodesForProfilePicBG.count
        return colorCodesForProfilePicBG[index]
    }
}

class CirculerUserProfileViewModel: CirculerProfileViewModelType {

    let borderWidth: CGFloat
    let backgroundColorCode: String

    let imageURL: URL?

    let text: String?
    let textColorCode: String = "FFFFFF"
    let textSize: CGFloat = 22

    private let user: User

    init(user: User, borderWidth: CGFloat = 0) {
        self.user = user
        self.borderWidth = borderWidth

        text = user.firstName.first?.description
        imageURL = URL(string: user.profileUrl ?? "")
        backgroundColorCode = Self.profileBackgroundColorCode(for: user.firstName)
    }
}

class CirculerMoreProfileViewModel: CirculerProfileViewModelType {

    let borderWidth: CGFloat
    let backgroundColorCode: String = "EBECF0"

    let imageURL: URL? = nil

    let text: String?
    let textSize: CGFloat = 18
    let textColorCode: String = "505F79"

    private let count: Int

    init(count: Int, borderWidth: CGFloat = 0) {
        self.count = count
        self.borderWidth = borderWidth

        text = "+\(count)"
    }
}

class CirculerProfileView: UIView {

    var viewModel: CirculerProfileViewModelType? {
        didSet { display()  }
    }

    private let imageView = UIImageView()
    private let label = UILabel()

    init(viewModel: CirculerProfileViewModelType) {
        super.init(frame: CGRect.zero)
        self.viewModel = viewModel

        setup()
        display()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.width / 2.0
    }

    private func setup() {
        label.backgroundColor = .clear
        imageView.backgroundColor = .clear

        label.frame = self.bounds
        imageView.frame = self.bounds

        label.addAndFill(in: self)
        imageView.addAndFill(in: self)

        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center

        clipsToBounds = true
    }

    private func display() {
        guard let viewModel = viewModel else { return }

        label.isHidden = true
        imageView.isHidden = true

        backgroundColor = UIColor(hex: viewModel.backgroundColorCode)

        if let string = viewModel.text {
            label.isHidden = false
            label.text = string
            label.font = UIFont.systemFont(ofSize: viewModel.textSize, weight: .bold)
            label.textColor = UIColor(hex: viewModel.textColorCode)
        }

        if let imageURL = viewModel.imageURL {
            imageView.isHidden = false
            imageView.image = nil
            imageView.setImage(from: imageURL)
        }

        layer.borderWidth = viewModel.borderWidth
        layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
    }
}
