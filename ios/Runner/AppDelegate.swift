import Flutter
import UIKit
import FBSDKCoreKit
import Photos
import Vision

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

        // Настраиваем внешний вид для iOS стиля (соответствует HIG)
        if #available(iOS 13.0, *) {
            // Используем стиль с glassmorphism эффектом как в iOS Settings
            segmentedControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.25)

            // Настраиваем фон - полупрозрачный для эффекта стекла
            segmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            segmentedControl.layer.cornerRadius = 9 // Стандартный radius для UISegmentedControl
            segmentedControl.layer.masksToBounds = true

            // Добавляем тонкую border для стеклянного эффекта
            segmentedControl.layer.borderWidth = 1
            segmentedControl.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor

            // Добавляем легкую тень для объема
            _view.layer.shadowColor = UIColor.black.cgColor
            _view.layer.shadowOffset = CGSize(width: 0, height: 4)
            _view.layer.shadowRadius = 12
            _view.layer.shadowOpacity = 0.15
            _view.layer.masksToBounds = false

            // Настраиваем текстовые атрибуты по Apple HIG
            let normalAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.6),
                .font: UIFont.systemFont(ofSize: 13, weight: .medium) // iOS стандартный размер
            ]

            let selectedAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
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

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let CHANNEL_NAME = "ai_cleaner/media_metadata"
  private let DISK_SPACE_CHANNEL = "com.ai_cleaner.disk_space"
  private let VISION_CHANNEL = "ai_cleaner/vision"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController

    // Регистрируем нативный UISegmentedControl
    let segmentedControlFactory = NativeSegmentedControlFactory(messenger: controller.binaryMessenger)
    registrar(forPlugin: "NativeSegmentedControl")?.register(
      segmentedControlFactory,
      withId: "native_segmented_control"
    )

    // Регистрируем нативный iOS 26 TabView
    let tabViewFactory = IOSTabViewFactory(messenger: controller.binaryMessenger)
    registrar(forPlugin: "IOSTabView")?.register(
      tabViewFactory,
      withId: "ios_tab_view"
    )

    // Method Channel для открытия iOS 26 Reference Screen (полностью нативный модуль)
    let ios26ReferenceChannel = FlutterMethodChannel(
      name: "ios26_reference_channel",
      binaryMessenger: controller.binaryMessenger
    )

    ios26ReferenceChannel.setMethodCallHandler { [weak controller] (call, result) in
      guard let controller = controller else {
        result(FlutterError(code: "UNAVAILABLE", message: "Controller not available", details: nil))
        return
      }

      switch call.method {
      case "openNativeScreen":
        // Открываем нативный iOS 26 экран модально (UIKit версия)
        let nativeVC = iOS26ReferenceViewController()
        let navController = UINavigationController(rootViewController: nativeVC)
        navController.modalPresentationStyle = .fullScreen
        controller.present(navController, animated: true)
        result(nil)

      case "openOriginalSwiftUIScreen":
        // Открываем ОРИГИНАЛЬНЫЙ SwiftUI экран из iOS-26-by-Examples
        if #available(iOS 18.0, *) {
          let swiftUIView = NewTabView()
          let hostingController = UIHostingController(rootView: swiftUIView)
          let navController = UINavigationController(rootViewController: hostingController)
          navController.modalPresentationStyle = .fullScreen

          // Добавляем кнопку закрытия
          hostingController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: controller,
            action: #selector(FlutterViewController.dismissViewController)
          )

          controller.present(navController, animated: true)
          result(nil)
        } else {
          result(FlutterError(
            code: "UNSUPPORTED_VERSION",
            message: "NewTabView requires iOS 18.0 or later",
            details: nil
          ))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Настраиваем Method Channel для передачи метаданных медиафайлов
    let metadataChannel = FlutterMethodChannel(
      name: CHANNEL_NAME,
      binaryMessenger: controller.binaryMessenger
    )

    metadataChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
        return
      }

      switch call.method {
      case "getMediaMetadata":
        if let args = call.arguments as? [String: Any],
           let assetId = args["assetId"] as? String {
          self.getMediaMetadata(assetId: assetId, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Настраиваем Method Channel для получения информации о дисковом пространстве
    let diskSpaceChannel = FlutterMethodChannel(
      name: DISK_SPACE_CHANNEL,
      binaryMessenger: controller.binaryMessenger
    )

    diskSpaceChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
        return
      }

      switch call.method {
      case "getTotalDiskSpace":
        result(self.getTotalDiskSpace())
      case "getFreeDiskSpace":
        result(self.getFreeDiskSpace())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Настраиваем Method Channel для Vision Framework
    let visionChannel = FlutterMethodChannel(
      name: VISION_CHANNEL,
      binaryMessenger: controller.binaryMessenger
    )

    visionChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
        return
      }

      self.handleVisionMethod(call: call, result: result)
    }

    FBSDKCoreKit.ApplicationDelegate.shared.application(
        application,
        didFinishLaunchingWithOptions: launchOptions
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Получение метаданных для медиафайла
  private func getMediaMetadata(assetId: String, result: @escaping FlutterResult) {
    // Получаем PHAsset по localIdentifier
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)

    guard let asset = fetchResult.firstObject else {
      result(FlutterError(code: "ASSET_NOT_FOUND", message: "Asset not found", details: nil))
      return
    }

    // Собираем метаданные
    var metadata: [String: Any] = [:]

    // Определяем, является ли это записью экрана
    metadata["isScreenRecording"] = self.isScreenRecording(asset: asset)

    // Дополнительная информация
    metadata["mediaType"] = asset.mediaType == .video ? "video" : "image"
    metadata["duration"] = asset.duration
    metadata["pixelWidth"] = asset.pixelWidth
    metadata["pixelHeight"] = asset.pixelHeight

    // Получаем оригинальное имя файла
    let resources = PHAssetResource.assetResources(for: asset)
    if let resource = resources.first {
      metadata["originalFilename"] = resource.originalFilename
    }

    result(metadata)
  }

  // Определение записи экрана по имени файла
  private func isScreenRecording(asset: PHAsset) -> Bool {
    guard asset.mediaType == .video else { return false }

    let resources = PHAssetResource.assetResources(for: asset)
    guard let resource = resources.first else { return false }

    let filename = resource.originalFilename.lowercased()

    // iOS использует ReplayKit - все записи экрана имеют префикс "RPReplay"
    // Также проверяем другие возможные варианты
    if filename.hasPrefix("rpreplay") {
      return true
    }

    // Screen Recording - альтернативный вариант
    if filename.hasPrefix("screen recording") {
      return true
    }

    // ReplayKit в имени файла
    if filename.contains("replaykit") {
      return true
    }

    return false
  }

  // MARK: - Disk Space Methods

  /// Получить общий размер диска в GB (используя URLResourceValues для точности)
  private func getTotalDiskSpace() -> Double {
    do {
      let fileURL = URL(fileURLWithPath: NSHomeDirectory())
      let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey])

      if let totalCapacity = values.volumeTotalCapacity {
        let totalSpaceInGB = Double(totalCapacity) / (1024.0 * 1024.0 * 1024.0)
        return totalSpaceInGB
      }
    } catch {
      print("Error getting total disk space: \(error.localizedDescription)")
    }
    return 0.0
  }

  /// Получить свободное место на диске в GB (используя URLResourceValues для точности)
  private func getFreeDiskSpace() -> Double {
    do {
      let fileURL = URL(fileURLWithPath: NSHomeDirectory())
      let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])

      // Используем volumeAvailableCapacityForImportantUsageKey для более точного значения
      // Это значение показывает реальное доступное место (то же что в Settings)
      if let freeCapacity = values.volumeAvailableCapacityForImportantUsage {
        let freeSpaceInGB = Double(freeCapacity) / (1024.0 * 1024.0 * 1024.0)
        return freeSpaceInGB
      }
    } catch {
      print("Error getting free disk space: \(error.localizedDescription)")
    }
    return 0.0
  }

  // MARK: - Vision Framework Methods

  /// Обработка методов Vision Framework
  private func handleVisionMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Проверяем доступность Vision Framework
    guard #available(iOS 13.0, *) else {
      result(FlutterError(
        code: "UNSUPPORTED_PLATFORM",
        message: "Vision Framework requires iOS 13.0 or later",
        details: nil
      ))
      return
    }

    switch call.method {
    case "isAvailable":
      result(VisionFrameworkHandler.isAvailable())

    case "analyzeBlur":
      handleAnalyzeBlur(call: call, result: result)

    case "analyzeBlurBatch":
      handleAnalyzeBlurBatch(call: call, result: result)

    case "generateFeaturePrint":
      handleGenerateFeaturePrint(call: call, result: result)

    case "getVisionVersion":
      // Возвращаем версию iOS, так как Vision Framework идет вместе с iOS
      result("iOS \(UIDevice.current.systemVersion)")

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Обработка analyzeBlur метода
  @available(iOS 13.0, *)
  private func handleAnalyzeBlur(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let imageData = args["imageData"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }

    VisionFrameworkHandler.analyzeBlur(imageData: imageData.data) { analysisResult in
      switch analysisResult {
      case .success(let blurData):
        result(blurData)
      case .failure(let error):
        result(FlutterError(
          code: "VISION_ERROR",
          message: error.localizedDescription,
          details: nil
        ))
      }
    }
  }

  /// Обработка analyzeBlurBatch метода
  @available(iOS 13.0, *)
  private func handleAnalyzeBlurBatch(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let imageDataList = args["imageDataList"] as? [FlutterStandardTypedData] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }

    let dataList = imageDataList.map { $0.data }

    VisionFrameworkHandler.analyzeBlurBatch(imageDataList: dataList) { analysisResult in
      switch analysisResult {
      case .success(let blurDataList):
        result(blurDataList)
      case .failure(let error):
        result(FlutterError(
          code: "VISION_ERROR",
          message: error.localizedDescription,
          details: nil
        ))
      }
    }
  }

  /// Обработка generateFeaturePrint метода
  @available(iOS 13.0, *)
  private func handleGenerateFeaturePrint(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let imageData = args["imageData"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }

    VisionFrameworkHandler.generateFeaturePrint(imageData: imageData.data) { featureResult in
      switch featureResult {
      case .success(let featureData):
        result(featureData)
      case .failure(let error):
        result(FlutterError(
          code: "VISION_ERROR",
          message: error.localizedDescription,
          details: nil
        ))
      }
    }
  }
}

