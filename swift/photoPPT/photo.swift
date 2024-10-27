//
//  photo.swift
//  photoPPT
//
//  Created by Figo on 2024/10/26.
//

import SwiftUI
import Combine

struct PhotoItem: Identifiable {
    let id = UUID()
    let image: UIImage
    var title: String
    var description: String
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

struct PhotoView: View {
    @State private var photoItems: [PhotoItem] = []
    @State private var showingImagePicker = false
    @State private var isProcessing = false
    @State private var processingResult: String?
    @State private var scrollProxy: ScrollViewProxy?
    @State private var lastAddedItemID: UUID?
    @State private var itemToDelete: UUID?
    @State private var showingSummary = false
    @State private var summaryText = ""
    @State private var showingResetAlert = false  // 新增：控制重置确认弹窗的显示
    @State private var showingMindMap = false
    @State private var isSummaryMode = true
    @State private var cancellables = Set<AnyCancellable>()
    @State private var alertItem: AlertItem?
    @State private var totalText: String = ""  // 新增：用于存储总文本
    @State private var fullScreenImage: UIImage?  // 新增：用于管理全屏图片
    @State private var isSummarizing = false  // 新增: 用于跟踪总结过程
    @State private var mindMapNodes: [MindMapNode] = []
    @State private var isGeneratingMindMap = false

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        Text("PPT 主题")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 50)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        ForEach(photoItems) { item in
                            PhotoItemView(item: item, itemToDelete: $itemToDelete, onDelete: {
                                deleteItem(id: item.id)
                            }, fullScreenImage: $fullScreenImage)  // 修改：传递 fullScreenImage
                            .id(item.id)
                        }
                        
                        if showingSummary {
                            SummaryView(text: summaryText)
                        }
                        
