//
//  iOS26TabBar.swift
//  Нативный iOS 26 Tab Bar с glassmorphism и анимациями
//  Summary, Sharing, Search
//

import UIKit

class iOS26TabBar: UIView {

    // MARK: - Callbacks

    var onTabChanged: ((Int) -> Void)?
    var onSearchTapped: (() -> Void)?

    // MARK: - Properties

    private let tabsContainer = UIView()
    private let summaryButton = UIButton(type: .system)
    private let sharingButton = UIButton(type: .system)
    private let searchButton = UIButton(type: .system)
    private let searchTextField = UITextField()

    private var isSearchExpanded = false
    var selectedIndex = 0 {
        didSet {
            updateSelection()
        }
    }

    // Constraints для анимаций
    private var tabsContainerWidthConstraint: NSLayoutConstraint!
    private var searchButtonWidthConstraint: NSLayoutConstraint!
    private var searchTextFieldLeadingConstraint: NSLayoutConstraint!

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
        // Container для табов (Summary, Sharing)
        setupTabsContainer()

        // Search button (отдельно справа)
        setupSearchButton()

        // Search TextField (скрыт по умолчанию)
        setupSearchTextField()

        setupConstraints()
        updateSelection()
    }

    private func setupTabsContainer() {
        tabsContainer.translatesAutoresizingMaskIntoConstraints = false

        // Glassmorphism
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 18
        blurView.layer.cornerCurve = .continuous
        blurView.clipsToBounds = true
        tabsContainer.addSubview(blurView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: tabsContainer.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: tabsContainer.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: tabsContainer.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: tabsContainer.bottomAnchor)
        ])

        // Background
        tabsContainer.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        tabsContainer.layer.cornerRadius = 18
        tabsContainer.layer.cornerCurve = .continuous
        tabsContainer.layer.borderWidth = 0.5
        tabsContainer.layer.borderColor = UIColor.label.withAlphaComponent(0.1).cgColor

        addSubview(tabsContainer)

        // Summary Button
        summaryButton.translatesAutoresizingMaskIntoConstraints = false
        summaryButton.setImage(UIImage(systemName: "heart"), for: .normal)
        summaryButton.setTitle("Summary", for: .normal)
        summaryButton.tintColor = .label
        summaryButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        summaryButton.addTarget(self, action: #selector(summaryTapped), for: .touchUpInside)
        tabsContainer.addSubview(summaryButton)

        // Sharing Button
        sharingButton.translatesAutoresizingMaskIntoConstraints = false
        sharingButton.setImage(UIImage(systemName: "person.2.fill"), for: .normal)
        sharingButton.setTitle("Sharing", for: .normal)
        sharingButton.tintColor = .label
        sharingButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        sharingButton.addTarget(self, action: #selector(sharingTapped), for: .touchUpInside)
        tabsContainer.addSubview(sharingButton)

        // Layout buttons horizontally
        NSLayoutConstraint.activate([
            summaryButton.leadingAnchor.constraint(equalTo: tabsContainer.leadingAnchor, constant: 12),
            summaryButton.centerYAnchor.constraint(equalTo: tabsContainer.centerYAnchor),
            summaryButton.heightAnchor.constraint(equalToConstant: 36),

            sharingButton.leadingAnchor.constraint(equalTo: summaryButton.trailingAnchor, constant: 8),
            sharingButton.trailingAnchor.constraint(equalTo: tabsContainer.trailingAnchor, constant: -12),
            sharingButton.centerYAnchor.constraint(equalTo: tabsContainer.centerYAnchor),
            sharingButton.heightAnchor.constraint(equalToConstant: 36),
            sharingButton.widthAnchor.constraint(equalTo: summaryButton.widthAnchor)
        ])
    }

    private func setupSearchButton() {
        searchButton.translatesAutoresizingMaskIntoConstraints = false

        // Glassmorphism
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 22
        blurView.layer.cornerCurve = .continuous
        blurView.clipsToBounds = true
        blurView.isUserInteractionEnabled = false
        searchButton.insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: searchButton.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: searchButton.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: searchButton.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: searchButton.bottomAnchor)
        ])

        searchButton.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        searchButton.layer.cornerRadius = 22
        searchButton.layer.cornerCurve = .continuous
        searchButton.layer.borderWidth = 0.5
        searchButton.layer.borderColor = UIColor.label.withAlphaComponent(0.1).cgColor

        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.tintColor = .label
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)

        addSubview(searchButton)
    }

    private func setupSearchTextField() {
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.placeholder = "Search"
        searchTextField.borderStyle = .none
        searchTextField.backgroundColor = .clear
        searchTextField.alpha = 0
        searchTextField.font = .systemFont(ofSize: 15)

        addSubview(searchTextField)
    }

    private func setupConstraints() {
        tabsContainerWidthConstraint = tabsContainer.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.65)
        searchButtonWidthConstraint = searchButton.widthAnchor.constraint(equalToConstant: 44)

        NSLayoutConstraint.activate([
            // Tabs Container
            tabsContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabsContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            tabsContainer.heightAnchor.constraint(equalToConstant: 44),
            tabsContainerWidthConstraint,

            // Search Button
            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchButton.heightAnchor.constraint(equalToConstant: 44),
            searchButtonWidthConstraint,

            // Search TextField
            searchTextField.leadingAnchor.constraint(equalTo: tabsContainer.trailingAnchor, constant: 8),
            searchTextField.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -8),
            searchTextField.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Actions

    @objc private func summaryTapped() {
        selectedIndex = 0
        onTabChanged?(0)
    }

    @objc private func sharingTapped() {
        selectedIndex = 1
        onTabChanged?(1)
    }

    @objc private func searchTapped() {
        onSearchTapped?()
    }

    // MARK: - Public Methods

    func expandSearch() {
        isSearchExpanded = true

        // Сворачиваем табы до одной иконки (текущий выбранный таб)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            // Убираем текст, оставляем только иконку
            self.summaryButton.setTitle("", for: .normal)
            self.sharingButton.setTitle("", for: .normal)

            // Сжимаем контейнер табов
            self.tabsContainerWidthConstraint.constant = -self.bounds.width * 0.55
            self.tabsContainerWidthConstraint.isActive = false
            self.tabsContainerWidthConstraint = self.tabsContainer.widthAnchor.constraint(equalToConstant: 56)
            self.tabsContainerWidthConstraint.isActive = true

            // Показываем поле поиска
            self.searchTextField.alpha = 1

            // Кнопка поиска остается на месте
            self.layoutIfNeeded()
        }
    }

    func collapseSearch() {
        isSearchExpanded = false

        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            // Возвращаем текст
            self.summaryButton.setTitle("Summary", for: .normal)
            self.sharingButton.setTitle("Sharing", for: .normal)

            // Расширяем контейнер табов
            self.tabsContainerWidthConstraint.isActive = false
            self.tabsContainerWidthConstraint = self.tabsContainer.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.65)
            self.tabsContainerWidthConstraint.isActive = true

            // Скрываем поле поиска
            self.searchTextField.alpha = 0

            self.layoutIfNeeded()
        }
    }

    func minimizeForScroll() {
        // При скролле вниз - скрываем табы, оставляем только поиск
        UIView.animate(withDuration: 0.25) {
            self.tabsContainer.alpha = 0
            self.tabsContainer.transform = CGAffineTransform(translationX: 0, y: 10)
        }
    }

    func restoreFromScroll() {
        // При скролле вверх - возвращаем табы
        UIView.animate(withDuration: 0.25) {
            self.tabsContainer.alpha = 1
            self.tabsContainer.transform = .identity
        }
    }

    // MARK: - Private Methods

    private func updateSelection() {
        // Обновляем визуальное состояние кнопок
        summaryButton.alpha = selectedIndex == 0 ? 1.0 : 0.6
        sharingButton.alpha = selectedIndex == 1 ? 1.0 : 0.6

        // Скрываем неактивный таб при развернутом поиске
        if isSearchExpanded {
            summaryButton.alpha = selectedIndex == 0 ? 1.0 : 0.0
            sharingButton.alpha = selectedIndex == 1 ? 1.0 : 0.0
        }
    }
}
