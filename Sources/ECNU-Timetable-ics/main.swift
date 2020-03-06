import Foundation
import PerfectHTTP
import PerfectHTTPServer
import Alamofire

// 注册您自己的路由和请求／响应句柄
var routes = Routes()
routes.add(method: .get, uri: "/") {
	request, response in
    response.setHeader(.contentType, value: "application/json")
    
    if let username = request.param(name: "username"),
        let password = request.param(name: "password")  {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        semesterBeginDate = dateFormatter.date(from: "2020.03.09")!
        semesterBeginDateComp = calendar.dateComponents([.year, .month, .day], from: semesterBeginDate!)
        
        getICSPath(username: username, password: password, year: 2019, semesterIndex: 2)
    }
    
//    if let username = request.param(name: "username"),
//        let password = request.param(name: "password") {
//        let (status, message) = login(username: username, password: password)
//
//        if status == .成功 {
//            do {
//                try response.setBody(json: ResultEntity.success(data: ["url": message]))
//                    .completed()
//            } catch {
//                response.setBody(string: "服务器处理发生致命错误")
//                    .completed()
//                fatalError("\(error)")
//            }
//        } else {
//            do {
//                try response.setBody(json: ResultEntity.fail(message: message))
//                    .completed()
//            } catch {
//                response.setBody(string: "服务器处理发生致命错误")
//                    .completed()
//                fatalError("\(error)")
//            }
//        }
//    }
//
//    do {
//        try response.setBody(json: ResultEntity.fail(message: "解析表单中用户名密码错误"))
//            .completed()
//    } catch {
//        response.setBody(string: "服务器处理发生致命错误")
//            .completed()
//        fatalError("\(error)")
//    }
}

do {
    // 启动HTTP服务器
    try HTTPServer.launch(
		.server(name: "www.example.ca", port: 8181, routes: routes))
} catch {
	fatalError("\(error)") // fatal error launching one of the servers
}

