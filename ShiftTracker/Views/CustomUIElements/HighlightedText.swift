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
                ForEach(parts, id: \.0) { part, isHighlighted in
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
        let parts = fullText.lowercased().components(separatedBy: lowercasedHighlight)
        
        for (i, part) in parts.enumerated() {
            if i != parts.count - 1 {
                if let partRange = fullText.range(of: part, options: .caseInsensitive),
                   let endIndex = fullText.index(partRange.upperBound, offsetBy: lowercasedHighlight.count, limitedBy: fullText.endIndex) {
                    let nextPart = String(fullText[partRange.upperBound..<endIndex])
                    separatedText.append((part, false))
                    separatedText.append((nextPart, true))
                } else if part.isEmpty {
                    // Special case when the highlight is at the start
                    let startIndex = fullText.startIndex
                    if let endIndex = fullText.index(startIndex, offsetBy: lowercasedHighlight.count, limitedBy: fullText.endIndex) {
                        let nextPart = String(fullText[startIndex..<endIndex])
                        separatedText.append((nextPart, true))
                    }
                }
            } else {
                separatedText.append((part, false))
            }
        }
        
        return separatedText
    }
    
    
    
    
    
    
}
