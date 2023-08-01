//
//  ShiftsList.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI
import CoreData
import Foundation
import Combine

struct ShiftsList: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var shiftStore: ShiftStore
    
    @EnvironmentObject var savedPublisher: ShiftSavedPublisher
    
    @EnvironmentObject var sortSelection: SortSelection

    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode
    @Environment(\.dismissSearch) private var dismissSearch
    
    @State private var isShareSheetShowing = false
    
    
    @State private var showingAddShiftSheet: Bool = false
    
    
    
    @Binding var navPath: NavigationPath
    
    @State private var selection = Set<NSManagedObjectID>()
    
    
    
    
    var body: some View {
        
        ZStack(alignment: .bottom){
        List(selection: $selection){
            ForEach(sortSelection.filteredShifts.filter { shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) }, id: \.objectID) { shift in
                ZStack {
                    NavigationLink(value: shift) {
                        ShiftDetailRow(shift: shift)
                    }
                    if !sortSelection.searchTerm.isEmpty {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing){
                                if jobSelectionViewModel.fetchJob(in: viewContext) == nil {
                                    Spacer()
                                    
                                }
                                HStack{
                                    Spacer()
                                    
                                    HighlightedText(text: shift.shiftNote ?? "", highlight: sortSelection.searchTerm)
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
                .listRowInsets(.init(top: 10, leading: jobSelectionViewModel.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
                .listRowBackground(Color("SquaresColor"))
                
                .swipeActions {
                    Button(role: .destructive) {
                        shiftStore.deleteOldShift(shift, in: viewContext)
                        
                        if sortSelection.oldShifts.isEmpty {
                            // navigates back if all shifts are deleted
                            navPath.removeLast()
                            
                        }
                        
                    } label: {
                        Image(systemName: "trash")
                    }
                }

            }
            
            // bottom "padding" if the list is long, as the tag picker will overlap 
            
            if sortSelection.filteredShifts.count >= 5 {
                Color.clear
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color("SquaresColor"))
            }

        }.searchable(text: $sortSelection.searchTerm, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Notes")
            
                .onSubmit(of: .search, sortSelection.fetchShifts)
               
            .tint(Color.gray)
            .scrollContentBackground(.hidden)

            .onAppear {
                if navigationState.gestureEnabled || sortSelection.oldShifts.isEmpty {
                    navigationState.gestureEnabled = false
                    sortSelection.fetchShifts()
                }
            }

            TagSortView(selectedFilters: $sortSelection.selectedFilters)
                .padding(.bottom)
                .background {
                    
                    colorScheme == .dark ? Color.black : Color.white
                        
                    
                } //.padding(.top)
                .frame(width: UIScreen.main.bounds.width)
                .frame(maxHeight: 30)
            
                .onChange(of: sortSelection.selectedFilters) { _ in
                    
                    sortSelection.fetchShifts()
                    
                }
        
    }
        
        
        
        
        .navigationBarTitle(sortSelection.selectedSort.name)
        
        
            .toolbar{
                
                ToolbarItemGroup(placement: .keyboard){
                    
                    Spacer()
                    
                    Button("Done"){
                        
                        hideKeyboard()
                        
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing){
                    
                   
                    
                    EditButton()
                    
                    if editMode?.wrappedValue.isEditing == true {
                        
                        Button(action: {
                            CustomConfirmationAlert(action: deleteItems, cancelAction: nil, title: "Are you sure?").showAndStack()
                        }) {
                            Image(systemName: "trash")
                        }.disabled(selection.isEmpty)
                        
                    } else {
                        
                        SortSelectionView(selectedSortItem: $sortSelection.selectedSort, sorts: ShiftNSSort.sorts)
                            .onChange(of: sortSelection.selectedSort) { _ in
                                sortSelection.fetchShifts()
                            }
                        
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

struct TagSortView: View {
    
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Tag.tagID, ascending: true)
        ]
    )
    private var tags: FetchedResults<Tag>
    
    @Binding var selectedFilters: Set<TagFilter>
    

    var body: some View {
        
        let filters = TagFilter.filters(from: Array(tags))
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(filters, id: \.self) { filter in
                    Button(action: {
                        if self.selectedFilters.contains(filter) {
                            self.selectedFilters.remove(filter)
                        } else {
                            self.selectedFilters.insert(filter)
                        }
                    }) {
                        Text("\(filter.name)")
                            .bold()
                            .frame(minWidth: 0, maxWidth: .infinity)

                       
                    }
                    .buttonStyle(.bordered)
                    .tint(filter.color)
                    .opacity(selectedFilters.contains(filter) ? 1.0 : 0.5)
                }
            }
            .padding()
        }
    }
}


class SortSelection: ObservableObject {
    @Published var selectedSort: ShiftNSSort = .default
    
    @Published var selectedFilters: Set<TagFilter> = []
    
    @Published var oldShifts: [OldShift] = []
    @Published var filteredShifts: [OldShift] = []
    
    @Published var searchTerm: String = "" {
        didSet {
            if searchTerm.isEmpty {
                if oldShifts.isEmpty {
                    fetchShifts()
                }
                filteredShifts = oldShifts
            } else {
                filteredShifts = oldShifts.filter {
                    $0.shiftNote?.lowercased().contains(searchTerm.lowercased()) ?? false
                }
            }
        }
    }
    

    private var viewContext: NSManagedObjectContext

    init(in context: NSManagedObjectContext) {
        self.viewContext = context
        fetchShifts()
    }

    
     func fetchShifts() {
        let request = NSFetchRequest<OldShift>(entityName: "OldShift")
        request.sortDescriptors = selectedSort.descriptors
         
         var predicates = selectedFilters.compactMap { $0.predicate }
         
         if !searchTerm.isEmpty {
                 let searchPredicate = NSPredicate(
                     format: "shiftNote contains[cd] %@", searchTerm)
                 predicates.append(searchPredicate)
             }
         
         if !predicates.isEmpty {
             
             request.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
         }

        do {
            try withAnimation{
                oldShifts = try viewContext.fetch(request)
                filteredShifts = oldShifts
            }
        } catch {
            print("Failed to fetch shifts: \(error)")
        }
    }
    
    func commitSearch() {
            fetchShifts() // we only commit full fetch when searching if they submit the search to be more efficient
        }
    
}


struct SortSelectionView: View {
    
    @Binding var selectedSortItem: ShiftNSSort
    let sorts: [ShiftNSSort]
    
    var body: some View {
        Menu {
            
            Picker("Sort", selection: $selectedSortItem){
                ForEach(sorts, id: \.self) { sort in
                    
                    Text("\(sort.name)")
                    
                }
            }
            
            
        } label: {
            
            Label("Sort", systemImage: "line.horizontal.3.decrease.circle")
            
        }
    }
}


struct ShiftNSSort: Hashable, Identifiable {
    let id: Int
    let name: String
    let descriptors: [NSSortDescriptor]

    static let sorts: [ShiftNSSort] = [
        ShiftNSSort(
            id: 0,
            name: "Latest",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)
            ]),
        ShiftNSSort(
            id: 1,
            name: "Oldest",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: true)
            ]),
        ShiftNSSort(
            id: 2,
            name: "Pay | Ascending",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.taxedPay, ascending: false)
            ]),
        ShiftNSSort(
            id: 3,
            name: "Pay | Descending",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.taxedPay, ascending: true)
            ]),
        ShiftNSSort(
            id: 4,
            name: "Longest",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.duration, ascending: false)
            ]),
        ShiftNSSort(
            id: 5,
            name: "Shortest",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.duration, ascending: true)
            ])
    ]

    static var `default`: ShiftNSSort { sorts[0] }
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

class ShiftSavedPublisher: ObservableObject {
    let shiftChanged = PassthroughSubject<Void, Never>()

    func changedShift() {
        shiftChanged.send()
    }
}
