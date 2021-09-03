//
//  TypingAnimationView.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 31/08/21.
//

import UIKit

class ChatTypingAnimationView: UIView {

    @IBOutlet private weak var profileView: CirculerProfileView!
    @IBOutlet private weak var animationView: TypingAnimationView!

    var profileViewModel: CirculerUserProfileViewModel? {
        didSet { profileView.viewModel = profileViewModel }
    }

    var isAnimating: Bool { animationView.isAnimating }

    func start() {
        animationView.start()
    }

    func stop() {
        animationView.stop()
    }
}

class TypingAnimationView: UIView {

    private static let tintColor = UIColor(hex: "606D8A")

    private let dot1 = UIImageView(image: UIImage.typingDot)
    private let dot2 = UIImageView(image: UIImage.typingDot)
    private let dot3 = UIImageView(image: UIImage.typingDot)

    private var dot1Bottom: NSLayoutConstraint?
    private var dot2Bottom: NSLayoutConstraint?
    private var dot3Bottom: NSLayoutConstraint?

    private let stackView: UIStackView = {
        let stack = UIStackView()

        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        return stack
    }()

    private(set) var isAnimating: Bool = false

    init() {
        super.init(frame: .zero)

        prepareForAnimation()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        prepareForAnimation()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        prepareForAnimation()
    }

    func start() {
        guard !isAnimating else { return }

        isAnimating = true

        animateDots()
    }

    func stop() {
        isAnimating = false

        dot1.layer.removeAllAnimations()
        dot2.layer.removeAllAnimations()
        dot3.layer.removeAllAnimations()

        dot1Bottom?.constant = 0
        dot2Bottom?.constant = 0
        dot3Bottom?.constant = 0

        layoutIfNeeded()
    }

    private func prepareForAnimation() {
        dot1.tintColor = Self.tintColor
        dot2.tintColor = Self.tintColor
        dot3.tintColor = Self.tintColor

        let viewDot1 = UIView()
        let viewDot2 = UIView()
        let viewDot3 = UIView()

        for (view, imageView) in zip([viewDot1, viewDot2, viewDot3], [dot1, dot2, dot3]) {
            imageView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(imageView)

            stackView.addArrangedSubview(view)
        }

        addSubview(stackView)

        dot1Bottom = dot1.bottomAnchor.constraint(equalTo: viewDot1.bottomAnchor)
        dot2Bottom = dot2.bottomAnchor.constraint(equalTo: viewDot2.bottomAnchor)
        dot3Bottom = dot3.bottomAnchor.constraint(equalTo: viewDot3.bottomAnchor)

        NSLayoutConstraint.activate([
            dot1Bottom!,
            dot2Bottom!,
            dot3Bottom!,

            dot1.centerXAnchor.constraint(equalTo: viewDot1.centerXAnchor),
            dot2.centerXAnchor.constraint(equalTo: viewDot2.centerXAnchor),
            dot3.centerXAnchor.constraint(equalTo: viewDot3.centerXAnchor),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func animateDots() {
        let duration = 0.25
        let constant = -(frame.height - dot1.frame.height)

        dot1Bottom?.constant = constant

        UIView.animate(withDuration: duration, delay: duration * 0, options: [.curveEaseInOut]) {
            self.layoutIfNeeded()
        }

        dot1Bottom?.constant = 0
        dot2Bottom?.constant = constant

        UIView.animate(withDuration: duration, delay: duration * 1, options: [.curveEaseInOut]) {
            self.layoutIfNeeded()
        }

        dot2Bottom?.constant = 0
        dot3Bottom?.constant = constant

        UIView.animate(withDuration: duration, delay: duration * 2, options: [.curveEaseInOut]) {
            self.layoutIfNeeded()
        }

        dot3Bottom?.constant = 0

        UIView.animate(withDuration: duration, delay: duration * 3, options: [.curveEaseInOut]) {
            self.layoutIfNeeded()
        } completion: { (finished) in
            guard finished && self.isAnimating else { return }

            self.animateDots()
        }
    }
}
