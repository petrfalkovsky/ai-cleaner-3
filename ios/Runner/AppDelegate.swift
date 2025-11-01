import Flutter
import UIKit
import FBSDKCoreKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let CHANNEL_NAME = "ai_cleaner/media_metadata"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Настраиваем Method Channel для передачи метаданных медиафайлов
    let controller = window?.rootViewController as! FlutterViewController
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
}
