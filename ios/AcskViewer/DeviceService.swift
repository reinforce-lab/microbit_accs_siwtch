//
//  DeviceService.swift
//  SenStickViewer
//
//  Created by akihiro uehara on 2018/01/31.
//  Copyright © 2018年 AkihiroUehara. All rights reserved.
//

import Foundation
import CoreBluetooth

// BLEのサービスを一律して扱うためのプロトコルです。ライブラリを使う側が、使うことはありません。

protocol DeviceService
{
    init?(device: Device)
    
    // 値が更新される都度CBPeripheralDelegateから呼びだされます
    func didUpdateValue(_ characteristic: CBCharacteristic, data:[UInt8])
}