// MARK: - Vision Framework Handler

/// Обработчик Vision Framework для анализа медиа-файлов
class VisionFrameworkHandler {

    // MARK: - Availability Check

    static func isAvailable() -> Bool {
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }

    // MARK: - Blur Detection

    @available(iOS 13.0, *)
    static func analyzeBlur(
        imageData: Data,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            completion(.failure(VisionError.invalidImageData))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let blurScore = calculateBlurScore(from: cgImage)

            let quality: String
            if blurScore < 0.3 {
                quality = "sharp"
            } else if blurScore < 0.6 {
                quality = "moderate"
            } else {
                quality = "blurry"
            }

            let result: [String: Any] = [
                "blurScore": blurScore,
                "quality": quality
            ]

            completion(.success(result))
        }
    }

    private static func calculateBlurScore(from cgImage: CGImage) -> Double {
        let width = cgImage.width
        let height = cgImage.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return 0.5
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixelData = context.data else {
            return 0.5
        }

        let pixels = pixelData.bindMemory(to: UInt8.self, capacity: width * height)

        var variance: Double = 0.0
        var count = 0

        let step = max(1, min(width, height) / 100)

        for y in stride(from: step, to: height - step, by: step) {
            for x in stride(from: step, to: width - step, by: step) {
                let index = y * width + x

                let center = Double(pixels[index])
                let top = Double(pixels[(y - step) * width + x])
                let bottom = Double(pixels[(y + step) * width + x])
                let left = Double(pixels[y * width + (x - step)])
                let right = Double(pixels[y * width + (x + step)])

                let laplacian = -4 * center + top + bottom + left + right
                variance += laplacian * laplacian
                count += 1
            }
        }

        let meanVariance = count > 0 ? variance / Double(count) : 0.0

        let sharpThreshold = 150.0
        let blurryThreshold = 50.0

        let blurScore: Double
        if meanVariance >= sharpThreshold {
            blurScore = 0.0
        } else if meanVariance <= blurryThreshold {
            blurScore = 1.0
        } else {
            blurScore = 1.0 - ((meanVariance - blurryThreshold) / (sharpThreshold - blurryThreshold))
        }

        return max(0.0, min(1.0, blurScore))
    }

    // MARK: - Feature Print Generation

    @available(iOS 13.0, *)
    static func generateFeaturePrint(
        imageData: Data,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            completion(.failure(VisionError.invalidImageData))
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        let featurePrintRequest = VNGenerateImageFeaturePrintRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let observation = request.results?.first as? VNFeaturePrintObservation else {
                completion(.failure(VisionError.noResults))
                return
            }

            let featureData = observation.data

            let result: [String: Any] = [
                "featurePrintLength": observation.elementCount,
                "featurePrintType": String(describing: observation.elementType),
                "featureData": featureData
            ]

            completion(.success(result))
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([featurePrintRequest])
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Batch Processing

    @available(iOS 13.0, *)
    static func analyzeBlurBatch(
        imageDataList: [Data],
        completion: @escaping (Result<[[String: Any]], Error>) -> Void
    ) {
        var results: [[String: Any]] = []
        let dispatchGroup = DispatchGroup()
        var hasError: Error?

        for imageData in imageDataList {
            dispatchGroup.enter()

            analyzeBlur(imageData: imageData) { result in
                switch result {
                case .success(let blurResult):
                    results.append(blurResult)
                case .failure(let error):
                    hasError = error
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            if let error = hasError {
                completion(.failure(error))
            } else {
                completion(.success(results))
            }
        }
    }
}

// MARK: - Vision Error Types

enum VisionError: LocalizedError {
    case invalidImageData
    case noResults
    case unsupportedPlatform

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data provided"
        case .noResults:
            return "No results from Vision Framework"
        case .unsupportedPlatform:
            return "Vision Framework not available on this platform"
        }
    }
}

