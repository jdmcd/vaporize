import Console
import Foundation

public final class View: Command {
    public let id = "view"
    
    public let signature: [Argument] = [
        
    ]
    
    public let help: [String] = [
        "Creates a view",
        "Use with the following format:",
        "view <viewName> <title>"
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        do {
            let currentPath = FileManager.default.currentDirectoryPath
            let packageFilePath = currentPath + "/Package.swift"
            
            if !FileManager.default.fileExists(atPath: packageFilePath) {
                throw ErrorCase.generalError("This is not a Vapor project. Please execute Vaporize in a Vapor project")
            }
            
            let directoryOfTemplates = "\(NSHomeDirectory())/.vaporize"
            let controllerFile = "\(directoryOfTemplates)/view.leaf"
            
            //require a name and the page title
            var args = arguments
            if args.count != 2 {
                throw ConsoleError.insufficientArguments
            }
            
            let viewName = args[0]
            let pageTitle = args[1]
            
            //initial changing of the file
            let contentsOfViewFile = try String(contentsOfFile: controllerFile)
            var filledInViewFile = contentsOfViewFile
            filledInViewFile = filledInViewFile.replacingOccurrences(of: .title, with: pageTitle)
            
            let writePath = "\(currentPath)/Resources/Views/\(viewName).leaf"
            
            try filledInViewFile.write(toFile: writePath, atomically: true, encoding: .utf8)
            
            console.success("\(viewName).leaf located at \(writePath)", newLine: true)
        } catch {
            console.error(error.localizedDescription, newLine: true)
        }
    }
}

enum ViewKey: String {
    case title = "VAR_TITLE"
}

fileprivate extension String {
    func replacingOccurrences(of: ViewKey, with: String) -> String {
        return replacingOccurrences(of: of.rawValue, with: with)
    }
}
