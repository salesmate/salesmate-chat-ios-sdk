//
//  ConversationCell.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 29/07/21.
//

import UIKit

class ConversationCellViewModel {
    
    private let conversation: Conversation
    private let user: User?
    
    let profileViewModel: CirculerProfileViewModelType?
    let name: String
    
    let lastMessage: String?
    let isRead: Bool
    let time: String
    
    init(conversation: Conversation, user: User?) {
        self.conversation = conversation
        self.user = user
        
        if let user = user {
            profileViewModel = CirculerUserProfileViewModel(user: user, border: false)
        } else {
            profileViewModel = nil
        }
        
        name = "\(user?.firstName ?? "") \(user?.lastName ?? "")"
        
        lastMessage = conversation.lastMessage?.messageSummary
        isRead = conversation.isRead
        time = conversation.lastMessageDate.shortDurationString
    }
}

class ConversationCell: UITableViewCell {

    static let ID = "ConversationCell"
    
    var viewModel: ConversationCellViewModel? {
        didSet { display() }
    }
    
    @IBOutlet private var readDotView: UIView!
    @IBOutlet private var profileView: CirculerProfileView!
    @IBOutlet private var lblName: UILabel!
    @IBOutlet private var lblTime: UILabel!
    @IBOutlet private var lblLastMessage: UILabel!
    
    private func display() {
        guard let viewModel = viewModel else { return }
        
        readDotView.isHidden = viewModel.isRead
        profileView.viewModel = viewModel.profileViewModel
        
        lblName.text = viewModel.name
        lblTime.text = viewModel.time
        lblLastMessage.text = viewModel.lastMessage
    }
}
