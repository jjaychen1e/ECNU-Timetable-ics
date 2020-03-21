import Foundation
import PerfectHTTP
import PerfectHTTPServer
import PerfectMySQL
import PerfectLogger

var routes = Routes()
routes.add(method: .get, uri: "/ecnu-ics/get-ics") {
	request, response in
    response.setHeader(.contentEncoding, value: "utf-8")
    response.setHeader(.contentType, value: "application/json")
    
    let sessionID = MySQLConnector.getNextSessionID()
    
    if let username = request.param(name: "username"),
        let password = request.param(name: "password"),
        let year = request.param(name: "year"),
        let semesterIndex = request.param(name: "semesterIndex"){
        
        if let year = Int(year), let semesterIndex = Int(semesterIndex) {
            let today = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy"
            let currentYear = Int(dateFormatter.string(from: today))!
            
            guard (1...3).contains(semesterIndex), (2019...currentYear).contains(year) else {
                try! response.setBody(json: ResultEntity.fail(message: "学年或学期索引不正确"))
                response.completed()
                
                LogManager.saveResultLog(username: request.param(name: "username") ?? "nil", year: request.param(name: "year") ?? "nil", semesterIndex: request.param(name: "semesterIndex") ?? "nil", description: "学年或学期索引不正确", eventID: sessionID)
                
                return
            }
            
            let icsSession = CrawlICSSession(sessionID: sessionID, username: username, password: password, year: year, semesterIndex: semesterIndex)
            
            let result = icsSession.getICS()
            
            guard result.code == 0 else {
                try! response.setBody(json: result)
                response.completed()
                
                LogManager.saveResultLog(username: icsSession.realName, year: request.param(name: "year") ?? "nil", semesterIndex: request.param(name: "semesterIndex") ?? "nil", description: result.message, eventID: sessionID)
                
                return
            }
            
            // So that the brower can parse the .ics file.
            response.setHeader(.contentType, value: "text/calendar")
            response.setHeader(.contentDisposition,
                               value: "attachment; filename=\"\(result.data["filename"]!)\"")
            response.setBody(string: result.data["content"]!)
            response.completed()
            
            LogManager.saveResultLog(username: icsSession.realName, year: request.param(name: "year") ?? "nil", semesterIndex: request.param(name: "semesterIndex") ?? "nil", description: "成功", eventID: sessionID)
            return
        }
    }
    
    try! response.setBody(json: ResultEntity.fail(message: "未提供学号，密码，学年或学期索引"))
    response.completed()
    
    LogManager.saveResultLog(username: request.param(name: "username") ?? "nil", year: request.param(name: "year") ?? "nil", semesterIndex: request.param(name: "semesterIndex") ?? "nil", description: "未提供学号，密码，学年或学期索引", eventID: sessionID)
}

do {
    try FileManager.default.createDirectory(atPath: FileManager.default.currentDirectoryPath + "/tmp", withIntermediateDirectories: true, attributes: nil)
    
    generateHelperPy()
    
    // 启动HTTP服务器
    try HTTPServer.launch(
		.server(name: "ecnu-ics.jjaychen.me", port: 80, routes: routes))
} catch {
	fatalError("\(error)") // fatal error launching one of the servers
}
