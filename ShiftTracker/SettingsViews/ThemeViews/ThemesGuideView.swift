//
//  ThemesGuideView.swift
//  testEnvironment
//
//  Created by Louis Kolodzinski on 8/07/23.
//

import SwiftUI

struct ThemesGuideView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var guideColor = false
    
    
    var body: some View {
        NavigationStack {
            VStack{
                
                ZStack{
                    
                    Rectangle()
                        .frame(maxWidth: 350, maxHeight: 125)
                        .foregroundStyle(.thinMaterial)
                        .background(.thinMaterial)
                        .cornerRadius(12)
                        
                    
                    
                    VStack{
                        
                    HStack{
                        Image(systemName: "paintpalette.fill")
                            .resizable()
                            .frame(maxWidth: 18, maxHeight: 18)
                            /*.foregroundStyle(LinearGradient(
                                colors: [.blue, .teal, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))*/
                            .foregroundStyle(.orange)
                            .padding(.bottom, 4)
                        
                        
                        Text("Creating Your Own Theme")
                            .font(.system(size: 15)) // Set the desired font size
                            .bold() // Apply the bold style
                            .kerning(-1)
                            .foregroundStyle(LinearGradient(
                                colors: [.orange, .teal, .blue ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                        //.font(.system(size: 15))
                        
                    }//.padding(.bottom, 65)
                        
                        .padding(.trailing, 124)
                    
                        Text("Easily transform your ShiftTracker app's look and feel! Just tap any UI element, preview it, and use the color picker at the bottom to instantly change its hue. Effortlessly customize headers, buttons, and backgrounds for a personalized and visually appealing experience.")
                            .font(.system(size: 13))
                            .bold() // Apply the bold style
                            .kerning(-1)
                            //.padding(40)
                            .frame(width: 313, height: 78, alignment: .center)
                            
                    
                }
            }
                .padding()
            ZStack{
                
                Rectangle()
                
                    .frame(maxWidth: 350, maxHeight: 250)
                    .background(.thinMaterial)
                    .foregroundStyle(.thinMaterial)
                    .cornerRadius(12)
                
                
                
                
                HStack{
                    
                    //chart box
                    ZStack{
                        Rectangle()
                        //.background(.white)
                            .frame(maxWidth: 155, maxHeight: 205)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        HStack{
                            Rectangle()
                                .foregroundStyle(.thinMaterial)
                                .background(.thinMaterial)
                                .frame(maxWidth: 30, maxHeight: 140)
                                .cornerRadius(12)
                                .padding(.top,80)
                            //.padding(.trailing, 80)
                                .padding(.horizontal, 0)
                            
                            Rectangle()
                                .foregroundStyle(.thinMaterial)
                                .background(.thinMaterial)
                                .frame(maxWidth: 30, maxHeight: 165)
                                .cornerRadius(12)
                                .padding(.top, 55)
                                .padding(.horizontal, 8)
                            //.padding(.trailing, 80)
                            
                            
                            Rectangle()
                                .foregroundStyle(.thinMaterial)
                                .background(.thinMaterial)
                                .frame(maxWidth: 30, maxHeight: 90)
                                .cornerRadius(12)
                                .padding(.top, 130)
                        }
                    }
                    VStack{
                        
                        ZStack{
                            Rectangle()
                            //.background(.white)
                                .frame(maxWidth: 155, maxHeight: 100)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                               
                            
                            VStack(alignment: .leading){
                                Rectangle()
                                    .frame(maxWidth: 100, maxHeight: 10)
                                    .foregroundColor(guideColor ? .cyan : .clear)
                                    .background(.ultraThickMaterial)
                                    .cornerRadius(12)
                                
                                Rectangle()
                                    .frame(maxWidth: 70, maxHeight: 10)
                                    .foregroundColor(guideColor ? .cyan : .clear)
                                    .background(.thinMaterial)
                                    .cornerRadius(12)
                                
                                Rectangle()
                                    .frame(maxWidth: 85, maxHeight: 10)
                                    .foregroundColor(guideColor ? .cyan : .clear
                                    )
                                    .background(.ultraThickMaterial)
                                    .cornerRadius(12)
                                
                                Rectangle()
                                    .frame(maxWidth: 95, maxHeight: 10)
                                    .foregroundColor(guideColor ? .cyan : .clear)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                            }
                        }
                        
                        
                        Rectangle()
                        //.background(.white)
                            .frame(maxWidth: 155, maxHeight: 100)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                    
                    
                }
            }
            //color picker here
            ZStack{
                Rectangle()
                    .frame(maxWidth: 350, maxHeight: 55)
                    .foregroundStyle(.thinMaterial)
                    .background(.thinMaterial)
                    .cornerRadius(12)
                
                HStack{
                    
                    Circle()
                        .frame(maxWidth: 30, maxHeight: 30)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                    
                    Circle()
                        .frame(maxWidth: 30, maxHeight: 30)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                    
                    Circle()
                        .frame(maxWidth: 30, maxHeight: 30)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                    
                    ZStack{
                        Circle()
                            .frame(maxWidth: 30, maxHeight: 30)
                            .foregroundColor(guideColor ? .cyan : .white)
                            .padding(.horizontal, 4)
                        
                        
                        Circle()
                            .frame(maxWidth: 15, maxHeight: 15)
                        
                            .foregroundStyle(.thinMaterial)
                        
                            
                    }
                    
                    Circle()
                        .frame(maxWidth: 30, maxHeight: 30)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                    
                    Circle()
                        .frame(maxWidth: 30, maxHeight: 30)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                    
                    Divider()
                        .frame(height: 20)
                    //.padding(.trailing)
                    
                    ZStack{
                        
                        Circle()
                            .frame(maxWidth: 30, maxHeight: 30)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                        
                        Circle()
                            .frame(maxWidth: 20, maxHeight: 20)
                            .foregroundStyle(.thinMaterial)
                        
                        Circle()
                            .frame(maxWidth: 10, maxHeight: 10)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                        
                    }
                }
                .padding(.horizontal)
                
                
            }.padding(.top, 5)
                
                /*Button(action: {
                    
                    self.guideColor.toggle()
                }){
                    
                    Rectangle()
                        .frame(maxWidth: 50, maxHeight: 50)
                    
                }*/
                
                
                
                
                
                
            Spacer()
                
                
                
        }
            
            
        .navigationTitle("How to use themes")
            
            
        .toolbar{
            
            ToolbarItem(placement: .navigationBarTrailing){
                CloseButton(action: {
                    dismiss()
                })
            }
            
            
        }
            
    }
    }
    
 
}

struct ThemesGuideView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        ThemesGuideView()
        
    }
    
    
}
