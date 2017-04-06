import Console
import Foundation

let console: ConsoleProtocol = Terminal(arguments: CommandLine.arguments)

var iterator = CommandLine.arguments.makeIterator()

guard let executable = iterator.next() else {
    throw ConsoleError.noExecutable
}

do {
    try console.run(
        executable: executable,
        commands: [
            New(console: console),
            Model(console: console),
            Controller(console: console),
            View(console: console),
            Group(id: "self", commands: [
                SelfInstall(console: console, executable: executable)
            ], help: [
                    "Commands that affect the toolbox itself."
            ]),
        ],
        arguments: Array(iterator),
        help: ["Spoofing MAC Address"])
} catch {
    
}
