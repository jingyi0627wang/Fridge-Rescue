import UIKit

// MARK: - Food photos
// Optional photo for a fridge food (e.g. homemade leftovers or anything we
// don't have a drawing for). Saved as a small JPEG in Documents/FoodPhotos;
// FoodItem only keeps the file name.

enum FoodPhotoStore {

    /// Documents/FoodPhotos (created once).
    private static let folder: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("FoodPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()

    /// Decoded photos, so lists don't re-read files on every redraw.
    private static let cache = NSCache<NSString, UIImage>()

    static func url(for fileName: String) -> URL {
        folder.appendingPathComponent(fileName)
    }

    static func image(named fileName: String) -> UIImage? {
        if let cached = cache.object(forKey: fileName as NSString) { return cached }
        guard let image = UIImage(contentsOfFile: url(for: fileName).path) else { return nil }
        cache.setObject(image, forKey: fileName as NSString)
        return image
    }

    /// Crops to a square, shrinks to 600 px and saves as JPEG. Returns the file name.
    static func save(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let side = min(image.size.width, image.size.height)
        guard side > 0 else { return nil }
        let target: CGFloat = min(600, side)
        let scale = target / side
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(x: (target - drawSize.width) / 2, y: (target - drawSize.height) / 2)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let square = UIGraphicsImageRenderer(size: CGSize(width: target, height: target), format: format).image { _ in
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
        guard let jpeg = square.jpegData(compressionQuality: 0.8) else { return nil }

        let name = "\(UUID().uuidString).jpg"
        do {
            try jpeg.write(to: url(for: name))
            cache.setObject(square, forKey: name as NSString)
            return name
        } catch {
            return nil
        }
    }

    static func delete(_ fileName: String?) {
        guard let fileName else { return }
        cache.removeObject(forKey: fileName as NSString)
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}
