//
//  ICSCalendar.swift
//  ECNU-Timetable-ics
//
//  Created by JJAYCHEN on 2020/3/5.
//

import Foundation

fileprivate struct ICSDateFormatter {
    private static let _dateFormatter = DateFormatter()
    
    static var dateFormatter: DateFormatter {
        get {
            _dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
            return _dateFormatter
        }
    }
}

fileprivate enum ICSTimeZone {
    case Asia_Shanghai
    
    func toString() -> String {
        switch self {
        case .Asia_Shanghai:
            return "Asia/Shanghai"
        }
    }
    
    func toICSDescription() -> String{
        switch self {
        case .Asia_Shanghai:
            return """
            
            X-WR-TIMEZONE:Asia/Shanghai
            CALSCALE:GREGORIAN
            BEGIN:VTIMEZONE
            TZID:Asia/Shanghai
            BEGIN:STANDARD
            TZOFFSETFROM:+0900
            RRULE:FREQ=YEARLY;UNTIL=19910914T170000Z;BYMONTH=9;BYDAY=3SU
            DTSTART:19890917T020000
            TZNAME:GMT+8
            TZOFFSETTO:+0800
            END:STANDARD
            BEGIN:DAYLIGHT
            TZOFFSETFROM:+0800
            DTSTART:19910414T020000
            TZNAME:GMT+8
            TZOFFSETTO:+0900
            RDATE:19910414T020000
            END:DAYLIGHT
            END:VTIMEZONE
            
            """
        }
    }
}

class ICSCalendar {
    var name: String
    
    var prodID: String = "jjacychen.me"
    
    var appleCalendarColor: String = "#B90E28"
    
    fileprivate var timeZone = ICSTimeZone.Asia_Shanghai
    
    var events: [[ICSEvent]] = [[]]
    
    private var eventsDescription: String {
        var description = ""
        for event in events {
            for e in event {
                description += e.toICSDescription()
            }
        }
        return description
    }
    
    init(name: String, prodID: String = "jjachen.me", appleCalendarColor: String = "#B90E28") {
        self.name = name
        self.prodID = prodID
        self.appleCalendarColor = appleCalendarColor
    }
    
    func append(events: [ICSEvent]) {
        self.events.append(events)
    }
    
    func toICSDescription() -> String {
        """
        
        BEGIN:VCALENDAR
        METHOD:PUBLISH
        VERSION:2.0
        X-WR-CALNAME: \(name)
        PRODID:-//\(prodID)
        X-APPLE-CALENDAR-COLOR:\(appleCalendarColor)
        \(timeZone.toICSDescription())
        \(eventsDescription)
        END:VCALENDAR
        
        """
    }
}

class ICSEvent {
    let uuid = UUID()
    let createdDate = Date()
    
    fileprivate var timeZone = ICSTimeZone.Asia_Shanghai
    var startDate: Date
    var endDate: Date
    
    var title: String
    var location: String?
    var note: String?
    
    var alarm: ICSEventAlarm?
    
    init(startDate: Date, endDate: Date, title: String, location: String? = nil, note: String? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.title = title
        self.location = location
        self.note = note
    }
    
    func setAlarm(alarm: ICSEventAlarm) {
        self.alarm = alarm
    }
    
    func toICSDescription() -> String {
        """
        
        BEGIN:VEVENT
        TRANSP:OPAQUE
        DTEND;TZID=\(timeZone.toString()):\(ICSDateFormatter.dateFormatter.string(from: endDate))
        UID:\(uuid.uuidString)
        DTSTAMP:\(ICSDateFormatter.dateFormatter.string(from: createdDate))Z
        LOCATION:\((location != nil) ? location! : "")
        DESCRIPTION:\((note != nil) ? note! : "")
        SEQUENCE:0
        X-APPLE-TRAVEL-ADVISORY-BEHAVIOR:AUTOMATIC
        SUMMARY:\(title)
        LAST-MODIFIED:\(ICSDateFormatter.dateFormatter.string(from: createdDate))Z
        CREATED:\(ICSDateFormatter.dateFormatter.string(from: createdDate))Z
        DTSTART;TZID=\(timeZone.toString()):\(ICSDateFormatter.dateFormatter.string(from: startDate))
        \((alarm != nil) ? alarm!.toICSDescription() : "")
        END:VEVENT
        
        """
    }
}

class ICSEventAlarm {
    let uuid = UUID()
    
    var description = "日程提醒"
    /// - Example: -30 代表提前 30 分钟
    var trigger: Int
    
    init(trigger: Int) {
        self.trigger = trigger
    }
    
    func toICSDescription() -> String {
        """
        
        BEGIN:VALARM
        X-WR-ALARMUID:\(uuid.uuidString)
        UID:\(uuid.uuidString)
        TRIGGER:-PT\(trigger)M
        DESCRIPTION:\(description)
        ACTION:DISPLAY
        END:VALARM
        
        """
    }
}
