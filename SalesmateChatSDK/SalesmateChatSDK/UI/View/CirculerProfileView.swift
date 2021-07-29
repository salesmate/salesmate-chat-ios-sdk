//
//  CirculerProfileView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 29/07/21.
//

import UIKit

class CirculerProfileViewModel {
    
    enum Display {
        case user(User)
        case count(Int)
    }
    
    private let display: Display
    
    let border: Bool
    
    var imageURL: URL?
    
    var text: String?
    var textColorCode: String = "505F79"
    
    var generateRandomBGColor: Bool = true
    var textToGenerateBGColor: String = ""
    
    init(display: Display, border: Bool = false) {
        self.display = display
        self.border = border
        
        prepareProperties()
    }
    
    private func prepareProperties() {
        switch display {
        case .user(let user):
            text = user.firstName.first?.description
            textColorCode = "FFFFFF"
            generateRandomBGColor = true
            textToGenerateBGColor = user.firstName
            
            if let profilePath = user.profileUrl {
                imageURL = URL(string: profilePath)
            }
        case .count(let count):
            text = "+\(count)"
            textColorCode = "505F79"
            generateRandomBGColor = false
        }
    }
}

class CirculerProfileView: UIView {
    
    var viewModel: CirculerProfileViewModel? {
        didSet { display()  }
    }
    
    private let imageView = UIImageView()
    private let label = UILabel()
    
    init(viewModel: CirculerProfileViewModel) {
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
        
        if viewModel.generateRandomBGColor {
            backgroundColor = UIColor.getRandomBgColor(forName: viewModel.textToGenerateBGColor)
        } else {
            backgroundColor = UIColor(hex: "EBECF0")
        }

        if let string = viewModel.text {
            label.isHidden = false
            label.text = string
            
            label.textColor = UIColor(hex: viewModel.textColorCode)
        }

        if let imageURL = viewModel.imageURL {
            imageView.isHidden = false
            imageView.image = nil
            imageView.setImage(from: imageURL)
        }
                
        if viewModel.border {
            layer.borderWidth = 2
            layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        } else {
            layer.borderWidth = 0
        }
    }
}
