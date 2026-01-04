import Flutter
import UIKit

/// Factory для создания нативного UISegmentedControl
class NativeSegmentedControlFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeSegmentedControlView(
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

/// Нативный UISegmentedControl для Flutter
class NativeSegmentedControlView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var segmentedControl: UISegmentedControl
    private var channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)
        _view.backgroundColor = .clear

        // Создаем UISegmentedControl с iOS 26 стилем
        segmentedControl = UISegmentedControl()

        // Парсим аргументы
        var items: [String] = ["Photos", "Videos"]
        var selectedIndex: Int = 0

        if let arguments = args as? [String: Any] {
            if let itemsArray = arguments["items"] as? [String] {
                items = itemsArray
            }
            if let index = arguments["selectedIndex"] as? Int {
                selectedIndex = index
            }
        }

        // Настраиваем сегменты
        for (index, item) in items.enumerated() {
            segmentedControl.insertSegment(withTitle: item, at: index, animated: false)
        }

        segmentedControl.selectedSegmentIndex = selectedIndex

        // Настраиваем внешний вид для iOS 26 стиля
        if #available(iOS 13.0, *) {
            // Используем новый стиль с glassmorphism эффектом
            segmentedControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.25)

            // Настраиваем фон
            segmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            segmentedControl.layer.cornerRadius = 14
            segmentedControl.layer.masksToBounds = true

            // Добавляем border для стеклянного эффекта
            segmentedControl.layer.borderWidth = 1.5
            segmentedControl.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor

            // Добавляем тень
            _view.layer.shadowColor = UIColor.black.cgColor
            _view.layer.shadowOffset = CGSize(width: 0, height: 8)
            _view.layer.shadowRadius = 20
            _view.layer.shadowOpacity = 0.3
            _view.layer.masksToBounds = false

            // Настраиваем текстовые атрибуты
            let normalAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.6),
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
            ]

            let selectedAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
            ]

            segmentedControl.setTitleTextAttributes(normalAttributes, for: .normal)
            segmentedControl.setTitleTextAttributes(selectedAttributes, for: .selected)
        }

        // Настраиваем layout
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            segmentedControl.topAnchor.constraint(equalTo: _view.topAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])

        // Создаем канал для коммуникации с Flutter
        channel = FlutterMethodChannel(
            name: "native_segmented_control_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        // Добавляем обработчик изменения сегмента
        segmentedControl.addTarget(
            self,
            action: #selector(segmentChanged),
            for: .valueChanged
        )

        // Настраиваем обработчик методов из Flutter
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "setSelectedIndex":
                if let index = call.arguments as? Int {
                    self.segmentedControl.selectedSegmentIndex = index
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid index", details: nil))
                }

            case "getSelectedIndex":
                result(self.segmentedControl.selectedSegmentIndex)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    @objc private func segmentChanged() {
        // Отправляем изменение во Flutter
        channel.invokeMethod("onSegmentChanged", arguments: segmentedControl.selectedSegmentIndex)
    }

    func view() -> UIView {
        return _view
    }
}
