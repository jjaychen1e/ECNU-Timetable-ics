//
//  CrawlICSSession.swift
//
//  Created by JJAYCHEN on 2020/3/2.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(JavaScriptCore)
import JavaScriptCore
#endif

import Foundation
import PerfectLib
import PerfectLogger
import Kanna

class CrawlICSSession {
    /// 若为 -1 代表数据库连接失败
    private let sessionID: String
    
    private let urlSession: URLSession
    
    private let username: String
    
    private let password: String
    
    private let year: Int
    
    private let semesterIndex: Int
    
    private let calendar = Calendar.current
    
    private let semesterBeginDateComp: DateComponents?
    
    private var _realName: String?
    
    var realName: String {
        get {
            _realName ?? username
        }
        set {
            _realName = newValue
        }
    }
    
    internal init(sessionID: String, username: String, password: String, year: Int, semesterIndex: Int) {
        self.sessionID = sessionID
        self.username = username
        self.password = password
        self.year = year
        self.semesterIndex = semesterIndex
        
        let urlSessionConfiguration = URLSessionConfiguration.ephemeral
        urlSessionConfiguration.httpAdditionalHeaders = ["Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8"]
        self.urlSession = URLSession(configuration: urlSessionConfiguration)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        
        ///设置开学时间
        if let semesterBeginDate = dateFormatter.date(from: 开学日期[String(year)]![String(semesterIndex)]!) {
            self.semesterBeginDateComp = calendar.dateComponents([.year, .month, .day], from: semesterBeginDate)
        } else {
            self.semesterBeginDateComp = nil
        }
    }
    
    func getICS() -> ResultEntity {
        if self.semesterBeginDateComp == nil {
            return ResultEntity.fail(message: "该学年开学日期未设定，请联系作者手动更新")
        }
        
        let loginStatus = login()
        
        guard loginStatus == .成功 else {
            return ResultEntity.fail(message: loginStatus.toString())
        }
        
        let ids = getIDS()
        
        guard  ids != "" else {
            return ResultEntity.fail(message: "\(realName): IDS 获取失败，尝试重新运行")
        }
        
        let semesterID = String(getSemesterID(year: year, semesterIndex: semesterIndex))
        
        let courses = getCourseInfoList(semesterID: semesterID, ids: ids)
        
        guard courses.count > 0 else {
            return ResultEntity.fail(message: "\(realName): 课程列表获取失败，尝试重新运行")
        }
        
        let calendarName = "\(year)-\(year+1) 学年\(索引转学期["\(semesterIndex)"]!)课表"
        
        let icsCalendar = getICSCalendar(for: courses, with: calendarName, in: semesterID, session: urlSession)
        
        return ResultEntity.success(data: [
            "content": icsCalendar.toICSDescription(),
            "filename": calendarName + ".ics"
        ])
    }

    private func login() -> LoginStatus {
        LogManager.saveProcessLog(message: "\(sessionID)-\(realName): 正在准备登录", eventID: sessionID)
//        print("正在准备登录")
        let semaphore = DispatchSemaphore(value: 0)
        
        var request = URLRequest(url: URL(string: PORTAL_URL)!)
        urlSession.dataTask(with: request) {
            data, response, error in
            defer{semaphore.signal()}
//            LogManager.saveProcessLog(message: "进入登录主页", eventID: self.sessionID)
//            print("进入登录主页")
        }.resume()
        
        semaphore.wait()
        
        let code = getCaptcha()
        
        let rsa = getRSA()
        
        let postData = [
            "code": String(code),
            "rsa": rsa,
            "ul": String(username.count),
            "pl": String(password.count),
            "lt": "LT-1665926-4VCedaEUwbuDuAPI7sKSRACHmInAcl-cas",
            "execution": "e1s1",
            "_eventId": "submit"
        ]
        
        var status: LoginStatus?
        
        request = URLRequest(url: URL(string: PORTAL_URL)!)
        request.encodeParameters(parameters: postData)
        
        urlSession.dataTask(with: request) {
            data, response, error in
            defer{semaphore.signal()}
            LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 正在登录", eventID: self.sessionID)
//            print("正在登录")
            if let data = data, let content = String(data: data, encoding: .utf8) {
                if let doc = try? HTML(html: content, encoding: .utf8) {
                    for err in doc.xpath("//*[@id='errormsg']") {
                        switch err.text {
                        case "用户名密码错误":
                            status = LoginStatus.用户名密码错误
                        case "验证码有误":
                            status = LoginStatus.验证码有误
                        default:
                            status = LoginStatus.未知错误
                        }
                        return
                    }
                    if let realName = doc.xpath("//a[contains(@title, \"查看登录记录\")]/font/text()").first?.text {
                        LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 用户名:" + realName, eventID: self.sessionID)
                        self.realName = realName
//                        print("用户名:" + realName)
                    }
                    status = LoginStatus.成功
                } else {
                    status = LoginStatus.未知错误
                }
            } else {
                status = LoginStatus.未知错误
            }
        }.resume()
        
        semaphore.wait()
        
        defer{
            LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 登录完毕: \(status?.toString() ?? "")", eventID: sessionID)
//            print("登录完毕: \(status?.toString() ?? "")")
        }
        
        if let status = status {
            return status
        } else {
            LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 登录超时", eventID: sessionID)
//            print("登录超时")
            return LoginStatus.未知错误
        }
    }

