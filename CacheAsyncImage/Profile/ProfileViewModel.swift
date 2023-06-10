//
//  ProfileViewModel.swift
//  CacheAsyncImage
//
//  Created by HYEONJUN PARK on 2023/06/10.
//

import SwiftUI
import PhotosUI

enum ProfileViewStatus {
    case success(Image)
    case empty
    case loading
    case failure(Error)
    
    var image: Image? {
        if case let .success(image) = self {
            return image
        }
        return nil
    }
}

class ProfileViewModel: ObservableObject {
    @Published var status: ProfileViewStatus = .empty
    @Published var selections: [PHPickerResult]? = nil {
        didSet {
            guard let provider = selections?.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                self.status = .empty
                return
                
            }
            status = .loading
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                guard let image = image as? UIImage else {
                    self.status = .empty
                    return
                }
                self.status = .success(Image(uiImage: image))
            }
        }
    }
    

    func save(image: UIImage) {
        do {
            let url = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("profile", conformingTo: .jpeg)
            if let jpeg = image.jpegData(compressionQuality: 0.5) {
                try jpeg.write(to: url, options: [.atomic, .completeFileProtection])
            }
        } catch {
            
        }
        
        
    }
}


