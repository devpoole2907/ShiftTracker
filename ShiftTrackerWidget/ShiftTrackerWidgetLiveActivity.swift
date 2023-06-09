//
//  ShiftTrackerWidgetLiveActivity.swift
//  ShiftTrackerWidget
//
//  Created by James Poole on 18/03/23.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ShiftActivityView: View{
    let context: ActivityViewContext<ShiftTrackerWidgetAttributes>
    var body: some View{
        
        VStack(alignment: .leading){
            HStack{
                Text("ShiftTracker")
                    .bold()
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text("PRO")
                    .bold()
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.orange)
                
                if context.state.isOnBreak{
                    Text("On Break")
                        .font(.caption)
                        .bold()
                        .frame(width: 80, height: 20)
                        .background(.indigo)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .padding(.bottom, 1)
                }
            }.padding(.horizontal, 20)
                .padding(.top, 15)
        
            HStack {
               
                    //.padding(.vertical, 10)
                if context.state.isOnBreak{
                    Text(context.state.startTime, style: .timer)
                        .font(.system(size: 45))
                        .foregroundColor(Color.indigo)
                        .bold()
                        .padding(.horizontal, 20)
                    Button(action: {
                        // Action to perform when button is tapped
                    }) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 45))
                            .foregroundColor(.indigo.opacity(0.8))
                    }
                }
                else {
                    Text(context.state.startTime, style: .timer)
                        .font(.system(size: 45))
                        .foregroundColor(Color.orange)
                        .bold()
                        .padding(.horizontal, 20)
                    Button(action: {
                        // Action to perform when button is tapped
                    }) {
                        Image(systemName: "pause.circle")
                            .font(.system(size: 45))
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }
                    Button(action: {
                        // Action to perform when button is tapped
                    }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 45))
                            .foregroundColor(.gray.opacity(0.6))
                    }

                
            }
            .padding()
        }
            .background(Color.black)
    }
}

struct ExpandedIslandView: View{
    let context: ActivityViewContext<ShiftTrackerWidgetAttributes>
    var body: some View{
        
        VStack(alignment: .leading){
            HStack{
                Text("ShiftTracker")
                    .bold()
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text("PRO")
                    .bold()
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.orange)
                
                    
            }.padding()
               // .padding(.bottom,15)
        
          /*  HStack {
                Text(context.state.startTime, style: .timer)
                    .font(.system(size: 45))
                    .foregroundColor(Color.orange)
                    .bold()
                    .padding(.horizontal, 20)
                    //.padding(.vertical, 10)
                

                
            }
            .padding() */
        }
            .background(Color.black)
        
            .privacySensitive(false)
    }
}

struct IslandMinimalView: View {
    let context: ActivityViewContext<ShiftTrackerWidgetAttributes>
    var body: some View{
        Text(context.state.startTime, style: .timer)
    }
}

struct ShiftTrackerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ShiftTrackerWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(alignment: .center){
                ShiftActivityView(context: context)
                    //.activityBackgroundTint(Color(red: 50/255, green: 50/255, blue: 50/255).opacity(0.4))
                    .activitySystemActionForegroundColor(Color.black)
            }

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    VStack{
                        Spacer()
                        HStack(spacing: 1){
                            if context.state.isOnBreak{
                                Button(action: {
                                    // Action to perform when button is tapped
                                }) {
                                    Image(systemName: "play.circle")
                                        .font(.system(size: 40))
                                        .foregroundColor(.indigo.opacity(0.8))
                                }
                            }
                            else {
                                Button(action: {
                                    // Action to perform when button is tapped
                                }) {
                                    Image(systemName: "pause.circle")
                                        .font(.system(size: 40))
                                        .foregroundColor(.orange.opacity(0.8))
                                }
                            }
                                Button(action: {
                                    // Action to perform when button is tapped
                                }) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                            
                        }
                    }//.padding(.top, 10)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack{
                    Spacer()
                        if !context.state.isOnBreak{
                            Text(context.state.startTime, style: .timer)
                                .font(.system(size: 35))
                                .foregroundColor(Color.orange)
                                .bold()
                        }
                        else {
                            Text(context.state.startTime, style: .timer)
                                .font(.system(size: 35))
                                .foregroundColor(Color.indigo)
                                .bold()
                        }
                        
                        
                        
                    }.padding(.horizontal, -20)
                        .padding(.top, -5)
                        .padding(.leading, 15)
                    
                       // .padding(.horizontal, 20)
                }
                DynamicIslandExpandedRegion(.bottom) {
                   // ExpandedIslandView(context: context)
                    
                    HStack{
                        Text("ShiftTracker")
                            .font(.caption2)
                            .bold()
                        Text("PRO")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .bold()
                    }
                    if context.state.isOnBreak{
                        Text("On Break")
                            .font(.caption)
                            .bold()
                            .frame(width: 80, height: 20)
                            .background(.indigo)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .padding(.bottom, 1)
                    }
                    //.padding(.bottom, -5)
                    
                    
                    
                }
                
            } compactLeading: {
                if !context.state.isOnBreak{
                    Image(systemName: "briefcase.circle")
                        
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.orange)
                }
                else {
                    Text("Break")
                        .foregroundColor(.indigo)
                        .font(.caption2)
                        //.frame(maxWidth: 50)
                        .padding(.leading, 8)
                }
                    //.frame(width: 40)
                    
            } compactTrailing: {
                if context.state.isOnBreak{
                    Text(context.state.startTime, style: .timer).monospacedDigit()
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 50)
                        .font(.caption2)
                        .foregroundColor(.indigo)
                }
                else {
                    Text(context.state.startTime, style: .timer)
                        .monospacedDigit()
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 50)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                    
                
                    //.frame(alignment: .trailing)
            } minimal: {
                if !context.state.isOnBreak{
                    Image(systemName: "briefcase.circle")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.orange)
                }
                else {
                    Image(systemName: "briefcase.circle")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.indigo)
                }
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.orange)
        }
    }
}

struct ShiftTrackerWidgetLiveActivity_Previews: PreviewProvider {
    static let attributes = ShiftTrackerWidgetAttributes(name: "Me", hourlyPay: 24)
    static let contentState = ShiftTrackerWidgetAttributes.ContentState(startTime: Date(), totalPay: 220, isOnBreak: true)

    static var previews: some View {
        if #available(iOS 16.2, *) {
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Island Compact")
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Island Expanded")
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
                .previewDisplayName("Minimal")
            attributes
                .previewContext(contentState, viewKind: .content)
                .previewDisplayName("Notification")
        }
    }
}

extension UIImage {
    func imageResized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