    private func getCaptcha() -> String{
        LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 获取验证码中", eventID: sessionID)
//        print("获取验证码中")
        let semaphore = DispatchSemaphore(value: 0)
        
        /// Save Captacha to file system.
        var code = "8888"
        
        var request = URLRequest(url: URL(string: CAPTCHA_URL)!)
        urlSession.dataTask(with: request) {
            data, response, error in
            defer{semaphore.signal()}
            
            do {
                let path = CAPTCHA_PATH // 取一个随机名
                let captchaURL = URL(fileURLWithPath: path)
                
                try data!.write(to: captchaURL)
    //            print("验证码已保存: \(path)")
                
                // 利用 Python 识别
                code = runCommand(launchPath: PYTHON3_PATH,
                                  arguments: [RECOGNIZE_PATH,
                                              path,
                                              TESSERACT_PATH])
    //            print("验证码识别完成")
                
                /// 删除已经识别的验证码
                let fileManager = FileManager.default
                try fileManager.removeItem(at: captchaURL)
    //            print("验证码已删除")
            } catch {
                fatalError("\(error)")
            }
        }.resume()
        
        semaphore.wait()
        
        defer {
            LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 获取验证码完毕: \(code)", eventID: sessionID)
//            print("获取验证码完毕: \(code)")
        }
        return code
    }

    private func getRSA() -> String {
        #if !os(Linux)
        let context: JSContext = JSContext()
        context.evaluateScript(desCode)
        
        let squareFunc = context.objectForKeyedSubscript("strEnc")
        
        let rsa = squareFunc?.call(withArguments: [username + password, "1", "2", "3"]).toString() ?? ""
        
        return rsa
        #else
        
        let rsa = runCommand(launchPath: PYTHON3_PATH,
                             arguments: [GETRSA_PATH,
                                         username+password])
        
        return rsa
        #endif
    }

    /// Get semesterID from year and semesterIndex.
    ///
    /// - Parameters:
    ///   - year: A `int` value represents the semester year.  For example: 2019-2020学年 -> year = 2019
    ///   - semesterIndex: A `int` value represents the semester index.  第一学期: 1, 第二学期: 2, 暑学期: 3
    ///
    /// - Returns:       The created semesterID  as `Int`.
    private func getSemesterID(year: Int, semesterIndex: Int) -> Int {
//        print("获取 semesterID 中")
        
        let semesterID = 801 + (year - 2019) * 96 + (semesterIndex - 1) * 32
        
//        defer{print("获取 semesterID 完毕: \(semesterID)")}
        return semesterID
    }

    private func getIDS() -> String{
        LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 获取 IDS 中", eventID: sessionID)
//        print("获取 IDS 中")
        let semaphore = DispatchSemaphore(value: 0)
        
        var ids = ""
        
        var request = URLRequest(url: URL(string: IDS_URL)!)
        urlSession.dataTask(with: request) {
            data, response, error in
            defer{semaphore.signal()}
            
            if let data = data, let content = String(data: data, encoding: .utf8) {
                let re = try! NSRegularExpression(pattern: "bg\\.form\\.addInput\\(form,\"ids\",\"[0-9]*", options: [])
                if let match = re.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.count)) {
                    let re = try! NSRegularExpression(pattern: "[0-9]+", options: [])
                    let substring = (content as NSString).substring(with: match.range)
                    if let match = re.firstMatch(in: substring, options: [], range: NSRange(location: 0, length: substring.count)) {
                        ids = (substring as NSString).substring(with: match.range)
                    }
                }
            }
        }.resume()
        
        semaphore.wait()
        
        LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 获取 IDS 完毕: \(ids)", eventID: sessionID)
