import Console
import Foundation

public final class Controller: Command {
    public let id = "controller"
    
    public let signature: [Argument] = [
        
    ]
    
    public let help: [String] = [
        "Creates a controller",
        "Use with the following format:",
        "controller ControllerName <functionName>:<functionType>:<functionRoute>",
        "Where \"functionType\" is \"get\" or \"post\""
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        do {
            let currentPath = FileManager.default.currentDirectoryPath
            let packageFilePath = currentPath + "/Package.swift"
            let controllersFolderPath = currentPath + "/Sources/App/Controllers"
            let dropletRoutesFile = currentPath + "/Sources/App/Setup/Droplet/Droplet+Routes.swift"
            let dropletViewFile = currentPath + "/Sources/App/Setup/Droplet/Droplet+Views.swift"
            
            if !FileManager.default.fileExists(atPath: packageFilePath) {
                throw ErrorCase.generalError("This is not a Vapor project. Please execute Vaporize in a Vapor project")
            }
            
            let directoryOfTemplates = "\(NSHomeDirectory())/.vaporize"
            let apiControllerFile = "\(directoryOfTemplates)/apicontroller.swift"
            let viewControllerFile = "\(directoryOfTemplates)/viewcontroller.swift"
            
            //require at least the name and one property
            var args = arguments
            if args.count == 0 {
                throw ConsoleError.insufficientArguments
            }
            
            let controllerName = args[0]
            args.removeFirst()
            
            var folder = ""
            while folder != "view" && folder != "api" {
                folder = console.ask("Create in Views folder or API folder? (view/api)").lowercased()
            }
            
            //initial changing of the file
            var contentsOfControllerFile = ""
            
            if folder == "view" {
                contentsOfControllerFile = try String(contentsOfFile: viewControllerFile)
            } else {
                contentsOfControllerFile = try String(contentsOfFile: apiControllerFile)
            }
            
            var filledInControllerFile = contentsOfControllerFile
            filledInControllerFile = filledInControllerFile.replacingOccurrences(of: .controllerName, with: controllerName)
            
            if args.count == 0 {
                //there were no functions passed in, remove the variable placeholders from file
                filledInControllerFile = filledInControllerFile.replacingOccurrences(of: .functions, with: "")
                filledInControllerFile = filledInControllerFile.replacingOccurrences(of: .routes, with: "")
            } else {
                var routesString = ""
                var functionsString = ""
                
                let functions = try args.map { try Function(fullString: $0) }
                for (index, function) in functions.enumerated() {
                    let isLast = index == functions.count - 1
                    let isFirst = index == 0
                    
                    if !isFirst {
                        routesString += space(count: 8)
                        functionsString += space(count: 4)
                    }
                    
                    routesString += "build.\(function.method.rawValue)(\"\(function.route)\", handler: \(function.name))"
                    
                    functionsString += "func \(function.name)(_ req: Request) throws -> ResponseRepresentable {"
                    functionsString += "\n"
                    functionsString += "\(space(count: 8))return \"\""
                    functionsString += "\n"
                    functionsString += "\(space(count: 4))}"
                    
                    if !isLast {
                        routesString += "\n"
                        functionsString += "\n\n"
                    }
                }
                
                filledInControllerFile = filledInControllerFile.replacingOccurrences(of: .functions, with: functionsString)
                filledInControllerFile = filledInControllerFile.replacingOccurrences(of: .routes, with: routesString)
            }

            var writePath = ""
            
            if folder == "view" {
                writePath = controllersFolderPath + "/Views"
            } else {
                writePath = controllersFolderPath + "/API"
            }
            
            try filledInControllerFile.write(toFile: writePath + "/\(controllerName).swift", atomically: true, encoding: .utf8)
            
            var registerContent = ""
            var route = ""
            
            if folder == "view" {
                route = dropletViewFile
                registerContent = try String(contentsOfFile: route)
            } else {
                route = dropletRoutesFile
                registerContent = try String(contentsOfFile: route)
            }
            
            var replacementText = ""
            
            if folder == "view" {
                replacementText = "try collection(\(controllerName)(view))"
            } else {
                replacementText = "try collection(\(controllerName).self)"
            }
            
            var filledInRegistrationFile = registerContent.replacingOccurrences(of: "}\n", with: "")
            filledInRegistrationFile += "\(space(count: 4))\(replacementText)\n"
            filledInRegistrationFile += "\(space(count: 4))}\n"
            filledInRegistrationFile += "}\n"
            try filledInRegistrationFile.write(toFile: route, atomically: true, encoding: .utf8)
            
            console.success("\(controllerName).swift located at \(writePath)/\(controllerName).swift", newLine: true)
        } catch {
            console.error(error.localizedDescription, newLine: true)
        }
    }
    
    func space(count: Int) -> String {
        if count < 0 {
            return ""
        }
        
        var spaces = ""
        for _ in 0 ..< count {
            spaces += " "
        }
        return spaces
    }
}

enum ControllerKey: String {
    case controllerName = "VAR_CONTROLLER_NAME"
    case routes = "VAR_ROUTES"
    case functions = "VAR_FUNCTIONS"
}

enum FunctionMethod: String {
    case get
    case post
}

fileprivate extension String {
    func replacingOccurrences(of: ControllerKey, with: String) -> String {
        return replacingOccurrences(of: of.rawValue, with: with)
    }
}

struct Function {
    let name: String
    let route: String
    let method: FunctionMethod
    
    init(name: String, method: String, route: String) throws {
        guard let functionMethod = FunctionMethod(rawValue: method) else {
            throw ConsoleError.insufficientArguments
        }
        
        self.name = name
        self.method = functionMethod
        self.route = route
    }
    
    init(fullString: String) throws {
        let splitStrings = fullString.components(separatedBy: ":")
        if splitStrings.count != 3 {
            throw ConsoleError.insufficientArguments
        }
        
        try self.init(name: splitStrings[0], method: splitStrings[1], route: splitStrings[2])
    }
}
