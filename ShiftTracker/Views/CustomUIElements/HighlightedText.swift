//
//  HighlightedText.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import SwiftUI

struct HighlightedText: View {
    let text: String
    let highlight: String
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if let parts = highlightSnippet(in: text, highlight: highlight) {
            HStack(spacing: 0) {
                Text("..")
                    .font(selectedJobManager.fetchJob(in: viewContext) != nil ? .callout : .caption)
                    .bold()
                ForEach(parts.indices, id: \.self) { index in
                    
                    let (part, isHighlighted) = parts[index]
                    
                    if isHighlighted {
                        Text(part)
                            .bold()
                            .font(selectedJobManager.fetchJob(in: viewContext) != nil ? .callout : .caption)
                            .foregroundStyle(.black)
                            .background(Color.yellow.opacity(0.8))
                            .cornerRadius(4)
                    } else {
                        Text(part)
                            .font(selectedJobManager.fetchJob(in: viewContext) != nil ? .callout : .caption)
                            .bold()
                            .font(.caption)
                    }
                }
                Text("..")
                    .font(selectedJobManager.fetchJob(in: viewContext) != nil ? .callout : .caption)
                    .bold()
            }.lineLimit(1)
                .padding(.horizontal, 10)
        }
    }
    
    
    
    func highlightSnippet(in text: String, highlight: String) -> [(String, Bool)]? {
        
        print("Full Text: \(text)")
        print("Highlight: \(highlight)")

        
        guard let range = text.range(of: highlight, options: .caseInsensitive) else {
            return nil
        }
        
        let start = text.index(range.lowerBound, offsetBy: -2, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: 5, limitedBy: text.endIndex) ?? text.endIndex
        
        let snippet = text[start..<end]
        
        return separateText(String(snippet), highlight: highlight)
    }
    
    
    func separateText(_ fullText: String, highlight: String) -> [(String, Bool)] {
        var separatedText: [(String, Bool)] = []
        let lowercasedHighlight = highlight.lowercased()
        let lowercasedFullText = fullText.lowercased()
        
        var lastIndex = fullText.startIndex
        
        while let range = lowercasedFullText.range(of: lowercasedHighlight, range: lastIndex..<fullText.endIndex) {
            let preText = String(fullText[lastIndex..<range.lowerBound])
            let highlightedText = String(fullText[range])
            
            if !preText.isEmpty {
                separatedText.append((preText, false))
            }
            
            separatedText.append((highlightedText, true))
            
            lastIndex = range.upperBound
        }
        
        let postText = String(fullText[lastIndex..<fullText.endIndex])
        
        if !postText.isEmpty {
            separatedText.append((postText, false))
        }
        
        return separatedText
    }

    
    
    
    
    
    
    
    
}
