import SwiftUI

struct ContentView: View {
    @State private var fruits: [Fruit] = []
    @State private var selectedFruit: Fruit? = nil
    @State private var fruitImages: [UUID: UIImage] = [:]   // ✅ хранение по UUID
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationView {
            ZStack {
                if fruits.isEmpty {
                    // 🔄 Индикатор загрузки
                    ProgressView("Loading fruits...")
                        .task { await loadFruits() }
                } else {
                    List(fruits) { fruit in
                        Button {
                            selectedFruit = fruit
                            print("🍎 Selected fruit:", fruit.name)
                        } label: {
                            HStack(spacing: 12) {
                                // 🟣 Добавлено из версии Jasper — миниатюра фото 40x40
                                if let image = fruitImages[fruit.id] {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.purple, lineWidth: 2))
                                        .shadow(radius: 3)
                                } else {
                                    // если нет фото — placeholder
                                    Circle()
                                        .fill(
                                            LinearGradient(colors: [.purple.opacity(0.5), .pink.opacity(0.5)],
                                                           startPoint: .topLeading,
                                                           endPoint: .bottomTrailing)
                                        )
                                        .frame(width: 40, height: 40)
                                        .overlay(Image(systemName: "photo")
                                            .foregroundColor(.white.opacity(0.7)))
                                }

                                // 🍏 Информация о фрукте
                                VStack(alignment: .leading) {
                                    Text(fruit.name)
                                        .font(.headline)
                                    Text(fruit.family)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("FruityVice 🍇")
            // 🧩 Карточка выбранного фрукта
            .sheet(item: $selectedFruit) { fruit in
                let bindingImage = Binding<UIImage?>(
                    get: { fruitImages[fruit.id] },
                    set: { fruitImages[fruit.id] = $0 }
                )

                FlippableCardContainer(
                    fruit: fruit,
                    selectedImage: bindingImage,
                    pickerSource: $pickerSource,
                    isCameraAvailable: isCameraAvailable
                )
                .id(fruit.id)
            }
        }
    }

    // MARK: - Загрузка данных
    func loadFruits() async {
        guard let url = URL(string: "https://www.fruityvice.com/api/fruit/all") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([Fruit].self, from: data)
            DispatchQueue.main.async {
                fruits = decoded
                print("✅ Loaded \(decoded.count) fruits.")
            }
        } catch {
            print("❌ Error loading fruits:", error)
        }
    }
}

#Preview {
    ContentView()
}
