//
//  RatingReviewView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 31/08/21.
//

import UIKit

class AskRatingCell: UITableViewCell {

    // MARK: - Constants
    private static let nib: UINib = UINib(nibName: "AskRatingCell", bundle: .salesmate)

    static func instantiate() -> AskRatingCell? {
        nib.instantiate(withOwner: self, options: nil)[0] as? AskRatingCell
    }

    // MARK: - Outlet
    @IBOutlet private weak var profileView: CirculerProfileView!
    @IBOutlet private weak var viewMainContainer: UIView!
    @IBOutlet private weak var viewReview: UIView!
    @IBOutlet private weak var lblRating: UILabel!
    @IBOutlet private weak var txtRemark: UITextField!

    @IBOutlet private weak var btnRating1: UIButton!
    @IBOutlet private weak var btnRating2: UIButton!
    @IBOutlet private weak var btnRating3: UIButton!
    @IBOutlet private weak var btnRating4: UIButton!
    @IBOutlet private weak var btnRating5: UIButton!
    @IBOutlet private weak var btnSendRemark: UIButton!

    // MARK: - Properties
    private var enableActionColor: UIColor?
    private var disableActionColor: UIColor? = UIColor(hex: "EBECF0")

    var viewModel: AskRatingViewModel? {
        didSet { display() }
    }

    var sendRating: ((String) -> Void)?
    var sendRemark: ((String) -> Void)?

    // MARK: - Override
    override func awakeFromNib() {
        super.awakeFromNib()

        viewMainContainer?.layer.borderWidth = 1
        viewMainContainer?.layer.borderColor = UIColor(hex: "EBECF0")?.cgColor
    }

    // MARK: - Private
    private func display() {
        guard let viewModel = viewModel else { return }

        profileView.viewModel = viewModel.profileViewModel

        if let color = UIColor(hex: viewModel.actionColorCode) {
            setActionColor(color)
        }

        prepareRatingButtons(viewModel.rating)

        if let ratingText = viewModel.ratingText {
            viewReview.isHidden = false
            lblRating.text = ratingText
        } else {
            viewReview.isHidden = true
            lblRating.text = nil
        }

        if let remark = viewModel.remark, !remark.isEmpty {
            txtRemark.text = remark
            txtRemark.isEnabled = false
            btnSendRemark.isHidden = true
        } else {
            txtRemark.text = nil
            txtRemark.isEnabled = true
            btnSendRemark.isHidden = false
        }
    }

    private func prepareRatingButtons(_ selectedRating: Int?) {
        guard let viewModel = viewModel else { return }

        btnRating1.setTitle(viewModel.ratingEmojies[0], for: .normal)
        btnRating2.setTitle(viewModel.ratingEmojies[1], for: .normal)
        btnRating3.setTitle(viewModel.ratingEmojies[2], for: .normal)
        btnRating4.setTitle(viewModel.ratingEmojies[3], for: .normal)
        btnRating5.setTitle(viewModel.ratingEmojies[4], for: .normal)

        let ratingButtons = [btnRating1, btnRating2, btnRating3, btnRating4, btnRating5]

        if let selectedRating = selectedRating {
            ratingButtons.forEach { $0?.isEnabled = false }
            ratingButtons.forEach { $0?.alpha = 0.5 }
            ratingButtons[selectedRating - 1]?.isEnabled = true
            ratingButtons[selectedRating - 1]?.alpha = 1
        } else {
            ratingButtons.forEach { $0?.isEnabled = true }
            ratingButtons.forEach { $0?.alpha = 1 }
        }
    }

    private func setActionColor(_ color: UIColor) {
        enableActionColor = color
        updateSendButton()
    }

    private func updateSendButton() {
        if txtRemark.text?.isEmpty ?? true {
            btnSendRemark.isEnabled = false
            btnSendRemark.backgroundColor = disableActionColor
        } else {
            btnSendRemark.isEnabled = true
            btnSendRemark.backgroundColor = enableActionColor
        }
    }

    // MARK: - Event
    @IBAction private func btnRatingPressed(_ sender: UIButton) {
        sendRating?(String(sender.tag))
    }

    @IBAction private func txtRemarkChange(_ textField: UITextField) {
        updateSendButton()
    }

    @IBAction private func btnSendRemarkPressed(_ sender: UIButton) {
        guard let remark = txtRemark.text, !remark.isEmpty else { return }
        sendRemark?(remark)
    }
}
