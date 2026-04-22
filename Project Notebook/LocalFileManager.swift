import Foundation

final class LocalFileManager {
    static let shared = LocalFileManager()
    
    private let rootFolder: URL
    
    private init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        rootFolder = paths[0].appendingPathComponent("Project Notebook", isDirectory: true)
        createDirectoryIfNeeded(rootFolder)
    }
    
    private func createDirectoryIfNeeded(_ url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    func createProject(name: String) -> Project? {
        let projectURL = rootFolder.appendingPathComponent(name, isDirectory: true)
        createDirectoryIfNeeded(projectURL)
        return Project(name: name, url: projectURL)
    }
    
    func deleteProject(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    func createVersion(in project: Project, name: String) -> Version? {
        let versionURL = project.url.appendingPathComponent(name, isDirectory: true)
        createDirectoryIfNeeded(versionURL)
        return Version(name: name, url: versionURL)
    }
    
    func deleteVersion(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    func deleteFeature(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    func createFeature(in version: Version, name: String) -> Feature? {
        let fileName = name.lowercased().hasSuffix(".txt") ? name : "\(name).txt"
        let fileURL = version.url.appendingPathComponent(fileName)
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try? "".write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        return Feature(name: name, url: fileURL)
    }
    
    func saveFeatureContent(feature: Feature, content: String) {
        try? content.write(to: feature.url, atomically: true, encoding: .utf8)
    }
    
    func loadAllProjects() -> [Project] {
        guard let items = try? FileManager.default.contentsOfDirectory(at: rootFolder, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return items.compactMap { url in
            guard url.hasDirectoryPath else { return nil }
            var project = Project(name: url.lastPathComponent, url: url)
            project.versions = loadVersions(for: project)
            return project
        }
    }
    
    private func loadVersions(for project: Project) -> [Version] {
        guard let items = try? FileManager.default.contentsOfDirectory(at: project.url, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return items.compactMap { url in
            guard url.hasDirectoryPath else { return nil }
            var version = Version(name: url.lastPathComponent, url: url)
            version.features = loadFeatures(for: version)
            return version
        }
    }
    
    private func loadFeatures(for version: Version) -> [Feature] {
        guard let items = try? FileManager.default.contentsOfDirectory(at: version.url, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return items.compactMap { url in
            guard !url.hasDirectoryPath, url.pathExtension == "txt" else { return nil }
            let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            return Feature(name: url.deletingPathExtension().lastPathComponent, url: url, content: content)
        }
    }
}
