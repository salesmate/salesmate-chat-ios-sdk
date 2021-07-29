//
//  NewChatButton.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 29/07/21.
//

import UIKit

class NewChatButton: UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    private func setup() {
        layer.cornerRadius = 10
        clipsToBounds = true
        
        setTitle("Start New Chat", for: .normal)
        setImage(UIImage.startNewChat, for: .normal)
        
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            
        semanticContentAttribute = .forceRightToLeft
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
    }
    
    override var backgroundColor: UIColor? {
        didSet {
            guard let color = backgroundColor else { return }
            
            if color.isDark {
                setTitleColor(.white, for: .normal)
                tintColor = .white
            } else {
                setTitleColor(.black, for: .normal)
                tintColor = .black
            }
        }
    }
}

