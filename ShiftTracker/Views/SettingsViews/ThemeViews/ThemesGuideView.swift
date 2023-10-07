//
//  ThemesGuideView.swift
//  testEnvironment
//
//  Created by Louis Kolodzinski on 8/07/23.
//

import SwiftUI

struct ThemesGuideView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var guideColor = false
    
    var guideBackgroundColor: Color {
        return colorScheme == .dark ? .gray.opacity(0.1) : .white
        }
    
    
    var body: some View {
        NavigationStack {
            VStack{
                
            
                    
                    
                    
                VStack(alignment: .leading, spacing: 20){
                        
                    HStack{
                        Image(systemName: "paintpalette.fill")
                            .resizable()
                            .frame(maxWidth: 18, maxHeight: 18)
                         
                            .foregroundStyle(colorScheme == .dark ? .orange : .cyan)
                      
                        
                        
                        Text("Creating Your Own Theme")
                            .font(.headline)
                            .roundedFontDesign()
                            .bold()
                            
                   
                            
                   
                    }
                        
                   
                    
                        Text("Select the UI element you wish to change the color of, then select a color from the picker.")
                            .font(.caption2)
                            .bold()
                           
                            
                    
                    }.padding()
                    .background(Color("SquaresColor"))
                    .cornerRadius(12)
            
                .padding()
            ZStack{
                
                Rectangle()
                
                    .frame(maxHeight: 250)
                    .background(Color("SquaresColor"))
                    .foregroundStyle(Color("SquaresColor"))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                
                
                
                HStack{
                    
                    //chart box
                    ZStack{
                        Rectangle()
                        //.background(.white)
                            .frame(maxWidth: 155, maxHeight: 205)
                            .foregroundStyle(guideBackgroundColor)
                            .cornerRadius(12)
                        HStack{
                            Rectangle()
                                .foregroundStyle(Color("SquaresColor"))
                                .background(Color("SquaresColor"))
                                .frame(maxWidth: 30, maxHeight: 140)
                                .cornerRadius(12)
                                .padding(.top,80)
                            //.padding(.trailing, 80)
                                .padding(.horizontal, 0)
                            
                            Rectangle()
                                .foregroundStyle(Color("SquaresColor"))
                                .background(Color("SquaresColor"))
                                .frame(maxWidth: 30, maxHeight: 165)
                                .cornerRadius(12)
                                .padding(.top, 55)
                                .padding(.horizontal, 8)
                            //.padding(.trailing, 80)
                            
                            
                            Rectangle()
                                .foregroundStyle(Color("SquaresColor"))
                                .background(Color("SquaresColor"))
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
                                .foregroundStyle(guideBackgroundColor)
                                .cornerRadius(12)
                               
                            
                            VStack(alignment: .leading){
                                Rectangle()
                                    .frame(maxWidth: 100, maxHeight: 10)
                                    .foregroundColor(Color("SquaresColor"))
                                    .background(Color("SquaresColor"))
                                    .cornerRadius(12)
                                
                                Rectangle()
                                    .frame(maxWidth: 70, maxHeight: 10)
                                    .foregroundColor(Color("SquaresColor"))
                                    .background(Color("SquaresColor"))
                                    .cornerRadius(12)
                                
                                Rectangle()
                                    .frame(maxWidth: 85, maxHeight: 10)
                                    .foregroundColor(Color("SquaresColor")
                                    )
                                    .background(Color("SquaresColor"))
                                    .cornerRadius(12)
                                
                                Rectangle()
                                    .frame(maxWidth: 95, maxHeight: 10)
                                    .foregroundColor(Color("SquaresColor"))
                                    .background(Color("SquaresColor"))
                                    .cornerRadius(12)
                            }
                        }
                        
                        
                        Rectangle()
                        //.background(.white)
                            .frame(maxWidth: 155, maxHeight: 100)
                            .foregroundStyle(guideBackgroundColor)
                            .cornerRadius(12)
                    }
                    
                    
                }
            }
            //color picker here
            ZStack{
                Rectangle()
                    .frame(maxWidth: 350, maxHeight: 55)
                    .foregroundStyle(Color("SquaresColor"))
                    .background(Color("SquaresColor"))
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
                        
                            .foregroundStyle(Color("SquaresColor"))
                        
                            
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
                            .foregroundStyle(Color("SquaresColor"))
                        
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
            
            
        .navigationTitle("Themes Info")
        .navigationBarTitleDisplayMode(.inline)
            
            
        .toolbar{
            
            ToolbarItem(placement: .navigationBarTrailing){
                CloseButton()
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
