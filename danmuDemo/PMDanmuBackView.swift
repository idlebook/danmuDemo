//
//  PMDanmuBackView.swift
//  danmuDemo
//
//  Created by idlebook on 2017/4/25.
//  Copyright © 2017年 PM. All rights reserved.
//

import UIKit

protocol PMGDanmuBackViewDelegate: class {
    func currentTime() -> TimeInterval
    func danmuViewWithModel(model: PMDanmuModel) -> UIView

}

// MARK:- 常量
private let kLaneCount = 5
private let kCheckTime = 0.1


class PMDanmuBackView: UIView {
    // MARK:- 属性
    /// 是否暂停
    var _isPause: Bool = false
    
    weak var delegate: PMGDanmuBackViewDelegate?
    
    // MARK:- 懒加载
    // 用于记录各个弹道的剩余存活时间(在下一个弹幕发射之前最多存活多少时间,也就是离开弹道所需要的时间)
    fileprivate lazy var laneLiveTimes:  [NSNumber] = {
        var laneLiveTimes: [NSNumber] = Array()
        for i in 0..<kLaneCount{
            laneLiveTimes.append(NSNumber(integerLiteral: 0))
        }
        return laneLiveTimes
    }()
    
    // 用于记录各个弹道的剩余绝对等待时间(在弹幕没有完全进入弹道的时间,也就是刚开始的时候不能碰撞)
    fileprivate lazy var laneWaitTimes: [NSNumber] = {
        var laneWaitTimes: [NSNumber] = Array()
        for i in 0..<kLaneCount{
            laneWaitTimes.append(NSNumber(integerLiteral: 0))
        }

        return laneWaitTimes
    }()
    

    
    fileprivate lazy var danmuViews: [UIView] = {
        var danmuViews: [UIView] = Array()
        return danmuViews
    }()
    
    
    fileprivate lazy var updateTimer: Timer? = {
        let updateTimer = Timer(timeInterval: kCheckTime, repeats: true, block: { _ in
            self.check()
        })
        
        RunLoop.current.add(updateTimer, forMode: .commonModes)
        
        return updateTimer
     
    }()
    
    
    // 弹幕
    public lazy var danmuMs: [PMDanmuModel] = {
        var danmuMs: [PMDanmuModel] = Array()
        return danmuMs
    }()
    
    // MARK:- 系统回调函数
    override func didMoveToSuperview() {
       let _ = self.updateTimer
    }
    
    deinit {
        self.updateTimer?.invalidate()
        updateTimer = nil
    }
    
    
    

}

// MARK:- 对外暴露的方法
extension PMDanmuBackView{
    func pause(){
        if !_isPause{
            _isPause = true
            for item in danmuViews{
                item.layer .pauseAnimate()
            }
            
            // 停止计时器
            updateTimer?.invalidate()
            updateTimer = nil
        }
        
    }
    
    
    
    func resume(){
        if _isPause{
            _isPause = false
            for item in danmuViews{
                item.layer.resumeAnimate()
            }
            // 开启计时器
            updateTimer = Timer(timeInterval: kCheckTime, repeats: true, block: { _ in
                self.check()
            })
            
            RunLoop.current.add(updateTimer!, forMode: .commonModes)
        }
        
    }
    
    
}



extension PMDanmuBackView{
    /// 每秒检查一次
    func check(){
//        print("每秒检查一次-------------------------------")
        // 给每个弹道的存活时间都减去0.1 , 如果减到0 , 则不再减
        for (index, _) in laneLiveTimes.enumerated(){
            if laneLiveTimes[index].doubleValue <= 0{
                laneLiveTimes[index] = NSNumber(integerLiteral: 0)
                continue
            }
            laneLiveTimes[index] = NSNumber(floatLiteral: laneLiveTimes[index].doubleValue - kCheckTime)
        }
        
        // 各个弹道的绝对等待时间
        for (index, _) in laneWaitTimes.enumerated(){
            if laneWaitTimes[index].doubleValue <= 0{
                laneWaitTimes[index] = NSNumber(integerLiteral: 0)
                continue
            }
            laneWaitTimes[index] = NSNumber(floatLiteral: laneWaitTimes[index].doubleValue - kCheckTime)
        }
        
        print(laneLiveTimes)
        
        
        // 对弹幕进行升序
        danmuMs.sort { (obj1, obj2) -> Bool in
            return obj1.beginTime <= obj2.beginTime
        }
        
        // 从第一个弹幕开始遍历,逐个检测是否满足条件
        var deleteModels: [NSNumber] = Array()
        for model in danmuMs {
            guard let currentTime = self.delegate?.currentTime() else {return}
            // 如果没有到达发射时间,那么剩下的也没有办法
            if model.beginTime > currentTime{
                break
            }
            
            // 把这个模型放在每一个弹道里面去检测, 能否发射
            for (index, _) in laneLiveTimes.enumerated(){
                print("index = \(index)")
                let isCanBiu: Bool = checkBiuDanmuWithModel(model: model, index: index)
                if isCanBiu{
                    deleteModels.append(NSNumber(integerLiteral: index))
                    break
                }
                
            }
        }
        
        for item in deleteModels{
            print("item = \(item)")
            
            danmuMs.remove(at: 0)
        }
    }
    
    
    func checkBiuDanmuWithModel(model: PMDanmuModel, index: Int) ->Bool{
        
        let danDaoH = Int(frame.size.height) / kLaneCount * index
        print("danDaoH = \(danDaoH)")
        // 该弹道还有等待时间
        if laneWaitTimes[index].doubleValue > 0.00{
            return false
        }
        
        guard let danmuView = self.delegate?.danmuViewWithModel(model: model) else {return false}
        // 弹幕存活时间
        let danmuLiveTime =  model.liveTime
        // 弹道剩余时间
        let laneLiveTime = self.laneLiveTimes[index].doubleValue
        // 计算速度
        let speed = (bounds.width + (danmuView.bounds.width)) / CGFloat(danmuLiveTime)
        let distance = speed * CGFloat(laneLiveTime)
        if distance > bounds.width {return false}
        
        danmuViews.append(danmuView)
         // 根据弹道索引, 重置剩余时间 + 弹幕完全进入屏幕的时间(重置数据)
        laneLiveTimes[index] = NSNumber(floatLiteral: model.liveTime)
        laneWaitTimes[index] = NSNumber(floatLiteral: Double((danmuView.bounds.width)) / Double(speed))
        
        // 弹幕可以发射
        danmuView.frame.origin = CGPoint(x: frame.size.width, y: CGFloat(danDaoH))
        addSubview(danmuView)
        
        // 移动
        UIView.animate(withDuration: model.liveTime, delay: 0, options: .curveLinear, animations: {
            danmuView.frame.origin.x = -danmuView.bounds.width
        }) { (_) in
            guard let danMuViewIndex = self.danmuViews.index(of: danmuView) else {return}
            self.danmuViews.remove(at: danMuViewIndex)
            danmuView.removeFromSuperview()
        }
        

        return true
    }
}



