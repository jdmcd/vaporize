import PackageDescription

let package = Package(
    name: "vaporize",
    dependencies: [
        .Package(url: "https://github.com/vapor/console.git", majorVersion: 1, minor: 0)
    ],
    exclude: [
        "Templates"
    ]
)
