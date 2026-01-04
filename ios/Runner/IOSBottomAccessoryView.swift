import UIKit

/// Bottom Accessory View с кнопкой Rescan (как в iOS 26 примере)
class IOSBottomAccessoryView: UIView {

    // MARK: - Properties

    var onRescanTapped: (() -> Void)?

    private lazy var rescanButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Rescan"
        config.image = UIImage(systemName: "arrow.clockwise")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.cornerStyle = .medium
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(rescanTapped), for: .touchUpInside)

        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemBackground.withAlphaComponent(0.95)

        // Добавляем separator сверху
        let separator = UIView()
        separator.backgroundColor = .separator.withAlphaComponent(0.3)
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        addSubview(rescanButton)

        NSLayoutConstraint.activate([
            // Separator
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            // Button
            rescanButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            rescanButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            rescanButton.heightAnchor.constraint(equalToConstant: 44),
            rescanButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }

    // MARK: - Actions

    @objc private func rescanTapped() {
        // Добавляем анимацию нажатия
        UIView.animate(withDuration: 0.1, animations: {
            self.rescanButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.rescanButton.transform = .identity
            }
        }

        onRescanTapped?()
    }
}
