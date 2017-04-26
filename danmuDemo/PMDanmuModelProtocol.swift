//
//  PMDanmuModelProtocol.swift
//  danmuDemo
//
//  Created by idlebook on 2017/4/25.
//  Copyright © 2017年 PM. All rights reserved.
//

import UIKit

@objc protocol PMGDanmuModelDelegate {
 
    @objc optional func attributeContent() -> NSAttributedString
    
    @objc optional func beginTime() -> TimeInterval
    
    @objc optional func liveTime() -> TimeInterval
    
    
}

