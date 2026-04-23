import SwiftUI
import AppKit

// MARK: - App Logo (SwiftUI Vector)
struct AppLogo: View {
    var size: CGFloat = 40
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.85, height: size * 0.85)
                .shadow(color: .blue.opacity(0.3), radius: size * 0.1, x: 0, y: size * 0.05)
            
            VStack(spacing: (size * 0.85) * 0.1) {
                ForEach(0..<4) { _ in
                    Capsule().fill(Color.white.opacity(0.5)).frame(width: (size * 0.85) * 0.15, height: (size * 0.85) * 0.05)
                }
            }
            .padding(.leading, -(size * 0.85) * 0.35)
            
            Image(systemName: "curlybraces")
                .font(.system(size: (size * 0.85) * 0.45, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Components
struct CircleAddButton: View {
    var color: Color = .blue
    var size: CGFloat = 22
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.gradient)
                    .frame(width: size, height: size)
                    .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .font(.system(size: size * 0.45, weight: .black))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

// MARK: - Main Layout
struct MainLayoutView: View {
    @StateObject private var viewModel = MainViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 350)
        } content: {
            ZStack {
                Color(NSColor.windowBackgroundColor).opacity(0.4).ignoresSafeArea()
                
                if let projectID = viewModel.selectedProject?.id,
                   let project = viewModel.projects.first(where: { $0.id == projectID }) {
                    VersionsColumnView(viewModel: viewModel, project: project)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary.opacity(0.2))
                        Text(appState.currentLanguage == .english ? "Select Project" : "Proje Seçin")
                            .font(.caption).foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            detailViewContent()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                LanguageSwitchButton()
            }
        }
        .sheet(isPresented: $viewModel.showingAddProject) {
            AddSheetView(title: appState.currentLanguage == .english ? "New Project" : "Yeni Proje", placeholder: appState.currentLanguage == .english ? "Project Name" : "Proje Adı", isPresented: $viewModel.showingAddProject) { name in viewModel.addProject(name: name) }
        }
        .sheet(isPresented: $viewModel.showingAddVersion) {
            if let project = viewModel.selectedProject {
                AddSheetView(title: appState.currentLanguage == .english ? "New Version" : "Yeni Versiyon", placeholder: "v1.0.0", isPresented: $viewModel.showingAddVersion) { name in viewModel.addVersion(to: project, name: name) }
            }
        }
        .sheet(isPresented: $viewModel.showingAddFeature) {
            if let version = viewModel.selectedVersion {
                AddSheetView(title: appState.currentLanguage == .english ? "New Feature" : "Yeni Özellik", placeholder: appState.currentLanguage == .english ? "Feature Name" : "Özellik Adı", isPresented: $viewModel.showingAddFeature) { name in viewModel.addFeature(to: version, name: name) }
            }
        }
    }
    
    @ViewBuilder
    private func detailViewContent() -> some View {
        if let projectID = viewModel.selectedProject?.id,
           let project = viewModel.projects.first(where: { $0.id == projectID }) {
            
            if let versionID = viewModel.selectedVersion?.id,
               let version = project.versions.first(where: { $0.id == versionID }) {
                FeatureModuleView(viewModel: viewModel, version: version)
            } else {
                emptyCreationView(title: appState.currentLanguage == .english ? "New Version" : "Yeni Versiyon",
                                 symbol: "tag.fill",
                                 color: .orange) {
                    viewModel.showingAddVersion = true
                }
            }
        } else {
            emptyCreationView(title: appState.currentLanguage == .english ? "New Project" : "Yeni Proje",
                             symbol: "folder.badge.plus",
                             color: .blue) {
                viewModel.showingAddProject = true
            }
        }
    }
    
    private func emptyCreationView(title: String, symbol: String, color: Color, action: @escaping () -> Void) -> some View {
        VStack(spacing: 32) {
            Image(systemName: symbol)
                .font(.system(size: 70))
                .foregroundStyle(color.gradient.opacity(0.3))
            
            VStack(spacing: 16) {
                Text(title).font(.system(.title2, design: .rounded)).fontWeight(.bold)
                CircleAddButton(color: color, size: 44, action: action)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}

// MARK: - Feature Module
struct FeatureModuleView: View {
    @ObservedObject var viewModel: MainViewModel
    @EnvironmentObject var appState: AppState
    let version: Version
    
    @State private var searchText: String = ""
    
    var filteredFeatures: [Feature] {
        if searchText.isEmpty { return version.features }
        return version.features.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(filteredFeatures) { f in
                        Button(action: { 
                            withAnimation { 
                                if viewModel.selectedFeature?.id == f.id { viewModel.selectedFeature = nil }
                                else { viewModel.selectedFeature = f }
                            }
                        }) {
                            Text(f.name)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(viewModel.selectedFeature?.id == f.id ? .bold : .regular)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(viewModel.selectedFeature?.id == f.id ? Color.green.opacity(0.12) : Color.clear)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(viewModel.selectedFeature?.id == f.id ? .green : .secondary)
                        .contextMenu {
                            Button(role: .destructive) { viewModel.deleteFeature(f, from: version) } label: { Label(appState.currentLanguage == .english ? "Delete" : "Sil", systemImage: "trash") }
                        }
                    }
                    
                    Button(action: { viewModel.showingAddFeature = true }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green.opacity(0.08))
                                .frame(width: 22, height: 22)
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 36)
            .background(VisualEffectView(material: .titlebar, blendingMode: .withinWindow)).overlay(Divider(), alignment: .bottom)
            
            if let feature = viewModel.selectedFeature {
                FeatureDetailView(viewModel: viewModel, feature: feature)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text").font(.system(size: 40)).foregroundColor(.secondary.opacity(0.2))
                    Text(appState.currentLanguage == .english ? "No Feature Selected" : "Özellik Seçilmedi")
                        .font(.system(.body, design: .rounded)).foregroundColor(.secondary.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(NSColor.textBackgroundColor))
            }
            
            // Search Bar at the bottom
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                TextField(appState.currentLanguage == .english ? "Search features..." : "Özellikleri ara...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(.caption, design: .rounded))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            .overlay(Divider(), alignment: .top)
        }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @ObservedObject var viewModel: MainViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                AppLogo(size: 28)
                Text("Project Notebook").font(.system(.headline, design: .rounded)).fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal).padding(.vertical, 12)
            
            List {
                ForEach(viewModel.projects) { project in
                    HStack {
                        Label(project.name, systemImage: "folder.fill").foregroundStyle(.blue.gradient).font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 4).padding(.horizontal, 8)
                    .background(viewModel.selectedProject?.id == project.id ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(6).contentShape(Rectangle())
                    .onTapGesture {
                        if viewModel.selectedProject?.id == project.id { viewModel.clearAllSelections() }
                        else { viewModel.selectProject(project) }
                    }
                    .contextMenu {
                        Button(role: .destructive) { viewModel.deleteProject(project) } label: { Label(appState.currentLanguage == .english ? "Delete" : "Sil", systemImage: "trash") }
                    }
                }
            }
            .onTapGesture { viewModel.clearAllSelections() }
            
            // Subtle credit footer
            Text("Arda Yiğit - Hazani")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.3))
                .padding(.bottom, 8)
        }
        .navigationTitle("")
    }
}

