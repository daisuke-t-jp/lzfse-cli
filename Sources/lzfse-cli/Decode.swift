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

class Decode {
    
    public static func decode(input: String, output: String?, force: Bool) {
        guard let inputURL = URL(string: input),
              let inputLastPathComponent = URL(string: inputURL.lastPathComponent) else {
            Print.stderrWrite("input path is invalid.")
            
            return
        }
        
        
        let inputDirectoryURL = inputURL.deletingLastPathComponent()
        
        if inputLastPathComponent.pathExtension.uppercased() == ArchiveManager.extensionLZFSE.uppercased() {
            self.decodeFile(input: input,
                            output: output,
                            force: force,
                            inputLastPathComponent: inputLastPathComponent,
                            inputDirectoryURL: inputDirectoryURL)
        }
        else if inputLastPathComponent.pathExtension.uppercased() == ArchiveManager.extensionAAR.uppercased() {
            self.decodeDirectory(input: input,
                                 output: output,
                                 force: force,
                                 inputLastPathComponent: inputLastPathComponent,
                                 inputDirectoryURL: inputDirectoryURL)
        }
        else {
            Print.stderrWrite("input file must be `.lzfse` or `.aar`.")
            
            return
        }
    }
    
    
    private static func decodeFile(input: String,
                                   output: String?,
                                   force: Bool,
                                   inputLastPathComponent: URL,
                                   inputDirectoryURL: URL) {
        let outputFileName = inputLastPathComponent.deletingPathExtension()
        
        if let output = output {
            guard var outputURL = URL(string: output) else {
                Print.stderrWrite("output path is invalid.")
                
                return
            }
            
            outputURL.appendPathComponent(outputFileName.path)
            
            _ = ArchiveManager.sharedInstance.decode(inputPath: FilePath(input),
                                                     outputPath: FilePath(outputURL.path),
                                                     overwritable: force)
        }
        else {
            var outputURL = inputDirectoryURL
            outputURL.appendPathComponent(outputFileName.path)
            
            _ = ArchiveManager.sharedInstance.decode(inputPath: FilePath(input),
                                                     outputPath: FilePath(outputURL.path),
                                                     overwritable: force)
        }
    }
    
    
    private static func decodeDirectory(input: String,
                                        output: String?,
                                        force: Bool,
                                        inputLastPathComponent: URL,
                                        inputDirectoryURL: URL) {
        let outputDirectoryName = inputLastPathComponent.deletingPathExtension()
        
        if let output = output {
            guard var outputURL = URL(string: output) else {
                Print.stderrWrite("output path is invalid.")
                
                return
            }
            
            outputURL.appendPathComponent(outputDirectoryName.path)
            
            _ = ArchiveManager.sharedInstance.decodeDirectory(inputPath: FilePath(input),
                                                              outputPath: FilePath(outputURL.path),
                                                              overwritable: force)
        }
        else {
            var outputURL = inputDirectoryURL
            outputURL.appendPathComponent(outputDirectoryName.path)
            
            _ = ArchiveManager.sharedInstance.decodeDirectory(inputPath: FilePath(input),
                                                              outputPath: FilePath(outputURL.path),
                                                              overwritable: force)
        }
    }
    
}
