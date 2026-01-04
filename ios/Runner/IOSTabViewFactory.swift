import Flutter
import UIKit

/// Factory для создания нативного iOS 26 TabView
class IOSTabViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return IOSTabViewWrapper(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Wrapper для интеграции IOSTabViewController с Flutter
class IOSTabViewWrapper: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var tabViewController: IOSTabViewController
    private var channel: FlutterMethodChannel
    private var parentViewController: UIViewController?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)
        _view.backgroundColor = .systemBackground

        tabViewController = IOSTabViewController()

        // Создаем канал для коммуникации с Flutter
        channel = FlutterMethodChannel(
            name: "ios_tab_view_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        setupCallbacks()
        setupMethodChannel()
        embedViewController()
    }

    private func setupCallbacks() {
        // Callback для кнопки Rescan
        tabViewController.onRescanTapped = { [weak self] in
            self?.channel.invokeMethod("onRescanTapped", arguments: nil)
        }

        // Callback для поиска
        tabViewController.onSearchTextChanged = { [weak self] text in
            self?.channel.invokeMethod("onSearchTextChanged", arguments: text)
        }

        // Callback для смены таба
        tabViewController.onTabChanged = { [weak self] index in
            self?.channel.invokeMethod("onTabChanged", arguments: index)
        }

        // Callback для открытия категории
        tabViewController.onCategoryTapped = { [weak self] tabType, categoryName in
            self?.channel.invokeMethod("onCategoryTapped", arguments: [
                "tabType": tabType,
                "categoryName": categoryName
            ])
        }
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "setSelectedTab":
                if let index = call.arguments as? Int {
                    self.tabViewController.selectTab(at: index)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid tab index", details: nil))
                }

            case "handleScroll":
                if let args = call.arguments as? [String: Any],
                   let offsetY = args["offsetY"] as? Double {
                    // Создаем fake scroll view для передачи offset
                    let scrollView = UIScrollView()
                    scrollView.contentOffset = CGPoint(x: 0, y: offsetY)
                    self.tabViewController.handleScroll(scrollView)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid scroll offset", details: nil))
                }

            case "updatePhotoCategories":
                if let categories = call.arguments as? [[String: Any]] {
                    self.tabViewController.updatePhotoCategories(categories)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid categories", details: nil))
                }

            case "updateVideoCategories":
                if let categories = call.arguments as? [[String: Any]] {
                    self.tabViewController.updateVideoCategories(categories)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid categories", details: nil))
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func embedViewController() {
        // Находим родительский ViewController
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            parentViewController = rootVC

            // Добавляем tab controller как child
            rootVC.addChild(tabViewController)
            _view.addSubview(tabViewController.view)

            tabViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tabViewController.view.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                tabViewController.view.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                tabViewController.view.topAnchor.constraint(equalTo: _view.topAnchor),
                tabViewController.view.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])

            tabViewController.didMove(toParent: rootVC)
        }
    }

    func view() -> UIView {
        return _view
    }

    deinit {
        tabViewController.willMove(toParent: nil)
        tabViewController.view.removeFromSuperview()
        tabViewController.removeFromParent()
    }
}
