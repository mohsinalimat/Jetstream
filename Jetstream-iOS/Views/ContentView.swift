//
//  ContentView.swift
//  Jetstream-iOS
//
//  Created by Andrew Shepard on 8/6/19.
//  Copyright © 2019 Andrew Shepard. All rights reserved.
//

import SwiftUI
import JetstreamKit

struct ContentView: View {
    @FetchRequest(fetchRequest: Weather.defaultFetchRequest()) var conditions: FetchedResults<Weather>
    
    var body: some View {
        // https://forums.developer.apple.com/thread/118172
        
        if let weather = conditions.first {
            let viewModel = WeatherViewModel(weather: weather)
            let weatherView = WeatherView(viewModel: viewModel)
                .background(Color.white)
                .edgesIgnoringSafeArea(.all)
            return AnyView(weatherView)
        } else {
            return AnyView(Text("Empty"))
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
