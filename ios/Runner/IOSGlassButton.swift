import UIKit

/// Кнопка со стеклянным эффектом (glassmorphism) как в iOS 26
/// Используется для иконки настроек и других UI элементов
class IOSGlassButton: UIButton {

    // MARK: - Properties

    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let iconSize: CGFloat

    // MARK: - Initialization

    init(systemImage: String, iconSize: CGFloat = 20) {
        self.iconSize = iconSize
        super.init(frame: .zero)

        setupUI(systemImage: systemImage)
    }

    required init?(coder: NSCoder) {
        self.iconSize = 20
        super.init(coder: coder)
        setupUI(systemImage: "gear")
    }

    // MARK: - Setup

    private func setupUI(systemImage: String) {
        // Стеклянный фон
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        layer.cornerRadius = 20
        layer.masksToBounds = true

        // Добавляем blur эффект
        insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Иконка
        let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)
        setImage(UIImage(systemName: systemImage, withConfiguration: config), for: .normal)
        tintColor = .label

        // Hover эффект для интерактивности
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    // MARK: - Touch Effects

    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.alpha = 0.8
        }
    }

    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }

    // MARK: - Public Methods

    /// Обновить иконку
    func setSystemImage(_ systemImage: String) {
        let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)
        setImage(UIImage(systemName: systemImage, withConfiguration: config), for: .normal)
    }
}