// MARK: - Versions
struct VersionsColumnView: View {
    @ObservedObject var viewModel: MainViewModel
    @EnvironmentObject var appState: AppState
    let project: Project
    var body: some View {
        ZStack {
            if project.versions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tag.slash.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text(appState.currentLanguage == .english ? "No Versions" : "Versiyon Yok")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            List {
                ForEach(project.versions) { version in
                    HStack {
                        Label(version.name, systemImage: "tag.fill").foregroundStyle(.orange.gradient).font(.body.weight(.medium))
                        Spacer()
                    }
                    .padding(.vertical, 4).padding(.horizontal, 8)
                    .background(viewModel.selectedVersion?.id == version.id ? Color.orange.opacity(0.1) : Color.clear)
                    .cornerRadius(6).contentShape(Rectangle())
                    .onTapGesture {
                        if viewModel.selectedVersion?.id == version.id { viewModel.selectedVersion = nil; viewModel.selectedFeature = nil }
                        else { viewModel.selectedVersion = version; viewModel.selectedFeature = nil }
                    }
                    .contextMenu {
                        Button(role: .destructive) { viewModel.deleteVersion(version, in: project) } label: { Label(appState.currentLanguage == .english ? "Delete" : "Sil", systemImage: "trash") }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .onTapGesture { viewModel.selectedVersion = nil; viewModel.selectedFeature = nil }
        .navigationTitle(project.name)
    }
}

// MARK: - Features Detail
struct FeatureDetailView: View {
    @ObservedObject var viewModel: MainViewModel
    let feature: Feature
    @State private var content: String = ""
    var body: some View {
        TextEditor(text: $content)
            .font(.system(.body))
            .scrollContentBackground(.hidden).padding()
            .background(Color(NSColor.textBackgroundColor))
            .onChange(of: content) { _, newValue in viewModel.updateFeatureContent(feature, content: newValue) }
            .onAppear { content = feature.content }
            .onChange(of: feature) { _, newFeature in content = newFeature.content }
            .navigationTitle(feature.name)
    }
}

// MARK: - Components Support
struct LanguageSwitchButton: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        Menu {
            ForEach(Language.allCases, id: \.self) { language in
                Button(action: { withAnimation { appState.currentLanguage = language } }) {
                    HStack {
                        Text(language.displayName)
                        if appState.currentLanguage == language { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 11))
                Text(appState.currentLanguage == .english ? "EN" : "TR")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.secondary.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct AddSheetView: View {
    let title: String; let placeholder: String; @Binding var isPresented: Bool; var onAdd: (String) -> Void
    @State private var text: String = ""; @EnvironmentObject var appState: AppState; @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(title).font(.system(.headline, design: .rounded))
                Text(appState.currentLanguage == .english ? "Enter a unique name" : "Benzersiz bir isim girin").font(.caption).foregroundColor(.secondary)
            }
            TextField(placeholder, text: $text).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 260).onSubmit { submit() }
            HStack(spacing: 12) {
                Button(appState.currentLanguage == .english ? "Cancel" : "İptal") { dismiss() }.buttonStyle(.plain).frame(width: 80).keyboardShortcut(.escape, modifiers: [])
                Button(appState.currentLanguage == .english ? "Create" : "Oluştur") { submit() }.buttonStyle(.borderedProminent).controlSize(.regular).frame(width: 100).keyboardShortcut(.defaultAction)
            }
        }
        .padding(28).frame(width: 320).background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow).cornerRadius(16))
    }
    private func submit() { if !text.isEmpty { onAdd(text); dismiss() } }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material; let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView(); view.material = material; view.blendingMode = blendingMode; view.state = .active; return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
