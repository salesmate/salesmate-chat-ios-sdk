//
//  AvailableUsersView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 29/07/21.
//

import UIKit

class AvailableUsersViewModel {

    struct Attributes {
        let spacing: CGFloat
        let borderWidth: CGFloat
        let maxNumberUserToShow: Int
    }

    private let users: [User]
    let attributes: Attributes

    var profileViewModels: [CirculerProfileViewModelType] = []

    init(users: [User], attributes: Attributes) {
        self.users = users
        self.attributes = attributes

        prepareProperties()
    }

    private func prepareProperties() {
        let availableUsers = users.filter({ $0.status != "available" })
        let usersToDisplay = availableUsers.prefix(attributes.maxNumberUserToShow)

        profileViewModels = usersToDisplay.map { CirculerUserProfileViewModel(user: $0, borderWidth: attributes.borderWidth) }

        let count = availableUsers.count - attributes.maxNumberUserToShow

        if count > 0 {
            profileViewModels.append(CirculerMoreProfileViewModel(count: count))
        }
    }
}

class AvailableUsersView: UIView {

    var viewModel: AvailableUsersViewModel? {
        didSet { display() }
    }

    private let stackView: UIStackView = UIStackView()
    private var profileViews: [CirculerProfileView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill

        stackView.addAndFill(in: self)
    }

    private func display() {
        guard let viewModel = viewModel else { return }

        stackView.subviews.forEach { $0.removeFromSuperview() }
        stackView.spacing = viewModel.attributes.spacing

        profileViews = viewModel.profileViewModels.map { CirculerProfileView(viewModel: $0) }

        for profileView in profileViews {
            stackView.addArrangedSubview(profileView)

            profileView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                profileView.widthAnchor.constraint(equalTo: heightAnchor),
                profileView.heightAnchor.constraint(equalTo: heightAnchor)
            ])
        }
    }
}
