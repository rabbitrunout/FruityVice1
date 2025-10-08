import SwiftUI
import UIKit

struct ContentView: View {
    @State private var fruits: [Fruit] = []
    @State private var selectedFruit: Fruit? = nil
    @State private var fruitImages: [String: FruitImageInfo] = [:]
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationView {
            List(fruits) { fruit in
                Button(action: { selectedFruit = fruit }) {
                    HStack {
                        Text(fruit.name)
                        Spacer()
                        if let image = fruitImages[fruit.name]?.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .navigationTitle("Fruits")
            .task { await loadFruits() }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save PDF Report") {
                        savePDFReport()
                    }
                }
            }
            .sheet(item: $selectedFruit) { fruit in
                let binding = Binding<UIImage?>(
                    get: { fruitImages[fruit.name]?.image },
                    set: { newImage in
                        if let img = newImage {
                            fruitImages[fruit.name] = FruitImageInfo(image: img, date: Date())
                        } else {
                            fruitImages.removeValue(forKey: fruit.name)
                        }
                        saveFruitImagesToDisk()
                    }
                )

                FlippableCardContainer(
                    fruit: fruit,
                    selectedImage: binding,
                    pickerSource: $pickerSource,
                    isCameraAvailable: isCameraAvailable
                )
                .id(fruit.id)
            }
        }
    }

    // MARK: - Load Fruityvice Data
    func loadFruits() async {
        guard let url = URL(string: "https://www.fruityvice.com/api/fruit/all") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([Fruit].self, from: data)
            DispatchQueue.main.async {
                fruits = decoded
                loadFruitImagesFromDisk()
            }
        } catch {
            print("Error loading fruits:", error)
        }
    }

    // MARK: - Persistence
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func saveFruitImagesToDisk() {
        var savedData: [String: [String: Any]] = [:]

        for (fruitName, info) in fruitImages {
            let imageURL = getDocumentsDirectory().appendingPathComponent("\(fruitName).jpg")

            if let image = info.image,
               let data = image.jpegData(compressionQuality: 0.9) {
                try? data.write(to: imageURL)
            }

            savedData[fruitName] = [
                "imagePath": imageURL.lastPathComponent,
                "date": info.date.timeIntervalSince1970
            ]
        }

        UserDefaults.standard.set(savedData, forKey: "SavedFruitImages")
    }

    func loadFruitImagesFromDisk() {
        guard let savedData = UserDefaults.standard.dictionary(forKey: "SavedFruitImages") as? [String: [String: Any]] else { return }

        var loaded: [String: FruitImageInfo] = [:]

        for (name, dict) in savedData {
            if let fileName = dict["imagePath"] as? String,
               let dateTimestamp = dict["date"] as? TimeInterval {
                let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)

                if let data = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: data) {
                    loaded[name] = FruitImageInfo(
                        image: image,
                        date: Date(timeIntervalSince1970: dateTimestamp)
                    )
                }
            }
        }

        fruitImages = loaded
    }

    // MARK: - PDF Report
    func savePDFReport() {
        let pdfMetaData = [
            kCGPDFContextCreator: "FruityVice App",
            kCGPDFContextAuthor: "Irina Safronova"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 612.0
        let pageHeight = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            for fruit in fruits {
                guard let info = fruitImages[fruit.name],
                      let image = info.image else { continue }

                context.beginPage()

                let headerAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 20)
                ]
                let bodyAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14)
                ]

                // Заголовок
                let title = "\(fruit.name)"
                title.draw(at: CGPoint(x: 20, y: 20), withAttributes: headerAttrs)

                // Текст с данными
                let df = DateFormatter()
                df.dateStyle = .medium
                df.timeStyle = .short

                let details =
                """
                Family: \(fruit.family)
                Calories: \(fruit.nutritions.calories)
                Carbs: \(fruit.nutritions.carbohydrates)
                Photo Date: \(df.string(from: info.date))
                """

                let textRect = CGRect(x: 20, y: 55, width: pageWidth - 40, height: 120)
                details.draw(in: textRect, withAttributes: bodyAttrs)

                // Картинка
                let imageMaxWidth = pageWidth - 40
                let imageMaxHeight = pageHeight - 190
                let aspect = image.size.width / image.size.height

                var drawW = imageMaxWidth
                var drawH = drawW / aspect
                if drawH > imageMaxHeight {
                    drawH = imageMaxHeight
                    drawW = drawH * aspect
                }

                let imageRect = CGRect(
                    x: (pageWidth - drawW) / 2,
                    y: 180,
                    width: drawW,
                    height: drawH
                )
                image.draw(in: imageRect)
            }
        }

        // Share PDF
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("FruitsReport.pdf")
        do {
            try data.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Could not save PDF: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
