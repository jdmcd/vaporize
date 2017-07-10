# Vaporize

Vaporize is a small tool built around Vapor's `Console` framework that is heavily inspired by Vapor's `toolbox`. Right now, the executable will generate a new project for you using my Vapor Template (https://github.com/mcdappdev/Vapor-Template), ask you for some MySQL/Redis information, and then generate a clean project for you using those specifications.

# Requirements

You must have Swift installed, as well as the Vapor toolbox.

# Installation

You can run the following code in your terminal to download Vaporize:

`curl -sL 162llc.com/install.sh | bash`

# Usage
Vaporize has four main functions: `new`, `model`, `controller`, and `view`.

## `new`
The `new` command generates a new project using https://github.com/mcdappdev/Vapor-Template. After running `vaporize new`, you'll be presented with a list of questions that it will use to fill in templating options in the template. It'll even create a local MySQL store for you, if you ask it to.

## `model`
The `model` command generates a new model using the same format as in the Vapor Template.

`vaporize model ModelName property1:string property2:bool property3:int property4:double`

The above command will generate the following output:

```swift
import Vapor
import FluentProvider

final class ModelName: Model {
    var storage = Storage()

    var property1: String
    var property2: Bool
    var property3: Int
    var property4: Double

    init(property1: String, property2: Bool, property3: Int, property4: Double) {
        self.property1 = property1
        self.property2 = property2
        self.property3 = property3
        self.property4 = property4
    }

    init(row: Row) throws {
        property1 = try row.get(ModelName.Field.property1)
        property2 = try row.get(ModelName.Field.property2)
        property3 = try row.get(ModelName.Field.property3)
        property4 = try row.get(ModelName.Field.property4)
    }

    init(json: JSON) throws {
        property1 = try json.get(ModelName.Field.property1)
        property2 = try json.get(ModelName.Field.property2)
        property3 = try json.get(ModelName.Field.property3)
        property4 = try json.get(ModelName.Field.property4)
    }

    func makeRow() throws -> Row {
        var row = Row()

        try row.set(ModelName.Field.property1, property1)
        try row.set(ModelName.Field.property2, property2)
        try row.set(ModelName.Field.property3, property3)
        try row.set(ModelName.Field.property4, property4)

        return row
    }
}

//MARK: - Preparation
extension ModelName: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self, closure: { builder in
            builder.id()
            builder.string(ModelName.Field.property1)
            builder.bool(ModelName.Field.property2)
            builder.int(ModelName.Field.property3)
            builder.double(ModelName.Field.property4)
        })
    }

    static func revert(_ database: Database) throws {
    }
}

//MARK: - JSONConvertible
extension ModelName: JSONConvertible {
    func makeJSON() throws -> JSON {
        var json = JSON()

        try json.set(ModelName.Field.id, id)
        try json.set(ModelName.Field.property1, property1)
        try json.set(ModelName.Field.property2, property2)
        try json.set(ModelName.Field.property3, property3)
        try json.set(ModelName.Field.property4, property4)
        try json.set(ModelName.createdAtKey, createdAt)
        try json.set(ModelName.updatedAtKey, updatedAt)

        return json
    }
}


//MARK: - Timestampable
extension ModelName: Timestampable { }

//MARK: - Field
extension ModelName {
    enum Field: String {
        case id
        case property1
        case property2
        case property3
        case property4
    }
}
```

You can also add the `--viewData` or `--node` flag which will add `ViewDataRepresentable` and `NodeRepresentable` conformance, respectively. 

In addition, if you use a capital letter as the start of the type value, the parser will infer a relationship to another entity. Like this:

`vaporize model ModelName user_id:User`

Generates:

```swift
import Vapor
import FluentProvider

final class ModelName: Model {
    var storage = Storage()

    var user_id: Identifier

    var user: Parent<ModelName, User> {
        return parent(id: user_id)
    }

    init(user_id: Identifier) {
        self.user_id = user_id
    }

    init(row: Row) throws {
        user_id = try row.get(ModelName.Field.user_id)
    }

    init(json: JSON) throws {
        user_id = try json.get(ModelName.Field.user_id)
    }

    func makeRow() throws -> Row {
        var row = Row()

        try row.set(ModelName.Field.user_id, user_id)

        return row
    }
}

//MARK: - Preparation
extension ModelName: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self, closure: { builder in
            builder.id()
            builder.parent(User.self)
        })
    }

    static func revert(_ database: Database) throws {
    }
}

//MARK: - JSONConvertible
extension ModelName: JSONConvertible {
    func makeJSON() throws -> JSON {
        var json = JSON()

        try json.set(ModelName.Field.id, id)
        try json.set(ModelName.Field.user_id, user_id)
        try json.set(ModelName.createdAtKey, createdAt)
        try json.set(ModelName.updatedAtKey, updatedAt)

        return json
    }
}


//MARK: - Timestampable
extension ModelName: Timestampable { }

//MARK: - Field
extension ModelName {
    enum Field: String {
        case id
        case user_id
    }
}
```

**Note:** This will also add the `Preparation` to `Config`'s array to automatically setup the database.


## `controller`
The `controller` command, when used without options, generates a super simple controller that can be used for adding routes/views.

`vaporize controller ControllerName`

The above command results in the following question:

`Create in Views folder or API folder? (view/api)`

Responding with `view` will produce the following file:

```swift
import Vapor
import Flash

final class ControllerName: RouteCollection {
    private let view: ViewRenderer

    init(_ view: ViewRenderer) {
        self.view = view
    }

    func build(_ builder: RouteBuilder) throws {
        builder.frontend() { build in

        }
    }
}
```

Responding with `api` will produce the following file:

```swift
import Vapor
import Flash

final class ControllerName: RouteCollection {
    func build(_ builder: RouteBuilder) throws {
        builder.version() { build in

        }
    }
}

//MARK: - EmptyInitializable
extension ControllerName: EmptyInitializable { }
```

### Extra Controller options
You can also specify functions and routes to add to the controller. Add them to the command similar to the `model` command, but in the following format: `<functionName>:<functionType>:<functionRoute>` where `functionName` is the name of the function, `functionType` is either `get` or `post`, and `functionRoute` is the route in which to add it to the drop.

`vaporize controller NewController homeView:get:home logoutView:get:home`

Running the above command will generate the following file:

```swift
import Vapor
import Flash

final class NewController: RouteCollection {
    func build(_ builder: RouteBuilder) throws {
        builder.version() { build in
            build.get("home", handler: homeView)
        build.get("home", handler: logoutView)
        }
    }

    func homeView(_ req: Request) throws -> ResponseRepresentable {
        return ""
    }

    func logoutView(_ req: Request) throws -> ResponseRepresentable {
        return ""
    }
}

//MARK: - EmptyInitializable
extension NewController: EmptyInitializable { }
```

**Note:** This command will also register the controller in the appropriate file so that it is accesible

## view
The view function will generate a new view filled in with a HTML title for the page.

`vaporize view login Login`

The above command will generate the following file:

```
#extend("Views/base")
#export("title") { Login }

#export("html") {

}
```

If you use the base leaf file provided in the template, the end HTML result looks like this:

```html

<!DOCTYPE html>
<html>

<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Login</title>
</head>

</html>
```

# Thanks

Much thanks to the Vapor team as well as everyone who helped contribute to the template as well as the creation of this tool.
