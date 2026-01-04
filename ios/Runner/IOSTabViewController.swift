import UIKit
import Flutter

/// Главный контроллер для iOS 26 стиля TabView с Photos/Videos/Search табами
/// Реализован по примеру iOS-26-by-Examples/NewTabView.swift
class IOSTabViewController: UITabBarController {

    // MARK: - Properties

    private var bottomAccessoryView: IOSBottomAccessoryView?

    // Callback для Flutter
    var onRescanTapped: (() -> Void)?
    var onSearchTextChanged: ((String) -> Void)?
    var onTabChanged: ((Int) -> Void)?
    var onCategoryTapped: ((String, String) -> Void)?  // (tabType, categoryName)

    // View controllers
    private var summaryVC: SummaryListViewController?
    private var sharingVC: SharingViewController?
    private var searchVC: SearchViewController?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabBar()
        setupViewControllers()
        setupBottomAccessory()

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
        // Summary Tab (Photos) - аналог Summary из примера
        let summaryViewController = SummaryListViewController()
        summaryViewController.onCategoryTapped = { [weak self] categoryName in
            self?.onCategoryTapped?("photo", categoryName)
        }
        self.summaryVC = summaryViewController

        let summaryNav = UINavigationController(rootViewController: summaryViewController)
        summaryNav.tabBarItem = UITabBarItem(
            title: "Photos",
            image: UIImage(systemName: "photo.stack"),
            selectedImage: UIImage(systemName: "photo.stack.fill")
        )

        // Sharing Tab (Videos) - аналог Sharing из примера
        let sharingViewController = SharingViewController()
        sharingViewController.onCategoryTapped = { [weak self] categoryName in
            self?.onCategoryTapped?("video", categoryName)
        }
        self.sharingVC = sharingViewController

        let sharingNav = UINavigationController(rootViewController: sharingViewController)
        sharingNav.tabBarItem = UITabBarItem(
            title: "Videos",
            image: UIImage(systemName: "video.stack"),
            selectedImage: UIImage(systemName: "video.stack.fill")
        )

        // Search Tab - аналог Search из примера с role: .search
        let searchViewController = SearchViewController()
        searchViewController.onSearchTextChanged = { [weak self] text in
            self?.onSearchTextChanged?(text)
        }
        self.searchVC = searchViewController

        let searchNav = UINavigationController(rootViewController: searchViewController)
        searchNav.tabBarItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )

        viewControllers = [summaryNav, sharingNav, searchNav]
    }

    // MARK: - Public Methods

    func updatePhotoCategories(_ categories: [[String: Any]]) {
        summaryVC?.updateCategories(categories)
    }

    func updateVideoCategories(_ categories: [[String: Any]]) {
        sharingVC?.updateCategories(categories)
    }

    func updateSearchResults(_ results: [[String: Any]]) {
        searchVC?.updateSearchResults(results)
    }

    private func setupBottomAccessory() {
        // Bottom Accessory - аналог .tabViewBottomAccessory из примера
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

    // MARK: - Scroll Handling
    // Реализация .tabBarMinimizeBehavior(.onScrollDown) из примера

    func handleScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let threshold: CGFloat = 50

        UIView.animate(withDuration: 0.3) {
            if offsetY > threshold {
                // Скрываем таб-бар при скролле вниз (.onScrollDown)
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
