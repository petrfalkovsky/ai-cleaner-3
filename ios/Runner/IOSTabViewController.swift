import UIKit
import Flutter

/// Главный контроллер для iOS 26 стиля с кастомным TabBar
/// Реализован по примеру iOS-26-by-Examples/NewTabView.swift с glassmorphism эффектом
class IOSTabViewController: UIViewController {

    // MARK: - Properties

    private var customTabBar: IOSCustomTabBar!
    private var bottomAccessoryView: IOSBottomAccessoryView?
    private var containerView: UIView!
    private var currentViewController: UIViewController?

    private var customTabBarBottomConstraint: NSLayoutConstraint!
    private var bottomAccessoryBottomConstraint: NSLayoutConstraint!

    // Callback для Flutter
    var onRescanTapped: (() -> Void)?
    var onSearchTextChanged: ((String) -> Void)?
    var onTabChanged: ((Int) -> Void)?
    var onCategoryTapped: ((String, String) -> Void)?

    // View controllers
    private var summaryVC: SummaryListViewController?
    private var sharingVC: SharingViewController?

    private var selectedIndex: Int = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupViewControllers()
        setupUI()
        showViewController(at: 0)
    }

    // MARK: - Setup

    private func setupViewControllers() {
        // Summary (Photos) View Controller
        let summaryViewController = SummaryListViewController()
        summaryViewController.onCategoryTapped = { [weak self] categoryName in
            self?.onCategoryTapped?("photo", categoryName)
        }
        self.summaryVC = summaryViewController

        // Sharing (Videos) View Controller
        let sharingViewController = SharingViewController()
        sharingViewController.onCategoryTapped = { [weak self] categoryName in
            self?.onCategoryTapped?("video", categoryName)
        }
        self.sharingVC = sharingViewController
    }

    private func setupUI() {
        // Container для view controllers
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Bottom Accessory (Rescan кнопка)
        let accessory = IOSBottomAccessoryView()
        accessory.translatesAutoresizingMaskIntoConstraints = false
        accessory.onRescanTapped = { [weak self] in
            self?.onRescanTapped?()
        }
        view.addSubview(accessory)
        bottomAccessoryView = accessory

        // Custom Tab Bar (2 кнопки + поиск)
        customTabBar = IOSCustomTabBar()
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        customTabBar.onTabChanged = { [weak self] index in
            self?.selectTab(at: index)
        }
        customTabBar.onSearchTapped = { [weak self] in
            self?.openSearch()
        }
        view.addSubview(customTabBar)

        // Constraints
        customTabBarBottomConstraint = customTabBar.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -8
        )
        bottomAccessoryBottomConstraint = accessory.bottomAnchor.constraint(
            equalTo: customTabBar.topAnchor,
            constant: -8
        )

        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: accessory.topAnchor),

            // Bottom Accessory
            accessory.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            accessory.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomAccessoryBottomConstraint,
            accessory.heightAnchor.constraint(equalToConstant: 60),

            // Custom Tab Bar
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBarBottomConstraint,
            customTabBar.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - Tab Switching

    private func selectTab(at index: Int) {
        guard index != selectedIndex else { return }

        selectedIndex = index
        showViewController(at: index)
        onTabChanged?(index)
    }

    private func showViewController(at index: Int) {
        // Удаляем текущий VC
        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()

        // Определяем новый VC
        let newVC: UIViewController
        if index == 0 {
            newVC = summaryVC ?? UIViewController()
        } else {
            newVC = sharingVC ?? UIViewController()
        }

        // Добавляем новый VC
        addChild(newVC)
        containerView.addSubview(newVC.view)
        newVC.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            newVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            newVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        newVC.didMove(toParent: self)
        currentViewController = newVC

        // Обновляем выбранный таб в UI
        customTabBar.selectedIndex = index
    }

    // MARK: - Search

    private func openSearch() {
        // TODO: Открыть поисковый экран
        // Можно создать SearchViewController и показать как modal или push
        onSearchTextChanged?("")
    }

    // MARK: - Public Methods

    func updatePhotoCategories(_ categories: [[String: Any]]) {
        summaryVC?.updateCategories(categories)
    }

    func updateVideoCategories(_ categories: [[String: Any]]) {
        sharingVC?.updateCategories(categories)
    }

    // MARK: - Scroll Handling
    // Реализация .tabBarMinimizeBehavior(.onScrollDown) из примера

    func handleScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let threshold: CGFloat = 50

        let shouldHide = offsetY > threshold

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0) {
            if shouldHide {
                // Скрываем табы и rescan при скролле вниз
                // Только кнопка поиска остается видимой
                self.customTabBar.setTabContainerHidden(true, animated: false)
                self.bottomAccessoryView?.alpha = 0
                self.bottomAccessoryView?.transform = CGAffineTransform(translationX: 0, y: 20)

                // Двигаем кнопку поиска вниз (где были табы)
                self.customTabBarBottomConstraint.constant = -8
                self.bottomAccessoryBottomConstraint.constant = -8
            } else {
                // Показываем все обратно
                self.customTabBar.setTabContainerHidden(false, animated: false)
                self.bottomAccessoryView?.alpha = 1
                self.bottomAccessoryView?.transform = .identity

                self.customTabBarBottomConstraint.constant = -8
                self.bottomAccessoryBottomConstraint.constant = -8
            }

            self.view.layoutIfNeeded()
        }
    }
}
