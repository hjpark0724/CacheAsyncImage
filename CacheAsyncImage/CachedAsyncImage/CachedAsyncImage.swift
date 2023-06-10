import SwiftUI
import Combine

/*
 * CachedAsyncImage 뷰의 상태 관리
 * empty - 초기 상태
 * success - 해당 URL에서 이미지를 정상적으로 가져온 상태
 * failure - URL에서 이미지 로드 실패
 */
public enum CachedAsyncImagePhase {
    case empty
    case success(Image)
    case failure(Error)
    
    public var image: Image? {
        if case let .success(image) = self {
            return image
        }
        return nil
    }
    
    public var error: (Error)? {
        if case let .failure(error) = self {
            return error
        }
        return nil
    }
}

public enum CachedAsyncImageError: Error {
    case urlError
    case networkError(Error)
    case httpResponseError(Int)
    case imageCreatedFail
}

struct CachedAsyncImage<Content>: View where Content: View{
    private var url: URL?
    private var scale: CGFloat
    private var transaction: Transaction
    private var content: (CachedAsyncImagePhase) -> Content
    @ObservedObject private var viewModel = CachedAsyncImageViewModel()
    
    /*
     * 사용 예)
     * let url = URL(string: "https://example.com/abc.png"
     *  CachedAsyncImage(url: URL)
     */
    
    init(url: URL?, scale: CGFloat = 1) where Content == Image {
        self.init(url: url) { phase in
            phase.image ?? Image(uiImage: .init())
        }
    }
    
    /*
     * 사용 예)
     * let url = URL(string: "https://example.com/abc.png"
     *   CachedAsyncImage(url: url) { image in
     *      image.resizable()
     *      .aspectRatio(contentMode: .fit)
     *   } placeholder: {
            RoundRectangle()
        }
     *
     */
    
    init<I, P>(url: URL?,
               scale: CGFloat = 1,
               @ViewBuilder content: @escaping (Image) -> I,
               @ViewBuilder placeholder: @escaping () -> P)
    where Content == _ConditionalContent<I, P>, I : View, P : View {
        self.init(url: url, scale: scale)  { phase in
            if case .success(let image) = phase {
                content(image)
            } else {
                placeholder()
            }
        }
    }
    
    /*
     * 사용 예)
     * let url = URL(string: "https://example.com/abc.png"
     *  CachedAsyncImage(url: url) { phase in
            if case let .success(image) = pahse {
     *          image.resizable()
     *          .aspectRatio(contentMode: .fit)
     *      } else if case let .failure(error) {
     *           Text("error : \(error)")
     *      }
     *
     */
    
    init(url: URL?,
         scale: CGFloat = 1.0,
         transaction: Transaction = Transaction(),
         @ViewBuilder content: @escaping (CachedAsyncImagePhase) -> Content) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }
    
    var body: some View {
        if #available(iOS 15.0, *) {
            content(viewModel.phase)
                .task {
                    await viewModel.fetch(url: url)
                }
        } else {
            content(viewModel.phase)
                .onAppear {
                    viewModel.fetchImage(url: url)
                }
        }
    }
}



struct CachedAsyncImage_Previews: PreviewProvider {
    static var previews: some View {
        let url = URL(string: "http://placehold.it/120×120&text=image4")
        CachedAsyncImage(url: url)
    }
}
