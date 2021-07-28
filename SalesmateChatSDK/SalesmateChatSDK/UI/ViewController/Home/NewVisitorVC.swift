//
//  NewVisitorVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
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

class NewVisitorVC: UIViewController {
    
    // MARK: - Static Functions
    static func create(with viewModel: NewVisitorViewModelType) -> NewVisitorVC {
        let storyboard = UIStoryboard(name: "NewVisitor", bundle: Bundle(for: Self.self))
        let VC = storyboard.instantiateInitialViewController() as! NewVisitorVC
        
        VC.viewModel = viewModel
        
        return VC
    }
    
    // MARK: - Private Properties
    private var viewModel: NewVisitorViewModelType!
    
    // MARK: - IBOutlets
    @IBOutlet private weak var lblResponseTime: UILabel!
    @IBOutlet private weak var lblPowerBy: UILabel!
    @IBOutlet private weak var btnStartChat: UIButton!
    
    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareView()
    }
    
    // MARK: - View
    private func prepareView() {
        lblResponseTime.text = viewModel.responseTime
        lblPowerBy.isHidden = !viewModel.showPowerBy
        
        btnStartChat.backgroundColor = UIColor(hex: viewModel.buttonColorCode)
    }
}
