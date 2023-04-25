//
//  ContentView.swift
//  ShiftTracker Watch Edition Watch App
//
//  Created by James Poole on 25/04/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack{
            List {
                
                NavigationLink(destination: TimerView()){
                    HStack{
                        VStack(alignment: .leading, spacing: 5){
                            Image(systemName: "briefcase.circle")
                                .foregroundColor(.cyan)
                                .font(.title)
                            Text("TVNZ")
                                .font(.headline)
                                .bold()
                            Text("Service Centre Analyst")
                                .font(.footnote)
                                .foregroundColor(.cyan)
                                .bold()
                            
                        }
                        Spacer()
                        
                        VStack{
                            Button(action: {
                                
                            }) {
                                Image(systemName: "ellipsis.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.title2)
                            }
                            Spacer()
                        }
                    }
                    .padding()
                }
                
            }.listStyle(CarouselListStyle())
                .navigationBarTitle("ShiftTracker")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct TimerView: View {
    var body: some View{
        
        Text("Cheese")
            .navigationBarTitle("Job name")
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
    }
}
