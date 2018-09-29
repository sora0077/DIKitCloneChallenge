import Foundation
import DIGenKit
import Basic
import Utility

func print(
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n",
    to stream: inout ThreadSafeOutputByteStream) {

    for item in items.dropLast() {
        stream <<< "\(item)\(separator)"
    }
    if let last = items.last {
        stream <<< "\(last)"
    }
    stream <<< terminator
    stream.flush()
}

enum Mode {
    case version
    case generate(path: AbsolutePath, exclusions: [AbsolutePath])
}

// swiftlint:disable:next function_body_length
func mode(from args: [String]) throws -> Mode {

    struct Options {
        private var _mode: Mode = .help
        var mode: Mode {
            get { return shouldPrintVersion ? .version : _mode }
            set { _mode = newValue }
        }

        var shouldPrintVersion: Bool = false

        var inputDirectory: AbsolutePath?
        var exclusions: [AbsolutePath]?

        enum Mode: String, StringEnumArgument {
            case help
            case version
            case generate

            static var completion: ShellCompletion = .none
        }
    }

    let parser = ArgumentParser(
        commandName: "dikitgen",
        usage: "generate <path to source code directory> [--exclude <subpath> ...]",
        overview: "A statically typed dependency injector for Swift.",
        seeAlso: "https://github.com/ishkawa/DIKit")

    let binder = ArgumentBinder<Options>()

    // version
    binder.bind(
        option: parser.add(option: "--version", kind: Bool.self),
        to: { $0.shouldPrintVersion = $1 })

    // generate
    let generateParser = parser.add(
        subparser: Options.Mode.generate.rawValue,
        overview: "Generate dependency injection code")

    binder.bind(
        positional: generateParser.add(
            positional: "input directory",
            kind: PathArgument.self),
        to: { $0.inputDirectory = $1.path })

    binder.bind(
        option: generateParser.add(
            option: "--exclude",
            kind: [PathArgument].self),
        to: { $0.exclusions = $1.map { $0.path } })

    // -
    binder.bind(
        parser: parser,
        to: { $0.mode = Options.Mode(rawValue: $1)! })

    var options = Options()
    try binder.fill(parseResult: parser.parse(Array(args.dropFirst())), into: &options)

    switch options.mode {
    case .help:
        parser.printUsage(on: stdoutStream)
        exit(EXIT_SUCCESS)

    case .version:
        return .version

    case .generate:
        return .generate(path: options.inputDirectory!, exclusions: options.exclusions ?? [])
    }
}

do {

    switch try mode(from: CommandLine.arguments) {
    case .version:
        print(Version.current, to: &stdoutStream)

    case .generate(let path, let exclusions):
        let output = try CodeGenerator(path: path, exclusions: exclusions).generate()
        print(output, to: &stdoutStream)
    }

} catch {
    print(error, to: &stderrStream)
}
