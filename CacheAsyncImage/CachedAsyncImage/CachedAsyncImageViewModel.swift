
import Foundation
import SwiftUI
import Combine

class CachedAsyncImageViewModel: ObservableObject {
    @Published var phase: CachedAsyncImagePhase = .empty
    private var cancelable: AnyCancellable? = nil
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @MainActor
    func fetch(url: URL?) async {
        guard let url = url else {
            phase = .failure(CachedAsyncImageError.urlError)
            return
        }
        
        let request = URLRequest(url: url)
        if let uiImage = ImageCache.shared.load(request) {
            phase = .success(Image(uiImage: uiImage))
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = ImageCache.shared.cache
        configuration.httpMaximumConnectionsPerHost = 10
        let session = URLSession(configuration: configuration)
       
        do {
            let (data, response) = try await session.data(for: request)
            let httpResponse = response as! HTTPURLResponse
            if httpResponse.statusCode < 200 || httpResponse.statusCode > 300 {
                phase = .failure(CachedAsyncImageError.httpResponseError(httpResponse.statusCode))
                return
            }
            
            guard let uiImage = UIImage(data: data) else {
                phase = .failure(CachedAsyncImageError.imageCreatedFail)
                return
            }
            phase = .success(Image(uiImage: uiImage))
            ImageCache.shared.store(request, response: response, data: data)
        } catch {
            phase = .failure(error)
        }
    }
    
    func fetchImage(url: URL?) {
        guard let url = url else {
            phase = .failure(CachedAsyncImageError.urlError)
            return
        }

        let request = URLRequest(url: url)
        if let uiImage = ImageCache.shared.load(request) {
            phase = .success(Image(uiImage: uiImage))
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = ImageCache.shared.cache
        configuration.httpMaximumConnectionsPerHost = 10
        let session = URLSession(configuration: configuration)
        
        cancelable = session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode < 200 || httpResponse.statusCode > 300 {
                    throw CachedAsyncImageError.httpResponseError(httpResponse.statusCode)
                    
                }
                return (data, response)
            }
            .receive(on: DispatchQueue.main)
            .sink { completon in
                if case let .failure(error) = completon {
                    self.phase = .failure(error)
                }
            } receiveValue: { data, response in
                guard let uiImage = UIImage(data: data) else {
                    self.phase = .failure(CachedAsyncImageError.imageCreatedFail)
                    return
                }
                self.phase = .success(Image(uiImage: uiImage))
                ImageCache.shared.store(request, response: response, data: data)
                
            }
    }
    
}

fileprivate final class ImageCache {
    static let shared = ImageCache()
    let cache: URLCache
    private init() {
        self.cache = URLCache(memoryCapacity: 32*1000*1000, diskCapacity: 100*1000*1000)
    }
    
    //캐시에 UIImage가 있는 경우 이미지를 반환하고 없는 경우 nil을 반환
    func load(_ request: URLRequest) -> UIImage? {
        guard let response = cache.cachedResponse(for: request) else { return nil }
        guard let uiImage = UIImage(data: response.data) else {
            cache.removeCachedResponse(for: request)
            return nil
        }
        //print("cache hit: \(request.url!.absoluteString)")
        return uiImage
    }
    
    //캐시에 request에 해당 하는 response 값과 data를 이용해 CachedResponse를 생성해 저장
    func store(_ request: URLRequest, response: URLResponse, data: Data) {
        cache.removeCachedResponse(for: request)
        let cachedResponse = CachedURLResponse(response: response, data: data)
        cache.storeCachedResponse(cachedResponse, for: request)
    }
    
}
