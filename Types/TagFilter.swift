//
//  TagFilter.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import Foundation
import SwiftUI

struct TagFilter: Hashable, Identifiable, Equatable {
    let id: Int
    let name: String
    let predicate: NSPredicate?
    let color: Color
    
    static func filters(from tags: [Tag]) -> [TagFilter] {
        let tagFilters = tags.enumerated().map { (index: Int, tag: Tag) -> TagFilter in
            TagFilter(id: index + 1,
                      name: "#\(tag.name ?? "Unknown")",
                      predicate: NSPredicate(format: "ANY tags.tagID == %@", tag.tagID! as CVarArg), color: Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue))
        }
        return tagFilters
    }
}
