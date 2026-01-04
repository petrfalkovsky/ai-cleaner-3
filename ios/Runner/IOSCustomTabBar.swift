import UIKit

/// Кастомный TabBar в стиле iOS 26 - 2 кнопки рядом + кнопка поиска
/// Реализует дизайн из iOS-26-by-Examples с glassmorphism эффектом
class IOSCustomTabBar: UIView {

    // MARK: - Properties

    private let tabContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true

        // Glassmorphism эффект
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)

        // Добавляем blur
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 20
        blurView.layer.masksToBounds = true
        view.insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }()

    private let photosButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Photos", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = 0
        return button
    }()

    private let videosButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Videos", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = 1
        return button
    }()

    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: config), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .label

        // Круглый контейнер для кнопки поиска
        button.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)
        button.layer.cornerRadius = 22
        button.layer.masksToBounds = true

        // Добавляем blur для стеклянного эффекта
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.isUserInteractionEnabled = false
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 22
        blurView.layer.masksToBounds = true
        button.insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: button.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])

        return button
    }()

    private let selectionIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.label.withAlphaComponent(0.1)
        view.layer.cornerRadius = 16
        return view
    }()

    var selectedIndex: Int = 0 {
        didSet {
            updateSelectedTab(animated: true)
        }
    }

    var onTabChanged: ((Int) -> Void)?
    var onSearchTapped: (() -> Void)?

    private var indicatorLeadingConstraint: NSLayoutConstraint?

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
        backgroundColor = .clear

        // Добавляем контейнер для табов
        addSubview(tabContainer)
        tabContainer.addSubview(selectionIndicator)
        tabContainer.addSubview(photosButton)
        tabContainer.addSubview(videosButton)

        // Добавляем кнопку поиска
        addSubview(searchButton)

        // Actions
        photosButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        videosButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)

        setupConstraints()
        updateSelectedTab(animated: false)
    }

    private func setupConstraints() {
        indicatorLeadingConstraint = selectionIndicator.leadingAnchor.constraint(equalTo: photosButton.leadingAnchor, constant: -4)

        NSLayoutConstraint.activate([
            // Tab container - слева
            tabContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tabContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            tabContainer.heightAnchor.constraint(equalToConstant: 44),

            // Selection indicator
            indicatorLeadingConstraint!,
            selectionIndicator.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            selectionIndicator.widthAnchor.constraint(equalTo: photosButton.widthAnchor, constant: 8),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 36),

            // Photos button
            photosButton.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor, constant: 4),
            photosButton.topAnchor.constraint(equalTo: tabContainer.topAnchor, constant: 4),
            photosButton.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: -4),
            photosButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            // Videos button
            videosButton.leadingAnchor.constraint(equalTo: photosButton.trailingAnchor, constant: 8),
            videosButton.topAnchor.constraint(equalTo: tabContainer.topAnchor, constant: 4),
            videosButton.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: -4),
            videosButton.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor, constant: -4),
            videosButton.widthAnchor.constraint(equalTo: photosButton.widthAnchor),

            // Search button - справа в круглом контейнере
            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            searchButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 44),
            searchButton.heightAnchor.constraint(equalToConstant: 44),

            // Расстояние между контейнером табов и кнопкой поиска
            searchButton.leadingAnchor.constraint(greaterThanOrEqualTo: tabContainer.trailingAnchor, constant: 12)
        ])
    }

    // MARK: - Actions

    @objc private func tabTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        onTabChanged?(selectedIndex)
    }

    @objc private func searchTapped() {
        onSearchTapped?()
    }

    private func updateSelectedTab(animated: Bool) {
        let targetButton = selectedIndex == 0 ? photosButton : videosButton

        let updateColors = {
            self.photosButton.setTitleColor(
                self.selectedIndex == 0 ? .label : .secondaryLabel,
                for: .normal
            )
            self.videosButton.setTitleColor(
                self.selectedIndex == 1 ? .label : .secondaryLabel,
                for: .normal
            )
        }

        if animated {
            indicatorLeadingConstraint?.isActive = false
            indicatorLeadingConstraint = selectionIndicator.leadingAnchor.constraint(
                equalTo: targetButton.leadingAnchor,
                constant: -4
            )
            indicatorLeadingConstraint?.isActive = true

            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
                self.layoutIfNeeded()
                updateColors()
            }
        } else {
            indicatorLeadingConstraint?.isActive = false
            indicatorLeadingConstraint = selectionIndicator.leadingAnchor.constraint(
                equalTo: targetButton.leadingAnchor,
                constant: -4
            )
            indicatorLeadingConstraint?.isActive = true
            updateColors()
        }
    }

    // MARK: - Public Methods

    /// Скрыть/показать контейнер табов (при скролле)
    func setTabContainerHidden(_ hidden: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.tabContainer.alpha = hidden ? 0 : 1
                self.tabContainer.transform = hidden ? CGAffineTransform(scaleX: 0.8, y: 0.8) : .identity
            }
        } else {
            self.tabContainer.alpha = hidden ? 0 : 1
            self.tabContainer.transform = hidden ? CGAffineTransform(scaleX: 0.8, y: 0.8) : .identity
        }
    }
}
