import UIKit

/// Search View Controller для iOS 26 TabView (третий таб с поиском)
/// Реализует Tab("Search", systemImage: "magnifyingglass", role: .search) из примера
class SearchViewController: UITableViewController {

    // MARK: - Properties

    private var searchController: UISearchController!
    private var searchResults: [[String: Any]] = []

    // Callback для передачи текста поиска во Flutter
    var onSearchTextChanged: ((String) -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Search"
        navigationController?.navigationBar.prefersLargeTitles = true

        setupSearchController()
        setupTableView()
    }

    // MARK: - Setup

    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search in all categories"

        // Делаем search bar всегда видимым (как в примере iOS 26)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        definesPresentationContext = true
    }

    private func setupTableView() {
        tableView.register(CategoryTableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
    }

    // MARK: - Public Methods

    func updateSearchResults(_ results: [[String: Any]]) {
        self.searchResults = results
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && !searchController.searchBar.text!.isEmpty {
            return searchResults.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! CategoryTableViewCell
        let item = searchResults[indexPath.row]

        cell.configure(
            title: item["title"] as? String ?? "",
            subtitle: item["subtitle"] as? String ?? "",
            icon: item["icon"] as? String ?? "",
            count: item["count"] as? Int ?? 0
        )

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: Обработка выбора результата поиска
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let tabVC = tabBarController as? IOSTabViewController {
            tabVC.handleScroll(scrollView)
        }
    }
}

// MARK: - UISearchResultsUpdating

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        onSearchTextChanged?(searchText)
    }
}
