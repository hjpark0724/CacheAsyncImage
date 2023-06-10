import SwiftUI
struct ProfileImage: View {
    @State var isPresented: Bool = false
    @ObservedObject var state = ProfileViewModel()
    @GestureState private var isDetectingLongPress = false
    @State private var completedLongPress = false
    
    var body: some View {
        LoadImageView(status: state.status)
            .scaledToFill()
            .frame(maxWidth: 100, maxHeight: 100)
            .background(
                LinearGradient(
                    colors: [.white, .gray.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                    )
            )
            .overlay(
                Circle().stroke(
                    LinearGradient(
                        colors: [.white, .gray.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1
                )
            )
            .clipShape(Circle())
            .shadow(radius: 4)
            .onLongPressGesture(minimumDuration: 0.5) {
                isPresented = true
            }
            .sheet(isPresented: $isPresented) {
                PhotoPicker(results: $state.selections)
            }
    }
}

struct LoadImageView: View {
    var status: ProfileViewStatus
    var body: some View {
        switch status {
        case .success(let image):
            image.resizable()
                .aspectRatio(contentMode: .fit)
        case .loading:
            ProgressView()
        case .empty:
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        case .failure(_):
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
    }
}

struct ProfileViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        
    }
}
struct ProfileImage_Previews: PreviewProvider {
    static var previews: some View {
        ProfileImage()
            .frame(width: 100, height: 100)
    }
}
