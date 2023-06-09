//
//  ContentView.swift
//  CacheAsyncImage
//
//  Created by HYEONJUN PARK on 2023/06/09.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            let url = URL(string: "https://is4-ssl.mzstatic.com/image/thumb/Purple1/v4/33/30/c0/3330c035-96ba-22ab-826d-cf7220c2a2da/pr_source.png/392x696bb.png")
            CachedAsyncImage(url: url) { phase in
                if case let .success(image) = phase {
                    image
                } else {
                    Text("fail to")
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
