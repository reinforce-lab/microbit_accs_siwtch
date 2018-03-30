//
//  DeviceInformationService.swift
//  MicrobitSDK
//
//  Created by AkihiroUehara on 2016/06/11.
//  Copyright © 2016年 AkihiroUehara. All rights reserved.
//

import Foundation
import CoreBluetooth

// デバイス情報サービスを示します。
// プロパティは、KVO準拠です。
// シリアルナンバーは、デバイスの製造時に書き込まれた唯一の識別子です。

open class DeviceInformationService : NSObject, MicrobitService //, CustomStringConvertible
{
    // Variables
    unowned let device: MicrobitDevice
    
    // Properties, KVO
    @objc dynamic open fileprivate(set) var manufacturerName: String
    @objc dynamic open fileprivate(set) var hardwareRevision: String
    @objc dynamic open fileprivate(set) var firmwareRevision: String
    @objc dynamic open fileprivate(set) var serialNumber:     String
    
    // イニシャライザ
    required public init?(device:MicrobitDevice)
    {
        self.device = device
        
        guard let service = device.findService(MicrobitUUIDs.DeviceInformationServiceUUID) else { return nil }

        // 値を読み出し
        if let char = device.findCharacteristic(service, uuid:MicrobitUUIDs.ManufacturerNameStringCharUUID) {
            device.readValue(char)
        }
        if let char = device.findCharacteristic(service, uuid:MicrobitUUIDs.HardwareRevisionStringCharUUID) {
            device.readValue(char)
        }
        if let char = device.findCharacteristic(service, uuid:MicrobitUUIDs.FirmwareRevisionStringCharUUID) {
            device.readValue(char)
        }
        if let char = device.findCharacteristic(service, uuid:MicrobitUUIDs.SerialNumberStringCharUUID) {
            device.readValue(char)
        }

        self.manufacturerName = ""
        self.hardwareRevision = ""
        self.firmwareRevision = ""
        self.serialNumber     = ""
    }
    
    // 値更新通知
    func didUpdateValue(_ characteristic: CBCharacteristic, data: [UInt8])
    {
        switch characteristic.uuid {
        case MicrobitUUIDs.ManufacturerNameStringCharUUID:
            if let s = String(bytes: data, encoding: String.Encoding.utf8) {
                self.manufacturerName = s
            }
            
        case MicrobitUUIDs.HardwareRevisionStringCharUUID:
            if let s = String(bytes: data, encoding: String.Encoding.utf8) {
                self.hardwareRevision = s
            }
            
        case MicrobitUUIDs.FirmwareRevisionStringCharUUID:
            if let s = String(bytes: data, encoding: String.Encoding.utf8) {
                self.firmwareRevision = s
            }
            
        case MicrobitUUIDs.SerialNumberStringCharUUID:
            if let s = String(bytes: data, encoding: String.Encoding.utf8) {
                self.serialNumber = s
            }
            
        default:
            debugPrint("\(#function): unexpected character: \(characteristic).")
            break
        }
    }
    
    // CustomStringConvertible
    override open var description: String {
        return "Device information: \n  Manufacturer: \(manufacturerName)\n  Hardware revision:\(hardwareRevision)\n  Firmware revision:\(firmwareRevision)\n  Serial number:\(serialNumber)"
    }
}
