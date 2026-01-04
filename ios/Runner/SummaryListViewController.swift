import UIKit

/// Summary List View Controller для iOS 26 TabView
class SummaryListViewController: UITableViewController {

    private var items: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Summary"
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        // Генерируем данные для примера
        items = (1...100).map { "Row \($0)" }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Уведомляем TabViewController о скролле
        if let tabVC = tabBarController as? IOSTabViewController {
            tabVC.handleScroll(scrollView)
        }
    }
}