//        print("获取 IDS 完毕: \(ids)")
        return ids
    }

    private func getCourseInfoList(semesterID: String, ids: String) -> [Course] {
        LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 获取 CourseInfoList 中", eventID: sessionID)
//        print("获取 CourseInfoList 中")
        let semaphore = DispatchSemaphore(value: 0)
        
        var courseID: [String] = []
        var courseName: [String] = []
        var courseInstructor: [String] = []
        var courses: [Course] = []
        
        let postData = [
            "ignoreHead": "1",
            "setting.kind": "std",
            "startWeek": "1",
            "semester.id": semesterID,
            "ids": ids
        ]
        
        var request = URLRequest(url: URL(string: COURSE_TABLE_URL)!)
        request.encodeParameters(parameters: postData)
        urlSession.dataTask(with: request) {
            data, response, error in
            defer{semaphore.signal()}
            
            if let data = data, let content = String(data: data, encoding: .utf8) {
                /// 获取课程代号
                var re = try! NSRegularExpression(pattern: "<td>[A-Z]{4}[0-9]{10}\\..{2}</td>", options: [])
                for match in re.matches(in: content, options: [], range: NSRange(location: 0, length: content.count)) {
                    let re = try! NSRegularExpression(pattern: "[A-Z]{4}[0-9]{10}\\..{2}", options: [])
                    let substring = (content as NSString).substring(with: match.range)
                    if let match = re.firstMatch(in: substring, options: [], range: NSRange(location: 0, length: substring.count)) {
                        courseID.append((substring as NSString).substring(with: match.range))
                    }
                }
                
                /// 获取课程名称
                re = try! NSRegularExpression(pattern: "\">.*</a></td>", options: [])
                for match in re.matches(in: content, options: [], range: NSRange(location: 0, length: content.count)) {
                    var substring = (content as NSString).substring(with: match.range)
                    substring = (substring as NSString).substring(with: NSRange(location: 2, length: substring.count - 11))
                    courseName.append(substring)
                }
                
                /// 获取任课教师
                re = try! NSRegularExpression(pattern: "\\t\\t<td>.*</td>\\n\\t", options: [])
                for match in re.matches(in: content, options: [], range: NSRange(location: 0, length: content.count)) {
                    var substring = (content as NSString).substring(with: match.range)
                    
                    var re = try! NSRegularExpression(pattern: ">.*<", options: [])
                    if let match = re.firstMatch(in: substring, options: [], range: NSRange(location: 0, length: substring.count)) {
                        substring = (substring as NSString).substring(with: match.range)
                    }
                    
                    re = try! NSRegularExpression(pattern: "<br/>", options: [])
                    substring = re.stringByReplacingMatches(in: substring, options: [], range: NSRange(location: 0, length: substring.count), withTemplate: " ")
                    
                    substring = (substring as NSString).substring(with: NSRange(location: 1, length: substring.count - 2))
                    courseInstructor.append(substring)
                }
            }
        }.resume()
        
        semaphore.wait()
        
        guard courseID.count == courseName.count, courseID.count == courseInstructor.count else {
            return courses
        }
        
        for i in 0..<courseID.count {
            courses.append(Course(courseID: courseID[i], courseName: courseName[i], courseInstructor: courseInstructor[i]))
        }
        
        defer{
            LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 获取 \(courses.map{c in c.courseName}) 完毕", eventID: sessionID)
//            print("获取 \(courses.map{c in c.courseName}) 完毕")
        }
        return courses
    }

    private func getICSCalendar(for courses: [Course], with name: String, in semesterID: String, session: URLSession) -> ICSCalendar{
        LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 制作 ICSCalendar 中", eventID: sessionID)
//        print("制作 ICSCalendar 中")
        let semaphore = DispatchSemaphore(value: 0)
        
        defer{
            LogManager.saveProcessLog(message: "\(self.sessionID)-\(self.realName): 制作 ICSCalendar 完毕", eventID: sessionID)
//            print("制作 ICSCalendar 完毕")
        }
        let calendar = ICSCalendar(name: name)
        
        for course in courses {
            DispatchQueue.global().async {
                defer{semaphore.signal()}
                let postData = [
                    "lesson.semester.id": semesterID,
                    "lesson.no": course.courseID
                ]
                
                let events = self.getICSEvent(for: course, with: postData)
                calendar.append(events: events)
            }
        }
        
        for _ in 0..<courses.count {
            semaphore.wait()
        }
        
        return calendar
    }

    private func getICSEvent(for course: Course, with postData: [String:String]) -> [ICSEvent]{
    //    print("为 \(course.courseName) 制作 ICSEvent 中")
    //    defer{print("为 \(course.courseName) 制作 ICSEvent 完毕")}
        let semaphore = DispatchSemaphore(value: 0)
        var events: [ICSEvent] = []
        
        var request = URLRequest(url: URL(string: COURSE_QUERY_URL)!)
        request.encodeParameters(parameters: postData)
        urlSession.dataTask(with: request) {
            data, response, error in
            defer{semaphore.signal()}
            
            if let data = data, let content = String(data: data, encoding: .utf8) {
                /// 获取星期
                var re = try! NSRegularExpression(pattern: "<td>星期.*</td>", options: [])
                if let match = re.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.count)){
                    let substring = (content as NSString).substring(with: match.range)
                    var lineMatch = (substring as NSString).substring(with: NSRange(location: 4, length: substring.count - 9))
                    
                    re = try! NSRegularExpression(pattern: "<br>", options: [])
                    lineMatch = re.stringByReplacingMatches(in: lineMatch, options: [], range: NSRange(location: 0, length: lineMatch.count), withTemplate: ",")
                    let splitLines = lineMatch.split(separator: ",")
                    
                    for line in splitLines {
                        let line = String(line)
                        let lineRange = NSRange(location: 0, length: line.count)
                        
                        /// 获取时间为星期*
                        let week = (line as NSString).substring(with: NSRange(location: 0, length: 3))
                        // e.g: 星期一
                        let weekOffsetInAWeek = 星期转数字[week]
                        
                        /// 获取上课节数
                        re = try! NSRegularExpression(pattern: "\\d{1,}-\\d{1,}", options: [])
                        let classOffsetMatch = re.firstMatch(in: line, options: [], range: lineRange)!
                        let classOffset = (line as NSString).substring(with: classOffsetMatch.range)
                        // e.g: 1-2 节
                        let split = classOffset.split(separator: "-")
                        let classStartTimeOffset = String(split[0])
                        let classEndTimeOffset = String(split[1])
                        
                        /// 获取上课周数
                        // e.g: [1,2,3,4,5,6,7,8,9]
                        var weekOffsetInASemester: [String] = []
                        
                        // 单周的课
                        re = try! NSRegularExpression(pattern: "\\[\\d{1,}\\]", options: [])
                        for match in re.matches(in: line, options: [], range: lineRange) {
                            var substring = (line as NSString).substring(with: match.range)
                            
                            substring = (substring as NSString).substring(with: NSRange(location: 1, length: substring.count - 2))
                            
                            weekOffsetInASemester.append(substring)
                        }
                        
                        re = try! NSRegularExpression(pattern: "单?双?\\[\\d{1,}-\\d{1,}\\]", options: [])
                        for match in re.matches(in: line, options: [], range: lineRange) {
                            let substring = (line as NSString).substring(with: match.range)
                            
                            re = try! NSRegularExpression(pattern: "\\d{1,}", options: [])
                            let match = re.matches(in: substring, options: [], range: NSRange(location: 0, length: substring.count))
                            
                            let weekFirst = (substring as NSString).substring(with: match[0].range)
                            let weekLast = (substring as NSString).substring(with: match[1].range)
                            
                            if substring.contains(string: "单") || substring.contains(string: "双") {
                                for i in stride(from: Int(weekFirst)!, through: Int(weekLast)!, by: 2) {
                                    weekOffsetInASemester.append(String(i))
                                }
                            } else {
                                for i in Int(weekFirst)!...Int(weekLast)! {
                                    weekOffsetInASemester.append(String(i))
                                }
                            }
                        }
                        
                        /// 获取上课地点
                        re = try! NSRegularExpression(pattern: ".*\\]", options: [])
                        let location = re.stringByReplacingMatches(in: line, options: [], range: lineRange, withTemplate: "").trimmingCharacters(in: .whitespaces)
                        
                        let beginHour = 开始上课时间[classStartTimeOffset]
                        let endHour = 结束上课时间[classEndTimeOffset]
                        let beginMin = (Int(classStartTimeOffset)! % 2 == 0) ? 55 : 00
                        let endMin = (Int(classEndTimeOffset)! % 2 == 0) ? 40 : 45
                        var classTimeBeginDateComp = self.semesterBeginDateComp!
                        var classTimeEndDateComp = self.semesterBeginDateComp!
                        classTimeBeginDateComp.day! += weekOffsetInAWeek!
                        classTimeEndDateComp.day! += weekOffsetInAWeek!
                        classTimeBeginDateComp.hour = beginHour
                        classTimeEndDateComp.hour = endHour
                        classTimeBeginDateComp.minute = beginMin
                        classTimeEndDateComp.minute = endMin
                        
                        for week in weekOffsetInASemester {
                            var classTimeBeginDateComp = classTimeBeginDateComp
                            var classTimeEndDateComp = classTimeEndDateComp
                            classTimeBeginDateComp.day! += (Int(week)! - 1) * 7
                            classTimeEndDateComp.day! += (Int(week)! - 1) * 7
                            
                            let classTimeBeginDate = self.calendar.date(from: classTimeBeginDateComp)
                            let classTimeEndDate = self.calendar.date(from: classTimeEndDateComp)
                            
                            let event = ICSEvent(startDate: classTimeBeginDate!, endDate: classTimeEndDate!, title: course.courseName, location: location, note: course.courseInstructor)
                            event.setAlarm(alarm: ICSEventAlarm(trigger: 30))
                            
                            events.append(event)
                        }
                    }
                }
            }
        }.resume()
        
        semaphore.wait()
        
        return events
    }

}
