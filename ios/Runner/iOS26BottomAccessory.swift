//
//  iOS26BottomAccessory.swift
//  Bottom Accessory с glassmorphism (Rescan button)
//  Растянута на всю ширину экрана
//

import UIKit

class iOS26BottomAccessory: UIView {

    // MARK: - Callbacks

    var onRescanTapped: (() -> Void)?

    // MARK: - Properties

    private let rescanButton = UIButton(type: .system)
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        // Glassmorphism background
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 16
        blurView.layer.cornerCurve = .continuous
        blurView.clipsToBounds = true
        addSubview(blurView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Background
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.label.withAlphaComponent(0.1).cgColor

        // Icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: "arrow.clockwise")
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        addSubview(iconImageView)

        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Rescan"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .systemBlue
        titleLabel.textAlignment = .left
        addSubview(titleLabel)

        // Button (full width)
        rescanButton.translatesAutoresizingMaskIntoConstraints = false
        rescanButton.backgroundColor = .clear
        rescanButton.addTarget(self, action: #selector(rescanTapped), for: .touchUpInside)
        addSubview(rescanButton)

        // Constraints
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            rescanButton.topAnchor.constraint(equalTo: topAnchor),
            rescanButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            rescanButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            rescanButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func rescanTapped() {
        // Анимация нажатия
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }

        onRescanTapped?()
    }
}
