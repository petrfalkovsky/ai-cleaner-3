//
//  iOS26ReferenceViewController.swift
//  Точная копия NewTabView.swift из iOS-26-by-Examples
//  Реализует нативный iOS 26 дизайн с glassmorphism и анимациями
//

import UIKit

/// Главный экран - точная копия NewTabView из iOS-26-by-Examples
class iOS26ReferenceViewController: UIViewController {

    // MARK: - Properties

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Список с закругленным контейнером
    private let listContainerView = UIView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // Tab Bar (Summary, Sharing, Search)
    private var tabBar: iOS26TabBar!

    // Bottom Accessory
    private var bottomAccessory: iOS26BottomAccessory!

    // Search
    private var searchBar: UISearchBar?
    private var isSearchExpanded = false

    private var selectedTabIndex = 0

    // Constraints
    private var tabBarBottomConstraint: NSLayoutConstraint!
    private var bottomAccessoryBottomConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "iOS 26 Reference"

        // Кнопка закрытия
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.leftBarButtonItem = closeButton
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // ScrollView для прокрутки всех элементов
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // List Container с закругленными краями
        setupListContainer()

        // Tab Bar
        tabBar = iOS26TabBar()
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.onTabChanged = { [weak self] index in
            self?.handleTabChange(index)
        }
        tabBar.onSearchTapped = { [weak self] in
            self?.toggleSearch()
        }
        view.addSubview(tabBar)

        // Bottom Accessory
        bottomAccessory = iOS26BottomAccessory()
        bottomAccessory.translatesAutoresizingMaskIntoConstraints = false
        bottomAccessory.onRescanTapped = { [weak self] in
            self?.handleRescan()
        }
        view.addSubview(bottomAccessory)

        // Table View
        setupTableView()
    }

    private func setupListContainer() {
        listContainerView.translatesAutoresizingMaskIntoConstraints = false
        listContainerView.backgroundColor = .systemBackground
        listContainerView.layer.cornerRadius = 16
        listContainerView.layer.cornerCurve = .continuous
        listContainerView.clipsToBounds = true

        // В темной теме - более светлый, в светлой - более темный
        if traitCollection.userInterfaceStyle == .dark {
            listContainerView.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.3)
        } else {
            listContainerView.backgroundColor = UIColor.systemGray5
        }

        contentView.addSubview(listContainerView)
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.isScrollEnabled = false // Скролл через главный ScrollView

        // В темной теме - более светлые separators
        if traitCollection.userInterfaceStyle == .dark {
            tableView.separatorColor = UIColor.white.withAlphaComponent(0.15)
        } else {
            tableView.separatorColor = UIColor.black.withAlphaComponent(0.1)
        }

        listContainerView.addSubview(tableView)
    }

    private func setupConstraints() {
        tabBarBottomConstraint = tabBar.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -8
        )

        bottomAccessoryBottomConstraint = bottomAccessory.bottomAnchor.constraint(
            equalTo: tabBar.topAnchor,
            constant: -12
        )

        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAccessory.topAnchor, constant: -8),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // List Container
            listContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            listContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            listContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            listContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            // TableView
            tableView.topAnchor.constraint(equalTo: listContainerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: listContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: listContainerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: listContainerView.bottomAnchor),
            tableView.heightAnchor.constraint(equalToConstant: CGFloat(100 * 44)), // 100 rows

            // Bottom Accessory
            bottomAccessory.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomAccessory.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomAccessoryBottomConstraint,
            bottomAccessory.heightAnchor.constraint(equalToConstant: 50),

            // Tab Bar
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tabBarBottomConstraint,
            tabBar.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }

    private func handleTabChange(_ index: Int) {
        selectedTabIndex = index
        // TODO: Переключение контента между Summary и Sharing
        print("Selected tab: \(index)")
    }

    private func toggleSearch() {
        isSearchExpanded.toggle()

        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            if self.isSearchExpanded {
                // Разворачиваем поиск, сворачиваем табы до иконок
                self.tabBar.expandSearch()
            } else {
                // Сворачиваем поиск, разворачиваем табы
                self.tabBar.collapseSearch()
            }
            self.view.layoutIfNeeded()
        }
    }

    private func handleRescan() {
        print("Rescan tapped")
        // TODO: Запуск сканирования
    }
}

// MARK: - UIScrollViewDelegate

extension iOS26ReferenceViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // При прокрутке вниз - скрываем Bottom Accessory и табы
        let offsetY = scrollView.contentOffset.y
        let shouldHide = offsetY > 50

        UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState]) {
            if shouldHide {
                self.bottomAccessory.alpha = 0
                self.tabBar.minimizeForScroll()
            } else {
                self.bottomAccessory.alpha = 1
                self.tabBar.restoreFromScroll()
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension iOS26ReferenceViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row + 1)"
        cell.backgroundColor = .clear

        // В темной теме - более светлый фон ячеек
        if traitCollection.userInterfaceStyle == .dark {
            cell.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        } else {
            cell.contentView.backgroundColor = .clear
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
