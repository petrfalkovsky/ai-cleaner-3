import UIKit

/// Sharing View Controller для iOS 26 TabView (Videos категории)
class SharingViewController: UITableViewController {

    // MARK: - Properties

    private var categories: [[String: Any]] = []

    // Callback для открытия категории
    var onCategoryTapped: ((String) -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Videos"
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView.register(CategoryTableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
    }

    // MARK: - Public Methods

    func updateCategories(_ categories: [[String: Any]]) {
        self.categories = categories
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! CategoryTableViewCell
        let category = categories[indexPath.row]

        cell.configure(
            title: category["title"] as? String ?? "",
            subtitle: category["subtitle"] as? String ?? "",
            icon: category["icon"] as? String ?? "",
            count: category["count"] as? Int ?? 0
        )

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let category = categories[indexPath.row]
        if let categoryName = category["name"] as? String {
            onCategoryTapped?(categoryName)
        }
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let tabVC = tabBarController as? IOSTabViewController {
            tabVC.handleScroll(scrollView)
        }
    }
}
