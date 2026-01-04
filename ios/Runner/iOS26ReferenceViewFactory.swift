//
//  iOS26ReferenceViewFactory.swift
//  Platform View Factory для iOS26ReferenceViewController
//  Интеграция нативного экрана с Flutter
//

import Flutter
import UIKit

class iOS26ReferenceViewFactory: NSObject, FlutterPlatformViewFactory {
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
        return iOS26ReferenceView(
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

class iOS26ReferenceView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var viewController: iOS26ReferenceViewController

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        viewController = iOS26ReferenceViewController()

        super.init()

        // Setup method channel for communication
        let channel = FlutterMethodChannel(
            name: "ios26_reference_view_\(viewId)",
            binaryMessenger: messenger!
        )

        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        }

        // Embed view controller
        viewController.view.frame = frame
        _view.addSubview(viewController.view)
    }

    func view() -> UIView {
        return _view
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateData":
            // TODO: Update data if needed
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
