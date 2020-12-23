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

extension FileManager {
    
    public func isDirectory(path: String) -> Bool {
        var flag: ObjCBool = false
        
        if self.fileExists(atPath: path, isDirectory: &flag) {
            return flag.boolValue
        }
        
        return false
    }
    
    
    public func fileSize(path: String) -> UInt64 {
        guard let attr = try? self.attributesOfItem(atPath: path) else {
            return 0
        }
        
        return attr[.size] as? UInt64 ?? 0
    }
    
    
    public func directorySize(path: String) -> UInt64 {
        guard let url = URL(string: path),
              let array = try? self.subpathsOfDirectory(atPath: path) else {
            return 0
        }
        
        
        var res: UInt64 = 0
        
        for file in array {
            var url2 = url
            url2.appendPathComponent(file)
            
            res += fileSize(path: url.path)
        }
        
        return res
    }
    
}
