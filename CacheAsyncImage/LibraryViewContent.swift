//
//  LibraryViewContent.swift
//  CacheAsyncImage
//
//  Created by HYEONJUN PARK on 2023/06/10.
//

import SwiftUI
struct LibraryViewContent: LibraryContentProvider {
    let url = URL(string: "http://placehold.it/120×120&text=image4")
    var views: [LibraryItem] {
        LibraryItem(CachedAsyncImage(url: url))
        LibraryItem(ProfileImage())
    }
}

