# Vaporize

Vaporize is a small tool built around Vapor's `Console` framework that is heavily inspired by Vapor's `toolbox`. Right now, the executable will generate a new project for you using my Vapor Template (https://github.com/mcdappdev/Vapor-Template), ask you for some MySQL/Redis information, and then generate a clean project for you using those specifications.

# Requirements

You must have Swift installed, as well as the Vapor toolbox.

# Installation

You can run the following code in your terminal to download Vaporize:

`curl -sL 162llc.com/install.sh | bash`

# Usage
Vaporize has three main functions: `new`, `model`, and `controller`.

## `new`
The `new` command generates a new project using https://github.com/mcdappdev/Vapor-Template. After running `vaporize new`, you'll be presented with a list of questions that it will use to fill in templating options in the template. It'll even create a local MySQL store for you, if you ask it to.

## `model`
The `model` command generates a new model using the same format as in the Vapor Template.

`vaporize model ModelName property1:string property2:bool property3:int property4:double`

The above command will generate the following output:

```swift
import Foundation
import Vapor
import Fluent

final class ModelName: Model {
    var id: Node?
    var property1: String!
    var property2: Bool!
    var property3: Int!
    var property4: Double!

    var exists: Bool = false

    init(property1: String, property2: Bool, property3: Int, property4: Double) {
        self.property1 = property1
        self.property2 = property2
        self.property3 = property3
        self.property4 = property4
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        property1 = try node.extract("property1")
        property2 = try node.extract("property2")
        property3 = try node.extract("property3")
        property4 = try node.extract("property4")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "property1": property1,
            "property2": property2,
            "property3": property3,
            "property4": property4
        ])
    }
}

//MARK: - Preparation
extension ModelName: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("modelnames", closure: { builder in
            builder.id()
            builder.string("property1")
            builder.bool("property2")
            builder.int("property3")
            builder.double("property4")
        })
    }

    static func revert(_ database: Database) throws {
    }
}
```

## `controller`
The `controller` command, when used without options, generates a super simple controller that can be used for adding routes/views.

`vaporize controller ControllerName`

The above command results in the following question:

`Create in Views folder or API folder? (view/api)`

Responding with "view" will produce the following file:

```swift
import Vapor
import HTTP

final class ControllerName {
    let drop: Droplet

    init(drop: Droplet) {
        self.drop = drop
    }

    func addRoutes() {

    }
}
```

### Extra Controller options
You can also specify functions and routes to add to the controller. Add them to the command similar to the `model` command, but in the following format: `<functionName>:<functionType>:<functionRoute>` where `functionName` is the name of the function, `functionType` is either `get` or `post`, and `functionRoute` is the route in which to add it to the drop.

`vaporize controller NewController homeView:get:home logoutView:get:home`

Running the above command will generate the following file:

```swift
import Vapor
import HTTP

final class NewController {
    let drop: Droplet

    init(drop: Droplet) {
        self.drop = drop
    }

    func addRoutes() {
        drop.get("home", handler: homeView)
        drop.get("home", handler: logoutView)
    }

    func homeView(_ req: Request) throws -> ResponseRepresentable {
        return ""
    }

    func logoutView(_ req: Request) throws -> ResponseRepresentable {
        return ""
    }
}
```

# Thanks

Much thanks to the Vapor team as well as everyone who helped contribute to the template as well as the creation of this tool.
