//
//  XIBView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 29/07/21.
//

import UIKit

class XIBView: UIView {

    var namerOfXIB: String { String(describing: Self.self) }
    
    private(set) var contentView : UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        guard let contentView = loadViewFromNib() else { return }
        
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        addSubview(contentView)
        
        self.contentView = contentView
    }

    private func loadViewFromNib() -> UIView? {
        let nib = UINib(nibName: namerOfXIB, bundle: .salesmate)
        return nib.instantiate(withOwner: self, options: nil)[0] as? UIView
    }
}
