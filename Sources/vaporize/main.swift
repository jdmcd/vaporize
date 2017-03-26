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
            New(console: console)
        ],
        arguments: Array(iterator),
        help: ["Spoofing MAC Address"])
} catch {
    
}
