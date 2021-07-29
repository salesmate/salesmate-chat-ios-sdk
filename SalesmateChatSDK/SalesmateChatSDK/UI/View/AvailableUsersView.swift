//
//  AvailableUsersView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 29/07/21.
//

import UIKit

class AvailableUsersViewModel {
    
    private let users: [User]
    private let maxNumberUserToShow: Int
    
    let spacing: CGFloat
    var profileViewModels: [CirculerProfileViewModel] = []
    
    init(users: [User], spacing: CGFloat, maxNumberUserToShow: Int) {
        self.users = users
        self.spacing = spacing
        self.maxNumberUserToShow = maxNumberUserToShow
        
        prepareProperties()
    }
    
    private func prepareProperties() {
        let availableUsers = users.filter({ $0.status == "available" })
        let usersToDisplay = availableUsers.prefix(maxNumberUserToShow)
        
        profileViewModels = usersToDisplay.map { CirculerProfileViewModel(display: .user($0), border: true) }
        
        let count = availableUsers.count - maxNumberUserToShow
        
        if count > 0 {
            profileViewModels.append(CirculerProfileViewModel(display: .count(count), border: true))
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
        stackView.spacing = viewModel.spacing
        
        profileViews = viewModel.profileViewModels.map { CirculerProfileView(viewModel: $0) }
        
        for profileView in profileViews {
            stackView.addArrangedSubview(profileView)
            
            profileView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                profileView.widthAnchor.constraint(equalTo: heightAnchor),
                profileView.heightAnchor.constraint(equalTo: heightAnchor),
            ])
        }
    }
}
