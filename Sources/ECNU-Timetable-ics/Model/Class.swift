//
//  Class.swift
//  ECNU-Timetable-ics
//
//  Created by JJAYCHEN on 2020/3/8.
//

struct Course {
    let courseID: String
    let courseName: String
    let courseInstructor: String
    
    init(courseID: String, courseName: String, courseInstructor: String) {
        self.courseID = courseID
        self.courseName = courseName
        self.courseInstructor = courseInstructor
    }
}
