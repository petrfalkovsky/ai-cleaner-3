import Foundation
import Vision
import UIKit
import Flutter

/// Обработчик Vision Framework для анализа медиа-файлов
///
/// Этот класс предоставляет методы для анализа изображений с использованием
/// iOS Vision Framework. Работает как отдельный модуль, который можно включать/выключать.
class VisionFrameworkHandler {

    // MARK: - Availability Check

    /// Проверяет доступность Vision Framework на текущем устройстве
    static func isAvailable() -> Bool {
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }

    // MARK: - Blur Detection

    /// Анализирует изображение на предмет размытия
    ///
    /// - Parameters:
    ///   - imageData: данные изображения в формате JPEG/PNG
    ///   - completion: callback с результатом анализа
    ///
    /// Возвращает в completion:
    /// - blurScore: Double от 0.0 (четкое) до 1.0 (размытое)
    /// - quality: String описание качества
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

        // Создаем request для анализа качества изображения
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        // VNImageBasedRequest для анализа резкости/размытия
        let sharpnessRequest = VNDetectImageQualityRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let observations = request.results as? [VNObservation] else {
                completion(.failure(VisionError.noResults))
                return
            }

            // Вычисляем blur score на основе нескольких метрик
            let blurScore = calculateBlurScore(from: cgImage)

            // Определяем качество
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
                "quality": quality,
                "observationCount": observations.count
            ]

            completion(.success(result))
        }

        // Выполняем request
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([sharpnessRequest])
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Вычисляет blur score для изображения
    ///
    /// Использует Laplacian variance и edge detection для определения резкости
    private static func calculateBlurScore(from cgImage: CGImage) -> Double {
        // Конвертируем изображение в grayscale для анализа
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
            return 0.5 // Средний blur score при ошибке
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixelData = context.data else {
            return 0.5
        }

        let pixels = pixelData.bindMemory(to: UInt8.self, capacity: width * height)

        // Вычисляем Laplacian variance
        var variance: Double = 0.0
        var count = 0

        // Сканируем изображение с шагом для производительности
        let step = max(1, min(width, height) / 100) // Адаптивный шаг

        for y in stride(from: step, to: height - step, by: step) {
            for x in stride(from: step, to: width - step, by: step) {
                let index = y * width + x

                let center = Double(pixels[index])
                let top = Double(pixels[(y - step) * width + x])
                let bottom = Double(pixels[(y + step) * width + x])
                let left = Double(pixels[y * width + (x - step)])
                let right = Double(pixels[y * width + (x + step)])

                // Laplacian operator
                let laplacian = -4 * center + top + bottom + left + right
                variance += laplacian * laplacian
                count += 1
            }
        }

        let meanVariance = count > 0 ? variance / Double(count) : 0.0

        // Нормализуем variance к диапазону 0.0 - 1.0
        // Высокий variance = четкое изображение = низкий blur score
        // Низкий variance = размытое изображение = высокий blur score

        // Эмпирические пороги (основаны на тестировании)
        let sharpThreshold = 150.0  // Четкое изображение
        let blurryThreshold = 50.0  // Размытое изображение

        let blurScore: Double
        if meanVariance >= sharpThreshold {
            blurScore = 0.0 // Очень четкое
        } else if meanVariance <= blurryThreshold {
            blurScore = 1.0 // Очень размытое
        } else {
            // Интерполяция между порогами
            blurScore = 1.0 - ((meanVariance - blurryThreshold) / (sharpThreshold - blurryThreshold))
        }

        return max(0.0, min(1.0, blurScore))
    }

    // MARK: - Feature Print Generation (для будущего использования)

    /// Генерирует feature print для изображения
    ///
    /// Feature print используется для поиска похожих изображений
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

            // Конвертируем feature print в формат, который можно передать через Flutter
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

    /// Анализирует несколько изображений на предмет размытия (batch)
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

// MARK: - Error Types

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
