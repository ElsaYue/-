//
//  pptManage.swift
//  photoPPT
//
//  Created by Figo on 2024/10/26.
//

import SwiftUI
import CoreData

class PPTManager: ObservableObject {
    let viewContext: NSManagedObjectContext
    
    @Published var items: [Item] = []
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        fetchItems()
    }
    
    func fetchItems() {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)]
        
        do {
            items = try viewContext.fetch(request)
        } catch {
            print("获取项目时出错: \(error)")
        }
    }
    
    func addItem() {
        let newItem = Item(context: viewContext)
        newItem.timestamp = Date()
        
        saveContext()
    }
    
    func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            viewContext.delete(item)
        }
        
        saveContext()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
            fetchItems()
        } catch {
            let nsError = error as NSError
            fatalError("未解决的错误 \(nsError), \(nsError.userInfo)")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
