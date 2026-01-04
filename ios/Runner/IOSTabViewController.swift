import UIKit
import Flutter

/// Главный контроллер для iOS 26 стиля TabView с Summary/Sharing табами
class IOSTabViewController: UITabBarController {

    // MARK: - Properties

    private var bottomAccessoryView: IOSBottomAccessoryView?
    private var searchButton: UIButton?
    private var isSearchExpanded = false
    private var searchBarController: UISearchController?

    // Callback для Flutter
    var onRescanTapped: (() -> Void)?
    var onSearchTextChanged: ((String) -> Void)?
    var onTabChanged: ((Int) -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabBar()
        setupViewControllers()
        setupBottomAccessory()
        setupSearchButton()

        delegate = self
    }

    // MARK: - Setup

    private func setupTabBar() {
        // iOS 26 стиль таб-бара
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // Полупрозрачный фон для glassmorphism
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        // Закругленные углы как в iOS 26
        tabBar.layer.cornerRadius = 16
        tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tabBar.layer.masksToBounds = true
    }

    private func setupViewControllers() {
        // Summary Tab
        let summaryVC = SummaryListViewController()
        let summaryNav = UINavigationController(rootViewController: summaryVC)
        summaryNav.tabBarItem = UITabBarItem(
            title: "Summary",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )

        // Sharing Tab
        let sharingVC = SharingViewController()
        let sharingNav = UINavigationController(rootViewController: sharingVC)
        sharingNav.tabBarItem = UITabBarItem(
            title: "Sharing",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )

        viewControllers = [summaryNav, sharingNav]
    }

    private func setupBottomAccessory() {
        guard let tabBar = tabBar as? UITabBar else { return }

        let accessory = IOSBottomAccessoryView()
        accessory.translatesAutoresizingMaskIntoConstraints = false
        accessory.onRescanTapped = { [weak self] in
            self?.onRescanTapped?()
        }

        view.addSubview(accessory)

        NSLayoutConstraint.activate([
            accessory.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            accessory.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            accessory.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
            accessory.heightAnchor.constraint(equalToConstant: 60)
        ])

        bottomAccessoryView = accessory
    }

    private func setupSearchButton() {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)

        tabBar.addSubview(button)

        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor, constant: -16),
            button.centerYAnchor.constraint(equalTo: tabBar.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])

        searchButton = button
    }

    // MARK: - Actions

    @objc private func searchButtonTapped() {
        toggleSearch()
    }

    private func toggleSearch() {
        isSearchExpanded.toggle()

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            if self.isSearchExpanded {
                self.expandSearch()
            } else {
                self.collapseSearch()
            }
        }
    }

    private func expandSearch() {
        // Показываем поисковую строку
        guard let navVC = selectedViewController as? UINavigationController,
              let topVC = navVC.topViewController else { return }

        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"

        topVC.navigationItem.searchController = searchController
        topVC.navigationItem.hidesSearchBarWhenScrolling = false

        searchBarController = searchController
        searchController.searchBar.becomeFirstResponder()
    }

    private func collapseSearch() {
        // Скрываем поисковую строку
        guard let navVC = selectedViewController as? UINavigationController,
              let topVC = navVC.topViewController else { return }

        topVC.navigationItem.searchController = nil
        searchBarController = nil
    }

    // MARK: - Scroll Handling

    func handleScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let threshold: CGFloat = 50

        UIView.animate(withDuration: 0.3) {
            if offsetY > threshold {
                // Скрываем таб-бар при скролле вниз
                self.tabBar.transform = CGAffineTransform(translationX: 0, y: self.tabBar.frame.height)
                self.bottomAccessoryView?.transform = CGAffineTransform(translationX: 0, y: self.tabBar.frame.height + 60)
            } else {
                // Показываем обратно
                self.tabBar.transform = .identity
                self.bottomAccessoryView?.transform = .identity
            }
        }
    }
}

// MARK: - UITabBarControllerDelegate

extension IOSTabViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        onTabChanged?(selectedIndex)
    }
}

// MARK: - UISearchResultsUpdating

extension IOSTabViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        onSearchTextChanged?(text)
    }
}
