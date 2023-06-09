//
//  AsyncImageViewModel.swift
//  CacheAsyncImage
//
//  Created by HYEONJUN PARK on 2023/06/09.
//

import Foundation
import SwiftUI
import Combine
class CachedAsyncImageViewModel: ObservableObject {
    
    @Published var phase: CachedAsyncImagePhase = .empty
    private var cancelable: AnyCancellable? = nil
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func fetch(url: URL?) async {
        guard let url = url else {
            phase = .failure(CachedAsyncImageError.urlError)
            return
        }
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
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
        } catch {
            phase = .failure(error)
        }
    }
    
    func fetchImage(url: URL?) {
        guard let url = url else {
            phase = .failure(CachedAsyncImageError.urlError)
            return
        }
        cancelable = URLSession.shared.dataTaskPublisher(for: url)
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
            }
        
    }
}
