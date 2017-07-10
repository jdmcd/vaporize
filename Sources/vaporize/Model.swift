import Console
import Foundation

public final class Model: Command {
    public let id = "model"
    
    public let signature: [Argument] = [
        
    ]
    
    public let help: [String] = [
        "Creates a model"
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        do {
            let currentPath = FileManager.default.currentDirectoryPath
            let packageFilePath = currentPath + "/Package.swift"
            let modelsFolderPath = currentPath + "/Sources/App/Models"
            let preparationsPath = currentPath + "/Sources/App/Setup/Config/Config+Preparations.swift"
            
            if !FileManager.default.fileExists(atPath: packageFilePath) {
                throw ErrorCase.generalError("This is not a Vapor project. Please execute Vaporize in a Vapor project")
            }
            
            let directoryOfTemplates = "\(NSHomeDirectory())/.vaporize"
            let modelFile = "\(directoryOfTemplates)/model.swift"
            
            //require at least the name and one property
            var args = arguments
            if args.count < 2 {
                console.error("Insufficient Arguments", newLine: true)
                throw ConsoleError.insufficientArguments
            }
            
            let node = arguments.flag("node")
            let viewData = arguments.flag("viewdata") || arguments.flag("viewData")
            
            let modelName = args[0]
            args.remove(at: 0)
            
            if node {
                guard let index = args.index(of: "--node=true") else { throw ConsoleError.argumentNotFound }
                args.remove(at: index)
            }
            
            if viewData {
                if let index = args.index(of: "--viewdata=true") {
                    args.remove(at: index)
                }
                
                if let index = args.index(of: "--viewData=true") {
                    args.remove(at: index)
                }
            }
            
            let properties = try args.map { try Property(fullString: $0) }
            
            //holder strings
            var propertyString = ""
            var propertyInitString = ""
            var propertyMakeRow = ""
            var builder = ""
            var makeJson = ""
            var initJson = ""
            
            var firstInitProperties = ""
            var fiAssignString = ""
            var fieldEnumKeys = ""
            
            var relationProperties = [Property]()
            
            //first loop builds the actual model
            for (index, property) in properties.enumerated() {
                let isLast = index == properties.count - 1
                let isFirst = index == 0
                let fieldString = "\(modelName).Field.\(property.name)"
                
                if !isFirst {
                    propertyString += space(count: 4)
                    fiAssignString += space(count: 8)
                    propertyInitString += space(count: 8)
                    propertyMakeRow += space(count: 8)
                    builder += space(count: 12)
                    makeJson += space(count: 8)
                    initJson += space(count: 8)
                    fieldEnumKeys += space(count: 8)
                }
                
                firstInitProperties += "\(property.name): \(property.type)"
                if property.optional {
                    firstInitProperties += "?"
                }
                
                fiAssignString += "self.\(property.name) = \(property.name)"
                
                propertyString += "var \(property.name): \(property.type)"
                if property.optional {
                    propertyString += "?"
                }
                
                propertyInitString += "\(property.name) = try row.get(\(fieldString))"
                
                propertyMakeRow += "try row.set(\(fieldString), \(property.name))"
                initJson += "\(property.name) = try json.get(\(fieldString))"
                makeJson += "try json.set(\(fieldString), \(property.name))"
                
                if let parentName = property.parentName {
                    relationProperties.append(property)
                    if property.optional {
                        builder += "builder.parent(\(parentName).self, optional: true)"
                    } else {
                        builder += "builder.parent(\(parentName).self)"
                    }
                } else {
                    if property.optional {
                        builder += "builder.\(property.type.lowercased())(\(fieldString), optional: true)"
                    } else {
                        builder += "builder.\(property.type.lowercased())(\(fieldString))"
                    }
                }
                
                fieldEnumKeys += "case \(property.name)"
                
                if !isLast {
                    //if it's not the last item, add a comma to the node array and add a new line to everything else
                    propertyString += "\n"
                    propertyInitString += "\n"
                    propertyMakeRow += "\n"
                    initJson += "\n"
                    makeJson += "\n"
                    builder += "\n"
                    fiAssignString += "\n"
                    fieldEnumKeys += "\n"
                    
                    firstInitProperties += ", "
                }
            }
            
            //second loop that builds the relationships
            for (index, property) in relationProperties.enumerated() {
                let isLast = index == properties.count - 1
                let isFirst = index == 0
                guard let parentName = property.parentName else { return }
                
                if !isFirst {
                    propertyString += space(count: 4)
                }
                
                if isFirst {
                    propertyString += "\n"
                }
                
                propertyString += "\n"
                propertyString += "\(space(count: 4))var \(parentName.lowercased()): Parent<\(modelName), \(parentName)>"
                
                if property.optional {
                    propertyString += "?"
                }
                propertyString += " {\n"
                propertyString += "\(space(count: 8))return parent(id: \(property.name.lowercased()))\n"
                propertyString += "\(space(count: 4))}"
                
                if !isLast {
                    //if it's not the last item, add a comma to the node array and add a new line to everything else
                    propertyString += "\n"
                }
            }
            
            let contentsOfModelTemplate = try String(contentsOfFile: modelFile)
            var newModel = contentsOfModelTemplate
            
            newModel = newModel.replacingOccurrences(of: .modelName, with: modelName)
            newModel = newModel.replacingOccurrences(of: .properties, with: propertyString)
            newModel = newModel.replacingOccurrences(of: .firstInit, with: firstInitProperties)
            newModel = newModel.replacingOccurrences(of: .fiAssign, with: fiAssignString)
            newModel = newModel.replacingOccurrences(of: .propertiesInit, with: propertyInitString)
            newModel = newModel.replacingOccurrences(of: .propertiesMakeRow, with: propertyMakeRow)
            newModel = newModel.replacingOccurrences(of: .builder, with: builder)
            newModel = newModel.replacingOccurrences(of: .makeJson, with: makeJson)
            newModel = newModel.replacingOccurrences(of: .jsonInit, with: initJson)
            newModel = newModel.replacingOccurrences(of: .fieldEnumKeys, with: fieldEnumKeys)
            
            
            //figure out if they want Node conformance
            if node {
                var nodeString = ""
                
                nodeString += "\n"
                nodeString += "//MARK: - NodeRepresentable \n"
                nodeString += "extension \(modelName): NodeRepresentable {"
                nodeString += "\n"
                nodeString += space(count: 4)
                nodeString += "func makeNode(in context: Context?) throws -> Node {"
                nodeString += "\n"
                nodeString += space(count: 8)
                nodeString += "return Node(try makeJSON())"
                nodeString += "\n"
                nodeString += space(count: 4)
                nodeString += "}"
                nodeString += "\n"
                nodeString += "}"
                
                newModel = newModel.replacingOccurrences(of: .node, with: nodeString)
            } else {
                newModel = newModel.replacingOccurrences(of: .node, with: "")
            }
            
            //figure out if they want ViewData conformance
            if viewData {
                var viewDataString = ""
                
                if node {
                    viewDataString += "\n"
                }
                viewDataString += "//MARK: - ViewDataRepresentable \n"
                viewDataString += "extension \(modelName): ViewDataRepresentable {"
                viewDataString += "\n"
                viewDataString += space(count: 4)
                viewDataString += "func makeViewData() throws -> ViewData {"
                viewDataString += "\n"
                viewDataString += space(count: 8)
                viewDataString += "return ViewData(try makeJSON())"
                viewDataString += "\n"
                viewDataString += space(count: 4)
                viewDataString += "}"
                viewDataString += "\n"
                viewDataString += "}"
                viewDataString += "\n"
                
                newModel = newModel.replacingOccurrences(of: .viewData, with: viewDataString)
            } else {
                newModel = newModel.replacingOccurrences(of: .viewData, with: "")
            }
            
            try newModel.write(toFile: "\(modelsFolderPath)/\(modelName).swift", atomically: true, encoding: .utf8)
            
            let contentsOfPreparationsFile = try String(contentsOfFile: preparationsPath)
            var filledInPreparation = contentsOfPreparationsFile
            
            //add to preparations file
            filledInPreparation = filledInPreparation.replacingOccurrences(of: "}\n", with: "")
            filledInPreparation += "\(space(count: 4))preparations.append(\(modelName).self)\n"
            filledInPreparation += "\(space(count: 4))}\n"
            filledInPreparation += "}\n"
            
            try filledInPreparation.write(toFile: preparationsPath, atomically: true, encoding: .utf8)
            
            console.success("\(modelName).swift located at \(modelsFolderPath)/\(modelName).swift", newLine: true)
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

enum ModelKeys: String {
    case modelName = "VAR_MODEL_NAME"
    case properties = "VAR_PROPERTIES"
    case propertiesInit = "VAR_INIT"
    case propertiesMakeRow = "VAR_MAKE_ROW"
    case builder = "VAR_BUILDER"
    case firstInit = "VAR_FIRST_INIT_PROPERTIES"
    case fiAssign = "VAR_FI_ASSIGN"
    case jsonInit = "VAR_JSON_INIT"
    case makeJson = "VAR_MAKE_JSON"
    case fieldEnumKeys = "VAR_FIELD_ENUM_CASES"
    case node = "VAR_NODE"
    case viewData = "VAR_VIEW_DATA"
}

struct Property {
    let name: String
    let type: String
    let optional: Bool
    
    var parentName: String? = nil
    
    init(name: String, type: String, optional: Bool) throws {
        
        if let rawPropertyType = PropertyType(rawValue: type) {
            self.type = rawPropertyType.rawValue.capitalized
        } else {
            self.type = PropertyType.identifier.rawValue.capitalized
            self.parentName = type.capitalized
        }
        
        self.optional = optional
        self.name = name
    }
    
    init(fullString: String) throws {
        let splitStrings = fullString.components(separatedBy: ":")
        if splitStrings.count != 2 {
            throw ConsoleError.insufficientArguments
        }
        
        let name = splitStrings[0]
        var type = splitStrings[1]
        var optional = false
        
        if type.hasSuffix("!") {
            optional = true
            type = type.substring(to: type.index(before: type.endIndex))
        }
        
        try self.init(name: name, type: type, optional: optional)
    }
}

enum PropertyType: String {
    case int
    case string
    case double
    case bool
    case identifier
}

extension String {
    public var pluralized: String {
        return plural()
    }
    
    func plural() -> String {
        return self + "s"
    }
}

fileprivate extension String {
    func replacingOccurrences(of: ModelKeys, with: String) -> String {
        return replacingOccurrences(of: of.rawValue, with: with)
    }
}
