//
//  CALayer+Aimate.swift
//  danmuDemo
//
//  Created by idlebook on 2017/4/26.
//  Copyright © 2017年 PM. All rights reserved.
//

import UIKit


extension CALayer{
    
    /// 暂停动画
    func pauseAnimate(){
        let pausedTime = self.convertTime(CACurrentMediaTime(), from: nil)
        self.speed = 0.0
        self.timeOffset = pausedTime
        
    }
    
    /// 恢复动画
    func resumeAnimate(){
        let pausedTime = self.timeOffset
        self.speed = 1.0
        self.timeOffset = 0.0
        self.beginTime = 0.0
        let timeSincePause = self.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        self.beginTime = timeSincePause
    }
}
