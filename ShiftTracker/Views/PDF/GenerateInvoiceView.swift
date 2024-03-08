//
//  GenerateInvoiceView.swift
//  ShiftTracker
//
//  Created by James Poole on 8/03/24.
//

import SwiftUI
import CoreData

struct GenerateInvoiceView: View {
    
    @ObservedObject var viewModel: InvoiceViewModel
    
    @State var username = ""
    
    init(shifts: FetchedResults<OldShift>? = nil, job: Job? = nil, selectedShifts: Set<NSManagedObjectID>? = nil, arrayShifts: [OldShift]? = nil, singleExportShift: OldShift? = nil) {
        self.viewModel = InvoiceViewModel(shifts: shifts, selectedShifts: selectedShifts, job: job, viewContext: PersistenceController.shared.container.viewContext, arrayShifts: arrayShifts, singleExportShift: singleExportShift)
    }
    
    
    
    var body: some View {
        
        NavigationStack {
            
            ZStack(alignment: .bottom) {
            
            ScrollView {
                
                VStack {
                    
                    TextField("Your name", text: $username)
                    TextField("Street address", text: $username)
                    
              
                    
                    
                }.padding()
                    .glassModifier()
                    .padding()
                
                
            }
                
                ShareLink(item: render(), label: {
                    
                    
                    
                    VStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up.fill")//.customAnimatedSymbol(value: $isActionButtonTapped)
                        //  .foregroundColor(textColor)
                        Text("Export")
                            .font(.subheadline)
                            .bold()
                        //  .foregroundColor(textColor)
                    }
                    .padding(.horizontal, 25)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .glassModifier(cornerRadius: 20, darker: true)
                    //.haptics(onChangeOf: isActionButtonTapped, type: .success)
                }).padding(.horizontal)
            
        }
            
        .toolbar{
            CloseButton()
        }
            
        
        .navigationTitle("Generate Invoice")
        .navigationBarTitleDisplayMode(.inline)
    }
        
        
    //
        
    }
    
    @MainActor func render() -> URL {
        
        let renderer = ImageRenderer(content: InvoiceView().environmentObject(viewModel))
        
      //  let a4Size = CGSize(width: 595, height: 842)
        
        
        
        
        let url = URL.documentsDirectory.appending(path: "output.pdf")
        
        renderer.render { size, renderer in
                   // 4: Tell SwiftUI our PDF should be the same size as the views we're rendering
       //     var box = CGRect(origin: .zero, size: a4Size)
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            guard let consumer = CGDataConsumer(url: url as CFURL), let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil)
            else {
                return
            }
                   // 5: Create the CGContext for our PDF pages
                   

                   // 6: Start a new PDF page
                   pdfContext.beginPDFPage(nil)
            pdfContext.translateBy(x: box.size.width / 2 - size.width / 2,
                                                   y: box.size.height / 2 - size.height / 2)
            
          //  pdfContext.scaleBy(x: 1.2, y: 1.2)

                   // 7: Render the SwiftUI view data onto the page
                   renderer(pdfContext)

                   // 8: End the page and close the file
                   pdfContext.endPDFPage()
                   pdfContext.closePDF()
               }
        
        return url
        
    }
    
    
}

struct InvoiceView: View {
    
    // only show totals on last page
    var isLastPage: Bool = true
    
    @EnvironmentObject var viewModel: InvoiceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            HStack {
                UserDetailsView().padding([.trailing, .bottom])
                // for pdf gen
               Spacer(minLength: 200)
                // for swiftui preview
               // Spacer()
                InvoiceDetailsView().padding(.bottom)
            }
            
            ClientDetailsView()
            
            InvoiceTableView(tableCells: viewModel.tableCells)
            
            Spacer()
            
            if isLastPage {
                
                TotalPayView(totalPay: viewModel.totalPay)//.padding(.leading)
                
            }
            
            Spacer()
        }.padding(20)
            .background(Color.white)//.ignoresSafeArea()
         //   .ignoresSafeArea()
        
          
        
    }
}

struct UserDetailsView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Your name").bold().font(.subheadline)
            Text("Street address")
            Text("Address line 2")
            Text("Country")
        }.font(.system(size: 8))
    }
    
}

struct ClientDetailsView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Invoice to").foregroundStyle(.white).padding(.horizontal).background(Color.black.opacity(0.5)).padding(.vertical, 2).font(.caption)
            Text("Client name")
            Text("Street address")
            Text("Address line 2")
            Text("Country")
        }.font(.system(size: 8))
    }
    
}

struct InvoiceDetailsView: View {
    
    var body: some View {
        
        VStack(alignment: .trailing, spacing: 2){
            Text("Invoice").bold().font(.subheadline)
            Text("Invoice No: IN00007")
            Text("Invoice date: \(Date().formatted())")
            Text("Due date: \(Date().formatted())")
        }.font(.system(size: 8))
    }
    
}

struct TotalPayView: View {
    
    var totalPay: Double
    
    var body: some View {
        
        VStack(alignment: .trailing, spacing: 5) {
            Divider()
            Text("Subtotal: $130.00")
            Text("GST (18.50%): $24.05")
            Text("Total: $\(totalPay)").bold()
        }.font(.system(size: 8))
        
    }
    
}

struct InvoiceTableView: View {
    
    var tableCells: [ShiftTableCell]
    
    let shiftManager = ShiftDataManager()
    
    var body: some View {
        
       
                    Grid {
                        GridRow {
                            Text("Date")
                            Text("Hours")
                            Text("Rate")
                            Text("Cost")
                        }
                        .bold()
                        Divider()
                        ForEach(tableCells) { cell in
                            GridRow {
                                
                                Text("\(cell.date.formatted(date: .abbreviated, time: .omitted))")
                                
                                    Text("\(shiftManager.formatTime(timeInHours: cell.duration / 3600))")
                                Text(cell.rate, format: .currency(code: "NZD"))
                                Text(cell.pay, format: .currency(code: "NZD"))
                                
                            }
                            
                        }
                    }.font(.system(size: 8))
                .foregroundStyle(.black)
       
        
    }
    
}

#Preview {
    InvoiceView()
}

struct ShiftTableCell: Identifiable {
    
    var id = UUID()
    // this needs to reduce any break duration
    var date: Date
    var duration: TimeInterval
    var rate: Double
    var pay: Double
    
    
}
