import SwiftUI
import Combine

@MainActor
final class MainViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selectedProject: Project?
    @Published var selectedVersion: Version?
    @Published var selectedFeature: Feature?
    
    // UI State
    @Published var showingAddProject = false
    @Published var showingAddVersion = false
    @Published var showingAddFeature = false
    
    init() {
        refresh()
    }
    
    func refresh() {
        self.projects = LocalFileManager.shared.loadAllProjects()
    }
    
    func clearAllSelections() {
        withAnimation {
            selectedProject = nil
            selectedVersion = nil
            selectedFeature = nil
        }
    }
    
    func selectProject(_ project: Project) {
        withAnimation {
            selectedProject = project
            selectedVersion = nil
            selectedFeature = nil
        }
    }
    
    func addProject(name: String) {
        withAnimation {
            if let newProject = LocalFileManager.shared.createProject(name: name) {
                projects.append(newProject)
                selectedProject = newProject
                objectWillChange.send()
            }
        }
    }
    
    func deleteProject(_ project: Project) {
        withAnimation {
            LocalFileManager.shared.deleteProject(at: project.url)
            if selectedProject?.id == project.id {
                selectedProject = nil
                selectedVersion = nil
                selectedFeature = nil
            }
            projects.removeAll { $0.id == project.id }
            objectWillChange.send()
        }
    }
    
    func addVersion(to project: Project, name: String) {
        withAnimation {
            if let newVersion = LocalFileManager.shared.createVersion(in: project, name: name) {
                if let index = projects.firstIndex(where: { $0.id == project.id }) {
                    projects[index].versions.append(newVersion)
                    selectedVersion = newVersion
                    objectWillChange.send()
                }
            }
        }
    }
    
    func deleteVersion(_ version: Version, in project: Project) {
        withAnimation {
            LocalFileManager.shared.deleteVersion(at: version.url)
            if let pIndex = projects.firstIndex(where: { $0.id == project.id }) {
                projects[pIndex].versions.removeAll { $0.id == version.id }
                
                if selectedVersion?.id == version.id {
                    selectedVersion = nil
                    selectedFeature = nil
                }
                objectWillChange.send()
            }
        }
    }
    
    func deleteFeature(_ feature: Feature, from version: Version) {
        withAnimation {
            LocalFileManager.shared.deleteFeature(at: feature.url)
            if let pIndex = projects.firstIndex(where: { $0.id == selectedProject?.id }),
               let vIndex = projects[pIndex].versions.firstIndex(where: { $0.id == version.id }) {
                projects[pIndex].versions[vIndex].features.removeAll { $0.id == feature.id }
                
                if selectedFeature?.id == feature.id {
                    selectedFeature = nil
                }
                objectWillChange.send()
            }
        }
    }
    
    func addFeature(to version: Version, name: String) {
        withAnimation {
            if let newFeature = LocalFileManager.shared.createFeature(in: version, name: name) {
                if let pIndex = projects.firstIndex(where: { $0.id == selectedProject?.id }),
                   let vIndex = projects[pIndex].versions.firstIndex(where: { $0.id == version.id }) {
                    projects[pIndex].versions[vIndex].features.append(newFeature)
                    selectedFeature = newFeature
                    objectWillChange.send()
                }
            }
        }
    }
}
