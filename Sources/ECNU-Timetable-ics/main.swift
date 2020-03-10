import Foundation
import PerfectHTTP
import PerfectHTTPServer

var routes = Routes()
routes.add(method: .get, uri: "/") {
	request, response in
    
    response.setHeader(.contentType, value: "application/json")
    
    if let username = request.param(name: "username"),
        let password = request.param(name: "password"),
        let year = request.param(name: "year"),
        let semesterIndex = request.param(name: "semesterIndex"){
        
        if let year = Int(year), let semesterIndex = Int(semesterIndex) {
            guard (1...3).contains(semesterIndex), (2000...9999).contains(year) else {
                try! response.setBody(json: ResultEntity.fail(message: "学年或学期索引不正确"))
                response.completed()
                return
            }
            
            let result = getICS(username: username, password: password, year: year, semesterIndex: semesterIndex)
            
            guard result.code == 0 else {
                try! response.setBody(json: result)
                response.completed()
                return
            }
            
            // So the brower can parse the .ics file.
            response.setHeader(.contentType, value: "text/calendar")
            response.setHeader(.contentDisposition,
                               value: "attachment; filename=\"\(result.data["filename"]!)\"")
            response.setBody(string: result.data["content"]!)
            response.completed()
        }
    }

    response.setHeader(.contentEncoding, value: "")
    try! response.setBody(json: ResultEntity.fail(message: "未提供学号，密码，学年或学期索引。"))
    response.completed()
}

do {
    try FileManager.default.createDirectory(atPath: FileManager.default.currentDirectoryPath + "/tmp", withIntermediateDirectories: true, attributes: nil)
    
    generateRecognizePy()
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy.MM.dd"
    
    // TODO: 设置开学时间
    semesterBeginDate = dateFormatter.date(from: "2020.03.09")!
    semesterBeginDateComp = calendar.dateComponents([.year, .month, .day], from: semesterBeginDate!)
    
    // 启动HTTP服务器
    try HTTPServer.launch(
		.server(name: "ecnu-ics.jjaychen.me", port: 8181, routes: routes))
} catch {
	fatalError("\(error)") // fatal error launching one of the servers
}
