import UIKit

/// Sharing View Controller для iOS 26 TabView
class SharingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Sharing"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Sharing"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
