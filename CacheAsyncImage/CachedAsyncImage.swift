//
//  CachedAsyncImage.swift
//  CachedAsyncImage
//
//  Created by HYEONJUN PARK on 2023/06/09.
//

import SwiftUI

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
    case networkError(Error)
    case httpResponseError(Int)
    case imageCreatedFail
}

struct CachedAsyncImage<Content>: View where Content: View{
    private var url: URL?
    private var scale: CGFloat
    private var transaction: Transaction
    private var content: (CachedAsyncImagePhase) -> Content
    @State private var phase: CachedAsyncImagePhase
    
    init(url: URL?, scale: CGFloat = 1) where Content == Image {
        self.init(url: url) { phase in
            phase.image ?? Image(uiImage: .init())
        }
    }
    
    
    init<I, P>(url: URL,
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
    
    
    init(url: URL?,
         scale: CGFloat = 1.0,
         transaction: Transaction = Transaction(),
         @ViewBuilder content: @escaping (CachedAsyncImagePhase) -> Content) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self._phase = State(wrappedValue: .empty)
    }
    
    var body: some View {
        if #available(iOS 15.0, *) {
            content(phase)
                .task {
                    guard let url = self.url else { return }
                    let request = URLRequest(url: url)
                    do {
                        let (data, response) = try await
                        URLSession.shared.data(for: request)
                        let httpResponse = response as! HTTPURLResponse
                        if httpResponse.statusCode < 200 || httpResponse.statusCode > 300 {
                            self.phase = .failure(CachedAsyncImageError.httpResponseError(httpResponse.statusCode))
                            print("http response error: \(httpResponse.statusCode)")
                        }
                        guard let uiImage = UIImage(data: data) else {
                            self.phase = .failure(CachedAsyncImageError.imageCreatedFail)
                            print("image create fail")
                            return
                        }
                        withAnimation(transaction.animation) {
                                self.phase = .success(Image(uiImage: uiImage))
                            }
                    } catch {
                        self.phase = .failure(error)
                        print("url request failed: \(error)")
                    }
                }
            
        } else {
            content(phase)
                .onAppear {
                    guard let url = self.url else { return }
                    let reqeust = URLRequest(url: url)
                    URLSession.shared.dataTask(with: reqeust){(data, response, error) in
                        DispatchQueue.main.async {
                            if let error = error { self.phase = .failure(error) }
                            let httpResponse = response as! HTTPURLResponse
                            if httpResponse.statusCode < 200 || httpResponse.statusCode > 300 {
                                self.phase = .failure(CachedAsyncImageError.httpResponseError(httpResponse.statusCode))
                                print("http response error: \(httpResponse.statusCode)")
                                return
                            }
                            guard let uiImage = UIImage(data: data!) else {
                                self.phase = .failure(CachedAsyncImageError.imageCreatedFail)
                                print("image create fail")
                                return
                            }
                            withAnimation(transaction.animation) {
                                self.phase = .success(Image(uiImage: uiImage))
                            }
                            
                        }
                    }.resume()
                }
        }
    }
}


struct CachedAsyncImage_Previews: PreviewProvider {
    static var previews: some View {
        let url = URL(string: "https://is4-ssl.mzstatic.com/image/thumb/Purple1/v4/33/30/c0/3330c035-96ba-22ab-826d-cf7220c2a2da/pr_source.png/392x696bb.png")
        CachedAsyncImage(url: url)
    }
}