                        if showingMindMap {
                            MindMapView(nodes: mindMapNodes)
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
                .background(Color(UIColor.systemGray6))
                .edgesIgnoringSafeArea(.all)
                .onAppear { scrollProxy = proxy }
            }
            
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Image(systemName: "archivebox")
                            .font(.title)
                            .padding()
                            .background(Color.black.opacity(0.7))  // 修改为半透明黑色
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding(.leading, 30)
                    .padding(.bottom, 30)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            if isSummaryMode {
                                showingSummary.toggle()
                                if showingSummary && summaryText.isEmpty {
                                    generateSummary()
                                }
                            } else {
                                showingMindMap.toggle()
                                if showingMindMap && mindMapNodes.isEmpty {
                                    generateMindMap()
                                }
                            }
                            isSummaryMode.toggle()
                        }
                    }) {
                        Image(systemName: isSummaryMode ? "list.bullet.clipboard" : "brain.head.profile")
                            .font(.title)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 30)
                }
            }
        }
        .overlay(
            VStack {
                Spacer()
                Button(action: {
                    self.showingImagePicker = true
                }) {
                    Image(systemName: "camera")
                        .font(.largeTitle)
                        .padding()
                        .background(Color.black.opacity(0.7))  // 修改为半透明黑色
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding(.bottom, 30)
            }
        )
        .sheet(isPresented: $showingImagePicker, content: {
            ImagePicker(image: self.$photoItems) { newImage in
                // 立即添加新的 PhotoItem，标题和描述都为空
                let newItem = PhotoItem(image: newImage, title: "", description: "")
                photoItems.append(newItem)
                lastAddedItemID = newItem.id

                processImage(newImage, for: newItem)
            }
        })
        .onChange(of: lastAddedItemID) { id in
            if let id = id {
                withAnimation {
                    scrollProxy?.scrollTo(id, anchor: .center)
                }
            }
        }
        .alert(item: $alertItem) { item in
            Alert(title: Text("处理结果"), message: Text(item.message), dismissButton: .default(Text("确定")))
        }
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text("创建新 PPT 主题"),
                message: Text("确定要创建一个新的 PPT 主题吗？当前主题内容将被保存。"),
                primaryButton: .default(Text("确定")) {
                    createNewTheme()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .overlay(
            Group {
                if isProcessing {
                    ProgressView("正在处理图片...")
                        .padding()
                        .background(Color.secondary.colorInvert())
                        .cornerRadius(10)
                        .shadow(radius: 10)
                } else if isSummarizing {
                    ProgressView("正在生成总结...")
                        .padding()
                        .background(Color.secondary.colorInvert())
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        )
        .sheet(item: Binding(
            get: { fullScreenImage.map { UIImage in FullScreenImageWrapper(image: UIImage) } },
            set: { _ in fullScreenImage = nil }
        )) { wrapper in
            FullScreenImageView(image: wrapper.image, isPresented: Binding(
                get: { fullScreenImage != nil },
                set: { if !$0 { fullScreenImage = nil } }
            ))
        }
    }
    
    private func deleteItem(id: UUID) {
        if let index = photoItems.firstIndex(where: { $0.id == id }) {
            photoItems.remove(at: index)
        }
        itemToDelete = nil
    }
    
    private func resetAlbum() {
        withAnimation {
            photoItems.removeAll()
            showingSummary = false
            summaryText = "这里是总结文本。您可以根据需要修改这段文字，展示相册的总体概况或其他相关信息。"
        }
    }
    
    func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: path)
            return path.path
        } catch {
            print("保存图片失败：\(error.localizedDescription)")
            return nil
        }
    }
    
    private func createNewTheme() {
        withAnimation {
            photoItems.removeAll()
            showingSummary = false
            showingMindMap = false
            summaryText = ""
            isSummaryMode = true
            totalText = ""
            mindMapNodes = []
        }
        
        // 不再设置 summaryText，因为我们不想在创建新主题时显示任何总结
    }
    
    private func generateSummary() {
        if totalText.isEmpty {
            summaryText = "没有足够的内容生成总结。请先添加一些照片。"
            return
        }

        isSummarizing = true
        summaryText = "正在生成总结..."

        NetworkManager.shared.processTextStream(allText: totalText)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isSummarizing = false
                switch completion {
                case .finished:
                    if summaryText == "正在生成总结..." {
                        summaryText = "没有足够的内容生成总结。"
                    }
                case .failure(let error):
                    alertItem = AlertItem(message: "生成总结失败：\(error.localizedDescription)")
                }
            }, receiveValue: { response in
                if summaryText == "正在生成总结..." {
                    summaryText = response
                } else {
                    summaryText += response
                }
            })
            .store(in: &cancellables)
    }
    
    private func processImage(_ newImage: UIImage, for newItem: PhotoItem) {
        isProcessing = true
        if let imageData = newImage.jpegData(compressionQuality: 0.8) {
            NetworkManager.shared.processImageStream(imageData: imageData)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    isProcessing = false
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        alertItem = AlertItem(message: "处理失败：\(error.localizedDescription)")
                    }
                }, receiveValue: { response in
                    // 更新描述为接收到的文本
                    if let index = photoItems.firstIndex(where: { $0.id == newItem.id }) {
                        photoItems[index].description += response
                    }
                    // 将新的响应文本添加到总文本中
                    totalText += response
                })
                .store(in: &cancellables)
        } else {
            isProcessing = false
            alertItem = AlertItem(message: "图片处理失败")
        }
    }
    
    private func generateMindMap() {
        isGeneratingMindMap = true
        mindMapNodes = []  // 清空现有的思维导图节点

        NetworkManager.shared.processKeyword(allText: totalText)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isGeneratingMindMap = false
                switch completion {
                case .finished:
                    if mindMapNodes.isEmpty {
                        // 如果没有生成任何节点,显示一个提示
                        mindMapNodes = [MindMapNode(title: "没有足够的内容生成思维导图", children: [])]
                    }
                case .failure(let error):
                    alertItem = AlertItem(message: "生成思维导图失败：\(error.localizedDescription)")
                }
            }, receiveValue: { result in
                mindMapNodes = parseMindMap(result)
            })
            .store(in: &cancellables)
    }

    private func parseMindMap(_ text: String) -> [MindMapNode] {
        var nodes: [MindMapNode] = []
        var currentMainNode: MindMapNode?
        
        let lines = text.split(separator: "\n")
        for line in lines {
            if line.starts(with: "一、") || line.starts(with: "二、") || line.starts(with: "三、") || line.starts(with: "四、") || line.starts(with: "五、") {
                if let currentNode = currentMainNode {
                    nodes.append(currentNode)
                }
                currentMainNode = MindMapNode(title: String(line), children: [])
            } else if line.contains("、"), let currentNode = currentMainNode {
                let childNode = MindMapNode(title: String(line), children: [])
                currentMainNode?.children.append(childNode)
            }
        }
        
        if let lastNode = currentMainNode {
            nodes.append(lastNode)
        }
        
        return nodes
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: [PhotoItem]
    var completion: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.completion(uiImage)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PhotoView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoView()
    }
}

