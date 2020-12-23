// Copyright 2020 Daisuke TONOSAKI
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import System
import ArgumentParser

enum Operation: EnumerableFlag {
    case encode
    case decode
    
    static func name(for value: Operation) -> NameSpecification {
        switch value {
            case .encode:
                return [.customShort("e"), .long]
            case .decode:
                return [.customShort("d"), .long]
        }
    }
}


struct Command: ParsableCommand {
    @Flag(help: "Specify operation.")
    var operation: Operation
    
    @Option(name: .shortAndLong, help: "Input file / directory path.")
    var input: String
    
    @Option(name: .shortAndLong, help: "Ouput directory path. If omitted, the same path as the input.")
    var output: String?
    
    // TODO: verbose flag.
    // @Flag(help: "Show verbose log.")
    // var verbose: Bool = false
    
    @Flag(name: .shortAndLong, help: "Deletes the existing file and outputs new.")
    var force: Bool = false
    
    
    static var configuration = CommandConfiguration(
        commandName: Constant.name,
        abstract: "LZFSE compression CLI",
        discussion: """
        The tool compress / decompress a single file and directory.
        """,
        version: Constant.version,
        shouldDisplay: true,
        // subcommands: ,
        // defaultSubcommand: ,
        helpNames: [.long, .short]
    )
    
    func run() throws {
        if operation == .encode {
            Encode.encode(input: self.input, output: self.output, force: self.force)
        }
        else if operation == .decode {
            Decode.decode(input: self.input, output: self.output, force: self.force)
        }
    }
}


Command.main()
