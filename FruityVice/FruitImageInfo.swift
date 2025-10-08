import UIKit

struct FruitImageInfo: Codable {
    let imageData: Data
    let date: Date

    var image: UIImage? {
        UIImage(data: imageData)
    }

    init(image: UIImage, date: Date) {
        self.imageData = image.jpegData(compressionQuality: 0.9) ?? Data()
        self.date = date
    }
}
