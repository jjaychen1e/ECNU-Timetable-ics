//
//  Helper.swift
//  ECNU-Timetable-ics
//
//  Created by JJAYCHEN on 2020/3/5.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Foundation


// MARK: Helper functions

func generateRecognizePy() {
    var content = """
        import pytesseract
        import sys
        from PIL import Image

        img = Image.open(sys.argv[1])
        tesseract_path = sys.argv[2]

        pytesseract.pytesseract.tesseract_cmd = tesseract_path
        print(pytesseract.image_to_string(img), end='')

        """
    
    do {
        try content.write(to: URL(fileURLWithPath: TEMP_PREXFIX + "/recognize.py"), atomically: true, encoding: String.Encoding.utf8)
    } catch {
        fatalError("\(error)")
    }
    
    #if os(Linux)
    
    content = """
    import execjs
    import sys
    input = sys.argv[1]
    
    desCode = \"\"\"
    \(desCode)
    \"\"\"
    
    desJS = execjs.compile(desCode)
    print(desJS.call('strEnc', input, '1', '2', '3'), end='')
    
    """
    
    do {
        try content.write(to: URL(fileURLWithPath: TEMP_PREXFIX + "/getRSA.py"), atomically: true, encoding: String.Encoding.utf8)
    } catch {
        fatalError("\(error)")
    }
    
    #endif
}

func runCommand(launchPath: String, arguments: [String]) -> String {
    let pipe = Pipe()
    let file = pipe.fileHandleForReading
    
    let task = Process()
    
    if #available(OSX 10.13, *) {
        task.executableURL = URL(string: launchPath)!
    } else {
        task.launchPath = launchPath
    }
    task.arguments = arguments
    task.standardOutput = pipe
    
    
    if #available(OSX 10.13, *) {
        do {
            try task.run()
        } catch {
            print("\(error)")
        }
    } else {
        task.launch()
    }
    
    
    
    let data = file.readDataToEndOfFile()
    return String(data: data, encoding: String.Encoding.utf8)!
}

extension URLRequest {
    
    private func percentEscapeString(_ string: String) -> String {
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-._* ")
        
        return string
            .addingPercentEncoding(withAllowedCharacters: characterSet)!
            .replacingOccurrences(of: " ", with: "+")
            .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
    }
    
    mutating func encodeParameters(parameters: [String : String]) {
        httpMethod = "POST"
        
        let parameterArray = parameters.map { (arg) -> String in
            let (key, value) = arg
            return "\(key)=\(self.percentEscapeString(value))"
        }
        
        httpBody = parameterArray.joined(separator: "&").data(using: String.Encoding.utf8)
    }
}
