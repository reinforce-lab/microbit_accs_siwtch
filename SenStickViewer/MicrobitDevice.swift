import Foundation
import CoreBluetooth

public protocol MicrobitDeviceDelegate : class {
    func didServiceFound(_ sender:MicrobitDevice)
    func didConnected(_ sender:MicrobitDevice)
    func didDisconnected(_ sender:MicrobitDevice)
}

open class MicrobitDevice : NSObject, CBPeripheralDelegate
{
    // MARK: variables
    open unowned let manager: CBCentralManager
    open let peripheral:      CBPeripheral

    open weak var delegate: MicrobitDeviceDelegate?
    
    // MARK: Properties
    open fileprivate(set) var isConnected: Bool
    
    open var name: String
    open fileprivate(set) var identifier: UUID

    open fileprivate(set) var deviceInformationService:   DeviceInformationService?
    open fileprivate(set) var batteryLevelService:        BatteryService?
    open fileprivate(set) var uartService: UARTSerivce?
    
    // MARK: initializer
    init(manager: CBCentralManager, peripheral:CBPeripheral, name: String?)
    {
        self.manager    = manager
        self.peripheral = peripheral
        self.isConnected = false
        self.name        = name ?? peripheral.name ?? ""
        self.identifier  = peripheral.identifier
        
        super.init()

        self.peripheral.delegate = self
        if self.peripheral.state == .connected {
            self.isConnected = true
            findSensticServices()
        }
    }
   
    // Internal , device managerが呼び出します
    internal func onConnected()
    {
        self.isConnected = true
        DispatchQueue.main.async(execute: {
            self.delegate?.didConnected(self)
        })
        
        findSensticServices()
    }
    
    internal func onDisConnected()
    {
        self.isConnected = false
        
        self.deviceInformationService   = nil
        self.batteryLevelService        = nil
        self.uartService = nil
        
        DispatchQueue.main.async(execute: {
            self.delegate?.didDisconnected(self)
        })
    }
    
    // Private methods
    func findSensticServices()
    {
        // サービスの発見
        let serviceUUIDs = Array(MicrobitUUIDs.MicrobitServiceUUIDs.keys)
        peripheral.discoverServices(serviceUUIDs)
    }
    
    // MARK: Public methods
    open func connect()
    {
        if peripheral.state == .disconnected || peripheral.state == .disconnecting {
            manager.connect(peripheral, options:nil)
        }
    }
    
    open func cancelConnection()
    {
        manager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: CBPeripheralDelegate
    
    // サービスの発見、次にキャラクタリスティクスの検索をする
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        // エラーなきことを確認
        if error != nil {
            debugPrint("Unexpected error in \(#function), \(String(describing: error)).")
            return
        }
        
        // FIXME サービスが一部なかった場合などは、どのような処理になる? すべてのサービスが発見できなければエラー?
        for service in peripheral.services! {
            let characteristicsUUIDs = MicrobitUUIDs.MicrobitServiceUUIDs[service.uuid]
            peripheral.discoverCharacteristics(characteristicsUUIDs, for: service)
        }
    }
    
    // サービスのインスタンスを作る
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        // エラーなきことを確認
        if error != nil {
            debugPrint("Unexpected error in \(#function), \(String(describing: error)).")
            return
        }
        
        // FIXME キャラクタリスティクスが発見できないサービスがあった場合、コールバックに通知が来ない。タイムアウトなどで処理する?
//   debugPrint("\(#function), \(service.UUID).")
        // すべてのサービスのキャラクタリスティクスが発見できれば、インスタンスを生成
        switch service.uuid {
        case MicrobitUUIDs.DeviceInformationServiceUUID:
            self.deviceInformationService = DeviceInformationService(device:self)
        case MicrobitUUIDs.BatteryServiceUUID:
            self.batteryLevelService = BatteryService(device:self)
        case MicrobitUUIDs.NordicUARTServiceUUID:
            self.uartService = UARTSerivce(device: self)
            
        default:
            debugPrint("\(#function):unexpected service is found, \(service)" )
            break
        }
        
        DispatchQueue.main.async(execute: {
            self.delegate?.didServiceFound(self)
        })        
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        if error != nil {
            debugPrint("didUpdate: \(characteristic.uuid) \(String(describing: error))")
            return
        }
        
        // キャラクタリスティクスから[UInt8]を取り出す。なければreturn。
        guard let characteristics_nsdata = characteristic.value else { return }
        
        var data = [UInt8](repeating: 0, count: characteristics_nsdata.count)
        (characteristics_nsdata as NSData).getBytes(&data, length: data.count)

//debugPrint("didUpdate: \(characteristic.uuid) \(data)")
        
        switch characteristic.service.uuid {
        case MicrobitUUIDs.DeviceInformationServiceUUID:
            self.deviceInformationService?.didUpdateValue(characteristic, data: data)
        case MicrobitUUIDs.BatteryServiceUUID:
            self.batteryLevelService?.didUpdateValue(characteristic, data: data)
        case MicrobitUUIDs.NordicUARTServiceUUID:
            self.uartService?.didUpdateValue(characteristic, data: data)
            
        default:
            debugPrint("\(#function):unexpected characteristic is found, \(characteristic)" )
            break
        }
    }
    
    open func peripheralDidUpdateName(_ peripheral: CBPeripheral)
    {
        self.name = peripheral.name ?? "(unknown)"
    }
    
    //    optional public func peripheral(peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService])
    //    optional public func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?)
    //    optional public func peripheral(peripheral: CBPeripheral, didDiscoverIncludedServicesForService service: CBService, error: NSError?)
    //    optional public func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    //    optional public func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    //    optional public func peripheral(peripheral: CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    //    optional public func peripheral(peripheral: CBPeripheral, didUpdateValueForDescriptor descriptor: CBDescriptor, error: NSError?)
    //    optional public func peripheral(peripheral: CBPeripheral, didWriteValueForDescriptor descriptor: CBDescriptor, error: NSError?)
}

// サービスなど発見のヘルパーメソッド
extension MicrobitDevice {
    // ペリフェラルから指定したUUIDのCBServiceを取得します
    func findService(_ uuid: CBUUID) -> CBService?
    {
        return (self.peripheral.services?.filter{$0.uuid == uuid}.first)
    }
    // 指定したUUIDのCharacteristicsを取得します
    func findCharacteristic(_ service: CBService, uuid: CBUUID) -> CBCharacteristic?
    {
        return (service.characteristics?.filter{$0.uuid == uuid}.first)
    }
}

// MicrobitServiceが呼び出すメソッド
extension MicrobitDevice {
    // Notificationを設定します。コールバックはdidUpdateValueの都度呼びだされます。初期値を読みだすために、enabeledがtrueなら初回の読み出しが実行されます。
    internal func setNotify(_ characteristic: CBCharacteristic, enabled: Bool)
    {
        peripheral.setNotifyValue(enabled, for: characteristic)
    }
    // 値読み出しを要求します
    internal func readValue(_ characteristic: CBCharacteristic)
    {
        peripheral.readValue(for: characteristic)
    }
    // 値の書き込み
    internal func writeValue(_ characteristic: CBCharacteristic, value: [UInt8])
    {
        let data = Data(bytes: UnsafePointer<UInt8>(value), count: value.count)
//        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
//        peripheral.writeValue( data, forCharacteristic: characteristic, type: .WithoutResponse)
        peripheral.writeValue( data, for: characteristic, type: .withResponse)
//debugPrint("writeValue: \(characteristic.uuid) \(value)")
    }
}
