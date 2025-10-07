import SwiftUI

struct FlippableCardView: View {
    let frontText: String
    let backImage: UIImage?

    var body: some View {
        ZStack {
            // Front side
            VStack {
                Text(frontText)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(colors: [.purple, .pink],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            )
            .cornerRadius(20)
            .shadow(radius: 10)
            .opacity(backImage == nil ? 1 : 0)

            // Back side
            if let image = backImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(20)
                    .shadow(radius: 10)
            }
        }
        .frame(height: 350)
        .padding()
    }
}

#Preview {
    FlippableCardView(frontText: "Apple", backImage: nil)
}
