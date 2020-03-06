//
//  ResultEntity.swift
//  MyAwesomeProject
//
//  Created by JJAYCHEN on 2020/3/5.
//

import Foundation

struct ResultEntity: Encodable {
    let code: Int;
    let message: String;
    let data: [String: String]
    
    init(code: Int, message: String, data: [String: String]) {
        self.code = code
        self.message = message
        self.data = data
    }
    
    static func success(data: [String: String]) -> ResultEntity {
        ResultEntity(code: 0, message: "success", data: data)
    }
    
    static func fail(message: String) -> ResultEntity {
        ResultEntity(code: -1, message: message, data: [:])
    }
}
