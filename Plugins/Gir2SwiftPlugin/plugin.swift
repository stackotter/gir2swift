import Foundation
import PackagePlugin

enum Gir2SwiftError: LocalizedError {
    case failedToGetGirNameFromManifest
    case failedToGetGirDirectory(containing: [String])
}

func getGirName(_ target: Target) throws -> String {
    let manifest = target.directory.appending("gir2swift-manifest.yaml")
    let lines = try String(contentsOf: URL(fileURLWithPath: manifest.string)).split(separator: "\n")
    var girName: String? = nil
    for line in lines {
        if line.hasPrefix("gir-name: ") {
            girName = line.dropFirst(10).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    if let girName = girName {
        return girName
    } else {
        throw Gir2SwiftError.failedToGetGirNameFromManifest
    }
}

func getGirDirectory(containing girFiles: [String]) throws -> Path {
    let possibleDirectories = ["/opt/homebrew/share/gir-1.0", "/usr/local/share/gir-1.0", "/usr/share/gir-1.0"].map(Path.init(_:))
    for directory in possibleDirectories {
        let directoryContainsAllGirs = girFiles.allSatisfy { file in
            let path = directory.appending(file).string
            return FileManager.default.fileExists(atPath: path)
        }
        if directoryContainsAllGirs {
            return directory
        }
    }
    throw Gir2SwiftError.failedToGetGirDirectory(containing: girFiles)
}

@main struct Gir2SwiftPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let outputDir = context.pluginWorkDirectory.appending("Gir2SwiftOutputDir")
        try FileManager.default.createDirectory(atPath: outputDir.string, withIntermediateDirectories: true)
        
        let girName = try getGirName(target)
        
        // Determine the list of output files
        let suffixes = ["aliases", "bitfields", "callbacks", "constants", "enumerations", "functions", "unions"]
        var outputFiles = suffixes.map { suffix in
            outputDir.appending("\(girName)-\(suffix).swift")
        }
        
        outputFiles.append(contentsOf: String("A").map { character in
            outputDir.appending("\(girName)-\(character).swift")
        })
        
        outputFiles.append(outputDir.appending("\(girName).swift"))
        
        // Determine the list of input files
        let targetDir = URL(fileURLWithPath: target.directory.string)
        let contents = try FileManager.default.contentsOfDirectory(at: targetDir, includingPropertiesForKeys: nil)
        
        var inputFiles = contents.filter { file in
            file.lastPathComponent.hasPrefix(girName)
        }.map { file in
            Path(file.path)
        }
        
        inputFiles.append(target.directory.appending("gir2swift-manifest.yaml"))
        
        // Find all girs that this library depends on
        let girFiles = target.recursiveTargetDependencies.compactMap {
            try? getGirName($0)
        }.filter {
            $0 != girName
        }.map {
            $0 + ".gir"
        }
        
        let girDirectory = try getGirDirectory(containing: girFiles)
        
        // Construct the arguments
        var arguments = [
            "-o", outputDir.string,
            "--configuration-directory", target.directory.string,
            "--alpha-names"
        ]
        
        arguments.append(contentsOf: girFiles.flatMap { girFile in
            ["-p", girDirectory.appending(girFile).string]
        })
        
        return [.buildCommand(
            displayName: "Running gir2swift",
            executable: try context.tool(named: "gir2swift").path,
            arguments: arguments,
            inputFiles: inputFiles,
            outputFiles: outputFiles
        )]
    }
}
