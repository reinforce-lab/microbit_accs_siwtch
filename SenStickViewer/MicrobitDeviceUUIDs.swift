import Foundation
import CoreBluetooth

public struct MicrobitUUIDs
{
    // アドバタイジングするサービスUUID (コントロールサービス)
//    public static let advertisingServiceUUID:CBUUID    = ControlServiceUUID
    
    // Device information service
    public static let DeviceInformationServiceUUID:CBUUID    = {return CBUUID(string: "180A")}()
    public static let ManufacturerNameStringCharUUID:CBUUID  = {return CBUUID(string: "2A29")}()
    public static let HardwareRevisionStringCharUUID:CBUUID  = {return CBUUID(string: "2A27")}()
    public static let FirmwareRevisionStringCharUUID:CBUUID  = {return CBUUID(string: "2A26")}()
    public static let SerialNumberStringCharUUID:CBUUID      = {return CBUUID(string: "2A25")}()
    
    // Battery service
    public static let BatteryServiceUUID:CBUUID    = {return CBUUID(string: "180F")}()
    public static let BatteryLevelCharUUID:CBUUID  = {return CBUUID(string: "2A19")}()

    // UART service
    public static let NordicUARTServiceUUID:CBUUID        = {return CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")}()
    public static let NordicUARTReadCharUUID:CBUUID       = {return CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")}()
    public static let NordicUARTWriteCharUUID:CBUUID      = {return CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")}()
    
    // デバイスが持つべき、サービスUUIDがキー、キャラクタリスティクスの配列、の辞書を返します。
    public static let MicrobitServiceUUIDs: [CBUUID: [CBUUID]] = [
        DeviceInformationServiceUUID : [ManufacturerNameStringCharUUID, HardwareRevisionStringCharUUID, FirmwareRevisionStringCharUUID, SerialNumberStringCharUUID],
        BatteryServiceUUID: [BatteryLevelCharUUID],
        NordicUARTServiceUUID: [NordicUARTReadCharUUID, NordicUARTWriteCharUUID],
    ]
}
