import Foundation
import PackagePlugin

@main struct Gir2SwiftPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let outputDir = context.pluginWorkDirectory.appending("Gir2SwiftOutputDir")
        try FileManager.default.createDirectory(atPath: outputDir.string, withIntermediateDirectories: true)
        
        let suffixes = ["@", "aliases", "bitfields", "callbacks", "constants", "enumerations", "functions", "unions"]
        var outputFiles = suffixes.map { suffix in
            outputDir.appending("GLib-2.0-\(suffix).swift")
        }
        
        outputFiles.append(contentsOf: "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { character in
            outputDir.appending("GLib-2.0-\(character).swift")
        })
        
        outputFiles.append(outputDir.appending("GLib-2.0.swift"))
        
        let inputFiles = [
            "GLib-2.0-2.62.0.awk",
            "GLib-2.0-2.62.0.sed",
            "GLib-2.0.awk",
            "GLib-2.0.blacklist",
            "GLib-2.0.module",
            "GLib-2.0.override",
            "GLib-2.0.preamble",
            "GLib-2.0.sed",
            "GLib-2.0.verbatim",
            "GLib-2.0<=2.60.0.sed",
            "gir2swift-manifest.yaml"
        ].map {
            context.package.directory.appending($0)
        }
        
        return [.buildCommand(
            displayName: "Running gir2swift",
            executable: try context.tool(named: "gir2swift").path,
            arguments: [
                "-o", outputDir.string,
                "--configuration-directory", context.package.directory,
                "--alpha-names"
            ],
            inputFiles: inputFiles,
            outputFiles: outputFiles
        )]
    }
}
