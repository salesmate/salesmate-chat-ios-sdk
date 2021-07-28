//
//  HomeVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
//

import UIKit

class HomeVC: UIViewController {

    // MARK: - Static Functions
    static func create(with viewModel: HomeViewModelType) -> HomeVC {
        let storyboard = UIStoryboard(name: "Home", bundle: Bundle(for: Self.self))
        let homeVC = storyboard.instantiateInitialViewController() as! HomeVC
        
        homeVC.viewModel = viewModel
        
        return homeVC
    }
    
    // MARK: - Private Properties
    private var viewModel: HomeViewModelType!
    
    // MARK: - IBOutlets
    @IBOutlet private weak var viewTop: UIView!
    @IBOutlet private weak var imgvTopPattern: UIImageView!
    
    @IBOutlet private weak var imgvLogoContainer: UIView!
    @IBOutlet private weak var imgvLogo: UIImageView!
    
    @IBOutlet private weak var lblGreeting: UILabel!
    @IBOutlet private weak var lblTeamIntro: UILabel!
    
    @IBOutlet private weak var viewContainer: UIView!
    
    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()

        prepareView()
    }
    
    // MARK: - View
    private func prepareView() {
        prepareTopView()
        
        viewContainer.layer.cornerRadius = 10
        viewContainer.clipsToBounds = true
        
        add(child: NewVisitorVC.create(with: viewModel.newVisitorViewModel), in: viewContainer)
    }
    
    private func prepareTopView() {
        viewTop.backgroundColor = UIColor(hex: viewModel.backgroundColorCode)
        
        if viewTop.backgroundColor?.isDark ?? true {
            lblGreeting.textColor = UIColor.white
            lblTeamIntro.textColor = UIColor.white
        } else {
            lblGreeting.textColor = UIColor.black
            lblTeamIntro.textColor = UIColor.black
        }
        
        if let link = viewModel.headerLogoURL {
            imgvLogo.setImage(from: link)
        }
        
        if let link = viewModel.backgroundPatternURL {
            imgvTopPattern.setImage(from: link)
        }
        
        imgvLogoContainer.isHidden = (viewModel.headerLogoURL == nil)
        
        lblGreeting.text = viewModel.greeting
        lblTeamIntro.text = viewModel.teamIntro
    }
}
