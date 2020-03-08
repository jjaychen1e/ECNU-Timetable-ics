import Foundation
import PerfectHTTP
import PerfectHTTPServer
import Alamofire

var routes = Routes()
routes.add(method: .get, uri: "/") {
	request, response in
    response.setHeader(.contentType, value: "application/json")
    
    if let username = request.param(name: "username"),
        let password = request.param(name: "password")  {
        
        getICSPath(username: username, password: password, year: 2019, semesterIndex: 2)
    }
}

do {
    generateRecognizePy()
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy.MM.dd"
    
    // TODO: 设置开学时间
    semesterBeginDate = dateFormatter.date(from: "2020.03.09")!
    semesterBeginDateComp = calendar.dateComponents([.year, .month, .day], from: semesterBeginDate!)
    
    // 启动HTTP服务器
    try HTTPServer.launch(
		.server(name: "www.example.ca", port: 8181, routes: routes))
} catch {
	fatalError("\(error)") // fatal error launching one of the servers
}

