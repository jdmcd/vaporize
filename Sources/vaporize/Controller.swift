import Console
import Foundation

public final class Controller: Command {
    public let id = "controller"
    
    public let signature: [Argument] = [
        
    ]
    
    public let help: [String] = [
        "Creates a controller"
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        do {
            let currentPath = FileManager.default.currentDirectoryPath
            let packageFilePath = currentPath + "/Package.swift"
            let controllersFolderPath = currentPath + "/Sources/AppLogic/Controllers"
            
            if !FileManager.default.fileExists(atPath: packageFilePath) {
                throw ErrorCase.generalError("This is not a Vapor project. Please execute Vaporize in a Vapor project")
            }
            
            let directoryOfTemplates = "\(NSHomeDirectory())/.vaporize"
            let controllerFile = "\(directoryOfTemplates)/controller.swift"
            
            //require at least the name and one property
            var args = arguments
            if args.count != 1 {
                throw ConsoleError.insufficientArguments
            }
            
            let controllerName = args[0]
            
            let contentsOfControllerFile = try String(contentsOfFile: controllerFile)
            var filledInControllerFile = contentsOfControllerFile
            filledInControllerFile = filledInControllerFile.replacingOccurrences(of: .controllerName, with: controllerName)
            
            var folder = ""
            while folder != "view" && folder != "api" {
                folder = console.ask("Create in Views folder or API folder? (view/api)").lowercased()
            }

            var writePath = ""
            
            if folder == "view" {
                writePath = controllersFolderPath + "/Views"
            } else {
                writePath = controllersFolderPath + "/API"
            }
            
            try controllerName.write(toFile: writePath + "/\(controllerName).swift", atomically: true, encoding: .utf8)
            
            console.success("\(controllerName).swift located at \(writePath)/\(controllerName).swift", newLine: true)
        } catch {
            console.error(error.localizedDescription, newLine: true)
        }
    }
}

enum ControllerKey: String {
    case controllerName = "VAR_CONTROLLER_NAME"
}

fileprivate extension String {
    func replacingOccurrences(of: ControllerKey, with: String) -> String {
        return replacingOccurrences(of: of.rawValue, with: with)
    }
}
