//
//  ShiftTrackerActivityTimerLiveActivity.swift
//  ShiftTrackerActivityTimer
//
//  Created by James Poole on 29/07/23.
//

import ActivityKit
import WidgetKit
import SwiftUI



struct ShiftTrackerActivityTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(alignment: .center){
                ShiftActivityView(context: context)
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)
            
        } dynamicIsland: { context in
            DynamicIsland {
                
                DynamicIslandExpandedRegion(.trailing){
                 
                    Text("PRO")
                        .foregroundStyle(.orange.gradient)
                        .fontWeight(.heavy)
                        .padding([.top], 10)
                        .padding(.trailing, 35)
                }.contentMargins(.vertical, 0)
                

                DynamicIslandExpandedRegion(.bottom, priority: 1) {
                    
                    HStack {
                        
                        VStack(alignment: .leading) {
                            HStack{
                                Image(systemName: context.attributes.jobIcon)
                                    .foregroundStyle(.white)
                                    .font(.title3)
                                    .padding(10)
                                    .background{
                                        Circle()
                                            .foregroundStyle(jobColor(from: context).gradient)
                                    }
                                    .shadow(color: jobColor(from: context), radius: 3)
                                VStack(alignment: .leading, spacing: 1){
                                    Text(context.attributes.jobName)
                                        .fontDesign(.rounded)
                                        .bold()
                                    HStack(spacing: 0){
                                        Text("\(context.state.isOnBreak ? "Break s" : "S")tarted at ")
                                        Text(context.state.startTime, style: .time)
                                    }
                                    .font(.footnote)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(.gray)
                                }
                                
                                
                            }.padding(.vertical, 5)
                        }
                        
                        Spacer()
                        
                    }
                    HStack{
                        Button(action: {
                            
                            // start the break or end the break if on break
                            
                        }){
                            Text(context.state.isOnBreak ? "End Break" : "Break")
                                .fontDesign(.rounded)
                                .bold()
                                .padding(3)
                            
                        }.tint(.indigo)
                        
                        Button(action: {
                            // end the shift, do nothing if on break
                            
                        }){
                            Text("End Shift")
                                .fontDesign(.rounded)
                                .bold()
                                .padding(3)
                            
                        }.tint(context.state.isOnBreak ? .gray : .red)
                        
                        
                        Text(context.state.startTime, style: .timer)
                            .fontDesign(.rounded)
                            .multilineTextAlignment(.trailing)
                            .font(.title)
                            .bold()
                        
                            .foregroundStyle(jobColor(from: context))
                         
                    }
                    
                }
                
            } compactLeading: {
                Image(systemName: context.attributes.jobIcon)
                    .foregroundStyle(jobColor(from: context).gradient)
                
            } compactTrailing: {
                
                var startTime = context.state.startTime
                
                Text(context.state.startTime, style: .timer)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(jobColor(from: context))
                    .fontDesign(.rounded)
                    .font(.caption)
                    .frame(width: 60)
            } minimal: {
                
                Image(systemName: context.attributes.jobIcon)
                    .foregroundStyle(jobColor(from: context).gradient)
                
                
            }
            .widgetURL(URL(string: "shifttrackerapp://"))
            .keylineTint(Color.orange)
        }
    }
    

    
    func jobColor(from context: ActivityViewContext<LiveActivityAttributes>) -> Color {
        return context.state.isOnBreak ? Color.indigo : Color(red: context.attributes.jobColorRed, green: context.attributes.jobColorGreen, blue: context.attributes.jobColorBlue)
    }
    
    
}

struct ShiftActivityView: View{
    
    @Environment(\.colorScheme) var colorScheme
    
    let context: ActivityViewContext<LiveActivityAttributes>
    
    var body: some View{
        
        let proColor = colorScheme == .dark ? Color.orange : Color.cyan
        
        let jobColor = context.state.isOnBreak ? Color.indigo : Color(red: context.attributes.jobColorRed, green: context.attributes.jobColorGreen, blue: context.attributes.jobColorBlue)
        
        VStack(alignment: .leading, spacing: 8){
      
            HStack(spacing: 2){
                Text("ShiftTracker")
                    .bold()
                Text("PRO")
                    .font(.title2)
                    .foregroundStyle(.orange.gradient)
                    .fontWeight(.heavy)
            }

                HStack {
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Image(systemName: context.attributes.jobIcon)
                                .foregroundStyle(.white)
                                .font(.title3)
                                .padding(10)
                                .background{
                                    Circle()
                                        .foregroundStyle(jobColor.gradient)
                                }
                                .shadow(color: jobColor, radius: 3)
                            VStack(alignment: .leading, spacing: 1){
                                Text(context.attributes.jobName)
                                    .fontDesign(.rounded)
                                    .bold()
                                HStack(spacing: 0){
                                    Text("\(context.state.isOnBreak ? "Break s" : "S")tarted at ")
                                    Text(context.state.startTime, style: .time)
                                }
                                .font(.footnote)
                                .fontDesign(.rounded)
                                .foregroundStyle(.gray)
                            }
                            
                            
                        }.padding(.vertical, 5)
                    }
                    
                    Spacer()
                    
                }
                HStack{
                    Button(action: {
                        
                        // start the break or end the break if on break
                        
                    }){
                        Text(context.state.isOnBreak ? "End Break" : "Break")
                            .fontDesign(.rounded)
                            .bold()
                            .padding(3)
                        
                    }.tint(.indigo)
                    
                    Button(action: {
                        // end the shift, do nothing if on break
                        
                    }){
                        Text("End Shift")
                            .fontDesign(.rounded)
                            .bold()
                            .padding(3)
                        
                    }.tint(context.state.isOnBreak ? .gray : .red)
                    
                    
                    Text(context.state.startTime, style: .timer)
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.trailing)
                        .font(.title)
                        .bold()
                    
                        .foregroundStyle(jobColor)
                     
                
                
            }
        }.padding()
            .background(.ultraThinMaterial)
        
    }
}



struct ShiftTrackerActivityTimerLiveActivity_Previews: PreviewProvider {
    static let attributes = LiveActivityAttributes(jobName: "Apple Incorporated", jobTitle: "CEO", jobIcon: "briefcase.fill", jobColorRed: 0.5, jobColorGreen: 0.1, jobColorBlue: 1.0, hourlyPay: 0)
    static let contentState = LiveActivityAttributes.ContentState(startTime: Date().addingTimeInterval(-3200), totalPay: 220, isOnBreak: false)
    
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