// 发送图片到服务器的函数（示例）
func sendImageToServer(_ imageData: Data) {
    // 这里实现发送图片数据到服务器的逻辑
    // 例如使用URLSession进行网络请求
}

struct PhotoItemView: View {
    let item: PhotoItem
    @Binding var itemToDelete: UUID?
    let onDelete: () -> Void
    @Binding var fullScreenImage: UIImage?
    
    @State private var isShowingDeleteButton = false
    @State private var selectedText: String = ""
    @State private var isShowingQueryOptions = false
    @State private var textMeaning: String = ""
    @State private var isLoadingMeaning = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(uiImage: item.image)
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .cornerRadius(15)
                .padding(.horizontal, 20)
                .onTapGesture {
                    fullScreenImage = item.image
                }
            
            Text(item.title)
                .font(.title)
                .padding(.top)
                .padding(.horizontal)
            
            SelectableTextView(text: item.description, selectedText: $selectedText, isShowingQueryOptions: $isShowingQueryOptions)
                .frame(height: 200)
                .padding()
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.vertical)
        .padding(.horizontal, 16)
        .overlay(deleteButton)
        .onLongPressGesture {
            withAnimation {
                isShowingDeleteButton.toggle()
            }
        }
        .overlay(queryOptionsOverlay)
        .sheet(isPresented: $isShowingQueryOptions) {
            MeaningView(text: selectedText, meaning: $textMeaning, isLoading: $isLoadingMeaning)
        }
    }
    
    private var deleteButton: some View {
        Group {
            if isShowingDeleteButton {
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation {
                                isShowingDeleteButton = false
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        Spacer()
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    private var queryOptionsOverlay: some View {
        Group {
            if isShowingQueryOptions {
                VStack {
                    Spacer()
                    HStack {
                        Button("查询") {
                            lookupSelectedText()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .padding()
            }
        }
    }
    
    private func lookupSelectedText() {
        isLoadingMeaning = true
        textMeaning = "正在加载..."
        isShowingQueryOptions = true
        
        NetworkManager.shared.processTextMeaningStream(text: selectedText)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoadingMeaning = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    textMeaning = "查询失败: \(error.localizedDescription)"
                }
            }, receiveValue: { result in
                if textMeaning == "正在加载..." {
                    textMeaning = result
                } else {
                    textMeaning += result
                }
            })
            .store(in: &cancellables)
    }
}

struct MeaningView: View {
    let text: String
    @Binding var meaning: String
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("查询结果")
                .font(.headline)
            
            Text("原文: \(text)")
                .font(.subheadline)
            
            if isLoading {
                ProgressView("正在加载...")
            } else {
                Text(meaning)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
    }
}

struct SelectableTextView: UIViewRepresentable {
    let text: String
    @Binding var selectedText: String
    @Binding var isShowingQueryOptions: Bool
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.text = text
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SelectableTextView
        
        init(_ parent: SelectableTextView) {
            self.parent = parent
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            if let selectedRange = textView.selectedTextRange {
                parent.selectedText = textView.text(in: selectedRange) ?? ""
                parent.isShowingQueryOptions = !parent.selectedText.isEmpty
            } else {
                parent.selectedText = ""
                parent.isShowingQueryOptions = false
            }
        }
    }
}

struct SummaryView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("总结")
                .font(.title)
                .fontWeight(.bold)
            
            Text(text)
                .font(.body)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)  // 添加这行
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.vertical)
        .padding(.horizontal, 16)
    }
}

struct MindMapNode: Identifiable {
    let id = UUID()
    let title: String
    var children: [MindMapNode]
}

struct MindMapView: View {
    let nodes: [MindMapNode]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("思维导图")
                .font(.title)
                .fontWeight(.bold)
            
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(nodes) { node in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(node.title)
                                .font(.headline)
                            ForEach(node.children) { child in
                                Text(child.title)
                                    .padding(.leading)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.vertical)
        .padding(.horizontal, 16)
    }
}

// 新增：全屏图片视图
struct FullScreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .edgesIgnoringSafeArea(.all)
        }
        .onTapGesture {
            isPresented = false
        }
    }
}

// 新增：用于包装 UIImage 以便在 sheet 中使用
struct FullScreenImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

