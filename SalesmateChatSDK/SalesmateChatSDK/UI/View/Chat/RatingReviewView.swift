//
//  RatingReviewView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 31/08/21.
//

import UIKit

class RatingReviewViewModel {

    private let config: [Configeration.Rating]

    private(set) var rating: String?
    private(set) var review: String?

    init(config: [Configeration.Rating], rating: Int? = nil, review: String? = nil) {
        self.config = config

        if let rating = rating {
            self.rating = config.first(where: { $0.id == String(rating) })?.label
        }

        self.review = review
    }
}

class RatingReviewView: XIBView {

    // MARK: - Outlet
    @IBOutlet private weak var viewReview: UIView!
    @IBOutlet private weak var lblRating: UILabel!

    // MARK: - Properties
    var viewModel: RatingReviewViewModel? {
        didSet { display() }
    }

    // MARK: - Override
    override func setup() {
        super.setup()

        contentView?.layer.borderWidth = 1
        contentView?.layer.borderColor = UIColor(hex: "EBECF0")?.cgColor
    }

    // MARK: - Private
    private func display() {
        guard let viewModel = viewModel else { return }

        if let rating = viewModel.rating {
            viewReview.isHidden = false
            lblRating.text = rating
        } else {
            viewReview.isHidden = true
            lblRating.text = nil
        }
    }
}
