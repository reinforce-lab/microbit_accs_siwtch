//
//  graphView.swift
//  MicrobitViewer
//
//  Created by AkihiroUehara on 2016/05/24.
//  Copyright © 2016年 AkihiroUehara. All rights reserved.
//

import UIKit


class DataGraphView : UIView {

    // Y軸の最大/最小
    var maxValue : Double = 1.0
    var minValue : Double = 0.0

    // データを追加するときの、今まで追加したデータのカウント
    var nextSamplePoint: Double = 0
    // 1グラフに収めるサンプルカウント数
    var sampleCount: Int = 100 {
        didSet {
            nextSamplePoint = 0
        }
    }
    
    // 描画対象?のフラグ。trueなら描画する。
    var shouldPlot:[Bool]  = [true, true, true]
    
    var value: [[Double]] = [[],[],[]]
    
    // 内部的に、300点までのパスを保持する
    let pathCount :Int = 100
    var pathData :[[CGFloat]] = []
//    let pathColor :[CGColor]  = [UIColor.red.cgColor, UIColor.green.cgColor, UIColor.blue.cgColor]
    /*
     赤＞　#ee6557
     緑＞　#53ba9c
     */
//    let pathColor :[CGColor]  = [ UIColor(red:0.93, green:0.40, blue:0.34, alpha:1.0).cgColor, UIColor(red:0.33, green:0.73, blue:0.61, alpha:1.0).cgColor, UIColor.blue.cgColor]
    let pathColor :[CGColor]  = [ UIColor(red:1.0, green:0.0, blue:0.0, alpha:1.0).cgColor, UIColor(red:0.0, green:1.0, blue:0.0, alpha:1.0).cgColor, UIColor.blue.cgColor]

    func clearPlot()
    {
        pathData = []
        setNeedsDisplay()
    }
    
    // データを描画します 配列は、[x, y, z]を想定。x, もしくはxおよびyのみの利用も可能。
    func plotData(_ value:[[Double]])
    {
        self.value = value
        
        // 再描画
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect)
    {
        super.draw(rect)

        // パスデータを構築
        pathData = [[], [], []]
        // データを間引きながら追加します, 配列の中の配列はそれぞれ軸のデータを表す。
        for (axisIndex, dataArray) in value.enumerated() {
            for i in (0..<dataArray.count) {
                var canAdd = false
                if sampleCount <= pathCount {
                    // そのままデータを追加してOK
                    canAdd = true
                } else {
                    // データ点列をsampleCountの値に合わせて、間引くなりする
                    nextSamplePoint += Double(pathCount) / Double(sampleCount)
                    if nextSamplePoint > 1 {
                        nextSamplePoint -= 1
                        canAdd = true
                    }
                }
                // データを正規化して追加
                if canAdd {
                    let y = CGFloat((dataArray[i] - minValue) / (maxValue - minValue))
                    assert(!y.isNaN)
                    assert(!y.isInfinite)
                    pathData[axisIndex].append(y)
                }
            }
        }
        
        // 描画
        let context = UIGraphicsGetCurrentContext()!
        
        for (index, apath) in pathData.enumerated() {
            // 描画すべきパスがない
            if apath.count == 0 {
                continue
            }
            // 描画対象ではない
            if !self.shouldPlot[index] {
                continue
            }
            
            // 描画色の設定
            // Color Declarations
            let gradientColor = pathColor[index] //UIColor(red: 1.000, green: 0.000, blue: 0.000, alpha: 1.000)
            // Gradient Declarations
            let colors   = [gradientColor, UIColor.white.cgColor]
            let gradient = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: [0.9, 1])!
            
            // ポリゴンを描画
            let polygonPath = UIBezierPath()
            // iOSの描画は左上が原点。だから右下のグラフ原点位置の座標は(0, height)。
            polygonPath.move(to: CGPoint(x:0 ,y:self.frame.height))
            // グラフのギザギザ部分の線分を追加していく。
            let dx = self.frame.width / CGFloat(pathCount)
            for i in 0..<apath.count {
                var y = apath[i] * self.frame.height
                // iOSの描画系は左上が原点なので、y軸を反転する
                y = self.frame.height - y
                let x = CGFloat(i) * dx
                assert(!x.isNaN)
                assert(!y.isNaN)
                polygonPath.addLine(to: CGPoint(x: x, y: y))
            }
            // ポリゴンを閉じるために、下に落とす直線と、原点に戻す直線を追加する。
            polygonPath.addLine(to: CGPoint(x: dx * CGFloat(apath.count), y: self.frame.height)) // グラフ右端の直線。上から下に下ろす。
            polygonPath.addLine(to: CGPoint(x: 0, y: self.frame.height)) // ポリゴンの底辺。グラフ右端から原点に戻す。
            polygonPath.close()
            context.saveGState()
            polygonPath.addClip()
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: self.frame.height), options: [])
            context.restoreGState()
        }
    }
}
