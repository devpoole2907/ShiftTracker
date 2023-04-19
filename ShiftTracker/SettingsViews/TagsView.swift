//
//  TagsView.swift
//  ShiftTracker
//
//  Created by James Poole on 4/04/23.
//

import SwiftUI



struct TagsView: View {
    @AppStorage("tagList") private var tagsList: Data = Data()
    @State private var tags: [Tag] = []
    @State private var newTag: String = ""
    @State private var selectedColorName: String = "red"

    var body: some View {
        NavigationView {
            VStack {
                VStack {

                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 35)
                            .overlay(
                                HStack {
                                    Image(systemName: "tag")
                                        .foregroundColor(.white.opacity(0.4))
                                        //.padding()
                                    TextField("New tag", text: $newTag)
                                }
                                    .foregroundColor(.white)
                                    .padding()
                            )
                            .padding([.leading, .trailing], 60)
                    HStack {
                        ForEach(["red", "green", "blue", "orange", "purple", "indigo"], id: \.self) { colorName in
                            Color(colorName)
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                .onTapGesture {
                                    selectedColorName = colorName
                                }
                        }
                    }.padding()
                }
                List {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag.name)
                            Spacer()
                            Circle()
                                .frame(width: 16, height: 16)
                                .foregroundColor(Color(tag.colorName))
                        }
                    }
                    .onDelete(perform: deleteTag)
                }.listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                .toolbar{
                    ToolbarItem{
                        Button(action: {
                            addTag()
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .onAppear(perform: loadData)
            
        }
        
    }

    func addTag() {
        guard !newTag.isEmpty else { return }
        let tag = Tag(name: newTag, colorName: selectedColorName)
        tags.append(tag)
        newTag = ""
        saveData()
    }

    func loadData() {
        if let decodedData = try? JSONDecoder().decode([Tag].self, from: tagsList) {
            tags = decodedData
        }
    }

    func saveData() {
        if let encodedData = try? JSONEncoder().encode(tags) {
            tagsList = encodedData
        }
    }
    
    func deleteTag(at offsets: IndexSet) {
            tags.remove(atOffsets: offsets)
            saveData()
        }
}



struct TagsView_Previews: PreviewProvider {
    static var previews: some View {
        TagsView()
    }
}
