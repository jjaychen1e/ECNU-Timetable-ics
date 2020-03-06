//
//  LoginStatus.swift
//  MyAwesomeProject
//
//  Created by JJAYCHEN on 2020/3/5.
//

import Foundation

enum LoginStatus: Int {
    case 成功 = 0
    case 用户名密码错误 = 1
    case 验证码有误 = 2
    case 未知错误 = 3
    
    func toString() -> String {
        switch self {
        case .成功:
            return "成功"
        case .未知错误:
            return "未知错误"
        case .用户名密码错误:
            return "用户名密码错误"
        case .验证码有误:
            return "验证码有误"
        }
    }
}
