//
//  ShiftsList.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI
import CoreData
import Foundation

struct ShiftsList: View {
    
    // @StateObject var temporaryViewModel = ContentViewModel()
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @EnvironmentObject var shiftManager: ShiftDataManager
    
    
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode
    
    @State private var isShareSheetShowing = false
    
    @State private var searchTerm = ""
    
    @State private var showingAddShiftSheet: Bool = false
    
    var searchQuery: Binding<String> {
        Binding {
            searchTerm
        } set: { newValue in
            searchTerm = newValue
            
            var predicates = Array(selectedFilters.compactMap { $0.predicate })
            
            if !newValue.isEmpty {
                let searchPredicate = NSPredicate(
                    format: "shiftNote contains[cd] %@",
                    newValue)
                predicates.append(searchPredicate)
            }
            
            if predicates.isEmpty {
                shifts.nsPredicate = nil
            } else {
                shifts.nsPredicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
            }
        }
    }
    
    
    
    @FetchRequest(
        sortDescriptors: ShiftSort.default.descriptors,
        predicate: nil,
        animation: .default)
    private var shifts: FetchedResults<OldShift>
    
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Tag.tagID, ascending: true)
        ]
    )
    private var tags: FetchedResults<Tag>
    
    
    @State private var selectedSort = ShiftSort.default
    @State private var selectedFilters: Set<TagFilter> = [TagFilter(id: 0, name: "All", predicate: nil)]
    
    @Binding var navPath: NavigationPath
    
    @State private var selection = Set<NSManagedObjectID>()
    
    
    
    var body: some View {
        
        
        
        List(selection: $selection){
            
            ForEach(shifts.filter { shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) }, id: \.objectID) { shift in
                
                ZStack {
                    NavigationLink(value: shift) {
                        ShiftDetailRow(shift: shift)
                    }
                    
                    if !searchTerm.isEmpty {
                        
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing){
                                
                                if jobSelectionViewModel.fetchJob(in: viewContext) == nil {
                                    Spacer()
                                    
                                }
                                
                                
                                HStack{
                                    Spacer()
                                    
                                    HighlightedText(text: shift.shiftNote ?? "", highlight: searchTerm)
                                        .padding(.vertical, jobSelectionViewModel.fetchJob(in: viewContext) == nil ? 2 : 5)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(6)
                                        .padding(.bottom, jobSelectionViewModel.fetchJob(in: viewContext) == nil ? 5 : 0)
                                        .padding(.trailing, jobSelectionViewModel.fetchJob(in: viewContext) == nil ? 0 : 12)
                                }
                                
                                
                                
                                
                            }.frame(maxWidth: 180)
                                .frame(alignment: .trailing)
                            
                            
                        }
                    }
                }
                
                
                
                
             /*   .navigationDestination(for: OldShift.self) { shift in
                    DetailView(shift: shift, presentedAsSheet: false, navPath: $navPath).navigationBarTitle(jobSelectionViewModel.fetchJob(in: viewContext) == nil ? (shift.job?.name ?? "Shift Details") : "Shift Details")
                    
                } */
                
                .listRowInsets(.init(top: 10, leading: jobSelectionViewModel.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
                .listRowBackground(Color("SquaresColor"))
                
                .swipeActions {
                    Button(role: .destructive) {
                        shiftManager.deleteShift(shift, in: viewContext)
                        
                        if shifts.isEmpty {
                            // navigates back if all shifts are deleted
                            navPath.removeLast()
                            
                        }
                        
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                
                
                
            }
            
        }.searchable(text: searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Notes")
            .tint(Color.gray)
            .scrollContentBackground(.hidden)
        
        
            .onAppear {
                navigationState.gestureEnabled = false
                
            }
        
        
        
        
            .navigationBarTitle(selectedSort.name)
        
        
            .toolbar{
                
                
                
                ToolbarItem(placement: .navigationBarTrailing){
                    
                    
                    if editMode?.wrappedValue.isEditing == true {
                        
                        Button(action: {
                            CustomConfirmationAlert(action: deleteItems, cancelAction: nil, title: "Are you sure?").showAndStack()
                        }) {
                            Image(systemName: "trash")
                        }.disabled(selection.isEmpty)
                        
                    }
                    
                    
                }
                
                
                ToolbarItem(placement: .navigationBarTrailing){
                    
                    EditButton()
                    
                    
                }
                
                ToolbarItem(placement: .navigationBarTrailing){
                    
                    Menu {
                        
                        Menu {
                            Picker("Sort By", selection: $selectedSort) {
                                ForEach(ShiftSort.sorts, id: \.self) { sort in
                                    Text("\(sort.name)")
                                }
                            }
                        } label: {
                            Label(
                                "Sort",
                                systemImage: "line.horizontal.3.decrease.circle")
                        }
                        .disabled(!selection.isEmpty)
                        .onChange(of: selectedSort) { _ in
                            let request = shifts
                            request.sortDescriptors = selectedSort.descriptors
                        }
                        
                        Menu {
                            ForEach(TagFilter.filters(from: Array(tags)), id: \.self) { filter in
                                Toggle(isOn: Binding(
                                    get: {
                                        if filter.name == "All" {
                                            return self.selectedFilters.count == 1 && self.selectedFilters.contains(filter)
                                        } else {
                                            return self.selectedFilters.contains(filter)
                                        }
                                    },
                                    set: { _ in
                                        if filter.name == "All" {
                                            self.selectedFilters = [filter]
                                        } else {
                                            if self.selectedFilters.contains(filter) {
                                                self.selectedFilters.remove(filter)
                                            } else {
                                                self.selectedFilters.insert(filter)
                                                // If "All" is in the set, remove it when another filter is added
                                                self.selectedFilters.remove(TagFilter(id: 0, name: "All", predicate: nil))
                                            }
                                        }
                                    })) {
                                        Text("\(filter.name)")
                                    }
                            }
                        } label: {
                            Label(
                                "Tag",
                                systemImage: "number.circle")
                        }
                        .disabled(!selection.isEmpty)
                        
                        .onChange(of: selectedFilters) { newValue in
                            let predicates = newValue.compactMap { $0.predicate } // 1. filter out `nil` predicates
                            if predicates.isEmpty {
                                let request = shifts
                                request.nsPredicate = nil // reset predicate if no filters are selected
                            } else {
                                let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: predicates) // 2. use `.and` instead of `.or`
                                let request = shifts
                                request.nsPredicate = compoundPredicate
                            }
                        }
                        
                        
                        
                        
                    } label: {
                        
                        
                        
                        Image(systemName: "ellipsis.circle")
                        
                    }
                }
                
                
            }
        
    }
    
    private func deleteItems() {
        withAnimation {
            selection.forEach { objectID in
                let itemToDelete = viewContext.object(with: objectID)
                viewContext.delete(itemToDelete)
            }
            
            do {
                try viewContext.save()
                selection.removeAll()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    
    
    
}

struct ShiftSort: Hashable, Identifiable {
    let id: Int
    let name: String
    let descriptors: [SortDescriptor<OldShift>]
    
    
    static let sorts: [ShiftSort] = [
        ShiftSort(
            id: 0,
            name: "Latest",
            descriptors: [
                SortDescriptor(\OldShift.shiftStartDate, order: .reverse)
            ]),
        ShiftSort(
            id: 1,
            name: "Oldest",
            descriptors: [
                SortDescriptor(\OldShift.shiftStartDate, order: .forward)
            ]),
        ShiftSort(
            id: 2,
            name: "Pay | Ascending",
            descriptors: [
                SortDescriptor(\OldShift.taxedPay, order: .reverse)
            ]),
        ShiftSort(
            id: 3,
            name: "Pay | Descending",
            descriptors: [
                SortDescriptor(\OldShift.taxedPay, order: .forward)
            ]),
        ShiftSort(
            id: 4,
            name: "Longest",
            descriptors: [
                SortDescriptor(\OldShift.duration, order: .reverse)
            ]),
        ShiftSort(
            id: 5,
            name: "Shortest",
            descriptors: [
                SortDescriptor(\OldShift.duration, order: .forward)
            ])
    ]
    
    // 4
    static var `default`: ShiftSort { sorts[0] }
    
    
}

struct TagFilter: Hashable, Identifiable, Equatable {
    let id: Int
    let name: String
    let predicate: NSPredicate?
    
    static func filters(from tags: [Tag]) -> [TagFilter] {
        let allFilter = TagFilter(id: 0, name: "All", predicate: nil)
        let tagFilters = tags.enumerated().map { (index: Int, tag: Tag) -> TagFilter in
            TagFilter(id: index + 1,
                      name: "#\(tag.name ?? "Unknown")",
                      predicate: NSPredicate(format: "ANY tags.tagID == %@", tag.tagID! as CVarArg))
        }
        return [allFilter] + tagFilters
    }
}


struct HighlightedText: View {
    let text: String
    let highlight: String
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if let parts = highlightSnippet(in: text, highlight: highlight) {
            HStack(spacing: 0) {
                Text("..")
                    .font(jobSelectionViewModel.fetchJob(in: viewContext) != nil ? .callout : .caption)
                    .bold()
                ForEach(parts, id: \.0) { part, isHighlighted in
                    if isHighlighted {
                        Text(part)
                            .bold()
                            .font(jobSelectionViewModel.fetchJob(in: viewContext) != nil ? .callout : .caption)
                            .foregroundStyle(.black)
                            .background(Color.yellow.opacity(0.8))
                            .cornerRadius(4)
                    } else {
                        Text(part)
                            .font(jobSelectionViewModel.fetchJob(in: viewContext) != nil ? .callout : .caption)
                            .bold()
                            .font(.caption)
                    }
                }
                Text("..")
                    .font(jobSelectionViewModel.fetchJob(in: viewContext) != nil ? .callout : .caption)
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
