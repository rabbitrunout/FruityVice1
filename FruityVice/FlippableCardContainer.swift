
//

import SwiftUI

struct FlippableCardContainer: View {
    let fruit: Fruit

    // Bindings from parent
    @Binding var selectedImage: UIImage?
    @Binding var pickerSource: UIImagePickerController.SourceType
    var isCameraAvailable: Bool

    // Local state
    @State private var rotation = 0.0
    @State private var showingImagePicker = false

    var body: some View {
        VStack {
            ZStack {
                // Show front or back depending on rotation (use truncatingRemainder to be robust)
                if rotation.truncatingRemainder(dividingBy: 360) < 90 ||
                   rotation.truncatingRemainder(dividingBy: 360) > 270 {
                    frontContent
                        .onTapGesture { flipCard() }
                } else {
                    backContent
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) // un-mirror
                        .onTapGesture { flipCard() }
                }
            }
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .animation(.easeInOut(duration: 0.6), value: rotation)
        .frame(height: 350)
        .padding()
        .onAppear {
            // Ensure rotation is set on the next main-runloop pass so layout happens after state stabilizes
            DispatchQueue.main.async {
                rotation = 0
            }
        }
        // Present the picker as a fullScreenCover attached to this container so it shows immediately
        .fullScreenCover(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: pickerSource, selectedImage: $selectedImage)
        }
    }

    // MARK: - Front
    private var frontContent: some View {
        VStack(spacing: 10) {
            Text(fruit.name)
                .font(.title)
                .bold()
            Text(fruit.family)
                .foregroundColor(.secondary)
            Text("Calories: \(fruit.nutritions.calories)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }

    // MARK: - Back
    private var backContent: some View {
        VStack(spacing: 10) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
            } else {
                Text("No Image Selected")
                    .foregroundColor(.gray)
            }

            HStack(spacing: 20) {
                Button("Pick from Library") {
                    pickerSource = .photoLibrary
                    showingImagePicker = true
                }

                Button("Take Photo") {
                    guard isCameraAvailable else { return }
                    pickerSource = .camera
                    showingImagePicker = true
                }
                .disabled(!isCameraAvailable)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.95))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }

    private func flipCard() {
        rotation += 180
    }
}

// Preview
#Preview {
    let sampleFruit = Fruit(
        name: "Apple",
        genus: "Malus",
        family: "Rosaceae",
        order: "Rosales",
        nutritions: Nutrition(carbohydrates: 13.81, protein: 0.26, fat: 0.17, calories: 52, sugar: 10.39)
    )
    @State var selectedImage: UIImage? = nil
    @State var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    return FlippableCardContainer(
        fruit: sampleFruit,
        selectedImage: $selectedImage,
        pickerSource: $pickerSource,
        isCameraAvailable: false
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
