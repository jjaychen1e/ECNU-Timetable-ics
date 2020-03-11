//
//  LogManager.swift
//  ECNU-Timetable-ics
//
//  Created by JJAYCHEN on 2020/3/10.
//

import Foundation
import PerfectMySQL
import PerfectLogger

let databaseHost = "127.0.0.1"
let databaseUser = "root"
let databasePassword = "Chen270499"
let databaseSchema = "ecnu_ics_schema"
let databaseTable = "ecnu_ics_table"

class MySQLConnector {
    static func query(statement sql: String) -> (isSuccess: Bool, results: MySQL.Results?) {
        let mysql = MySQL()
        mysql.setOption(.MYSQL_SET_CHARSET_NAME, "utf8")
        
        defer { mysql.close() }
        
        guard mysql.connect(host: databaseHost, user: databaseUser, password: databasePassword, db: databaseSchema) else {
            LogManager.saveProcessLog(message: "数据库连接失败: \(mysql.errorMessage())", eventID: "-1")
            return (false, nil)
        }

        if mysql.query(statement: sql) {
            return (true, mysql.storeResults() ?? nil)
        } else {
            LogManager.saveProcessLog(message: "数据库 Query 失败: \(mysql.errorMessage())", eventID: "-1")
            return (false, nil)
        }
    }
    
    static func getNextSessionID() -> String {
        let sql = """
        select auto_increment from information_schema.`TABLES`
        where table_name='\(databaseTable)'
        """
        
        var nextID: String?
        
        if let results = MySQLConnector.query(statement: sql).results {
            results.forEachRow { row in
                nextID = row[0]!
                return
            }
        }
        
        if let nextID = nextID {
            return nextID
        }
        
        return "-1"
    }
}

class LogManager {
    static func saveProcessLog(message: String, eventID: String) {
        LogFile.info(message, eventid: eventID, logFile: processLogFilePath)
    }
    
    static func saveResultLog(username: String, year: String, semesterIndex: String, description: String, eventID: String) {
        var yearSemesterDescription = ""
        if let yearInt = Int(year) {
            yearSemesterDescription = "\(yearInt)-\(yearInt + 1) 学年第 \(semesterIndex) 学期"
        } else {
            yearSemesterDescription = "\(year) 学年第 \(semesterIndex) 学期"
        }
        
        
        LogFile.info("\(username) 请求生成 \(yearSemesterDescription) 课程表结果为：\(description)", eventid: eventID, logFile: processLogFilePath)
        LogFile.info("\(username) 请求生成 \(yearSemesterDescription) 课程表结果为：\(description)", eventid: eventID, logFile: resultLogFilePath)
        
        if !saveRecord(username: username, year: year, semesterIndex: semesterIndex, description: description) {
            LogFile.info("数据库记录结果失败", eventid: eventID, logFile: processLogFilePath)
            LogFile.info("数据库记录结果失败", eventid: eventID, logFile: resultLogFilePath)
        }
    }
    
    private static func saveRecord(username: String, year: String, semesterIndex: String, description: String) -> Bool{
        let sql = """
        INSERT INTO ecnu_ics_record(username, year, semester_index, description)
        values(\"\(username)\", \"\(year)\", \"\(semesterIndex)\", \"\(description)\")
        """
        
        return MySQLConnector.query(statement: sql).isSuccess
    }
}


