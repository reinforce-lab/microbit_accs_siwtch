import Foundation
import CoreBluetooth

open class MicrobitDeviceManager : NSObject, CBCentralManagerDelegate
{
    let queue: DispatchQueue
    var manager: CBCentralManager?
    
    var scanTimer: DispatchSourceTimer?
    var scanCallback:((_ remaining: TimeInterval) -> Void)?
    
    // Properties, KVO
    @objc dynamic open fileprivate(set) var devices:[MicrobitDevice] = []
    
    @objc dynamic open fileprivate(set) var state: Int = 0
    
    @objc dynamic open fileprivate(set) var isScanning: Bool = false
    
    // Initializer, Singleton design pattern.
    open static let sharedInstance: MicrobitDeviceManager = MicrobitDeviceManager()
    
    fileprivate override init() {
        queue = DispatchQueue(label: "Microbit.ble-queue") // serial queue
        
        super.init()
        
        manager = CBCentralManager.init(delegate: self, queue: queue)
    }
    
    // MARK: Public methods
    
    // 1秒毎にコールバックします。0になれば終了です。
    open func scan(_ duration:TimeInterval = 5.0, callback:((_ remaining: TimeInterval) -> Void)?)
    {
        // デバイスリストをクリアする
        DispatchQueue.main.async(execute: {
            self.devices = []
        })
        
        // スキャン中、もしくはBTの電源がオフであれば、直ちに終了。
        if manager!.isScanning || manager!.state != .poweredOn {
            callback?(0)
            return
        }
        
        // スキャン時間は1秒以上、30秒以下に制約
        let scanDuration = max(1, min(30, duration))
        scanCallback = callback
        
        // 接続済のペリフェラルを取得する
//        for peripheral in (manager!.retrieveConnectedPeripherals(withServices: [MicrobitUUIDs.advertisingServiceUUID])) {
        for peripheral in (manager!.retrieveConnectedPeripherals(withServices: [MicrobitUUIDs.NordicUARTServiceUUID])) {
            addPeripheral(peripheral, name:nil)
        }
        
        // スキャンを開始する。
//        manager!.scanForPeripherals(withServices: [MicrobitUUIDs.advertisingServiceUUID], options: nil)
        manager!.scanForPeripherals(withServices: nil, options: nil)
        isScanning = true
        
        var remaining = scanDuration
        scanTimer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: DispatchQueue.main)
        scanTimer?.schedule(deadline: DispatchTime.now(), repeating: 1.0) // 1秒ごとのタイマー
        scanTimer?.setEventHandler {
            // 時間を-1秒。
            remaining = max(0, remaining - 1)
            if remaining <= 0 {
                self.cancelScan()
            }
            // 継続ならばシグナリング
            self.scanCallback?(remaining)
        }
        scanTimer!.resume()
    }
    
    open func scan(_ duration:TimeInterval = 5.0)
    {
        scan(duration, callback: nil)
    }
    
    open func cancelScan()
    {
        guard manager!.isScanning else { return }
        
        scanTimer!.cancel()
        
        self.scanCallback?(0)
        self.scanCallback = nil
        
        self.manager!.stopScan()
        self.isScanning = false
    }
    
    // CentralManagerにデリゲートを設定して初期状態に戻します。
    // ファームウェア更新などで、CentralManagerを別に渡して利用した後、復帰するために使います。
    open func reset()
    {
        // デバイスリストをクリアする
        DispatchQueue.main.async(execute: {
            self.devices = []
        })

        manager?.delegate = self
    }
    
    // MARK: Private methods
    
    func addPeripheral(_ peripheral: CBPeripheral, name: String?)
    {
        //すでに配列にあるかどうか探す, なければ追加。KVOを活かすため、配列それ自体を代入する
        if !devices.contains(where: { element -> Bool in element.peripheral == peripheral }) {
            var devs = Array<MicrobitDevice>(self.devices)
            devs.append(MicrobitDevice(manager: self.manager!, peripheral: peripheral, name: name))
            DispatchQueue.main.async(execute: {
                self.devices = devs
            })
        }
    }
    
    // MARK: CBCentralManagerDelegate
    open func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        // BLEの処理は独立したキューで走っているので、KVOを活かすためにメインキューで代入する
        DispatchQueue.main.async(execute: {
            // iOS9以前とiOS10以降で、stateの列挙型の型名は異なるが、Intの値と要素はまったく同じ。
            // iOSのバージョンごとにプロパティを分けた場合は、コメントアウトのコードでバージョンに合わせて適合させられるが、使う側からすればややこしいだけか。
            /*
            if #available(iOS 10.0, *) {
                self.state = central.state
            } else { // iOS10以前
                self.centralState = CBCentralManagerState(rawValue:central.state.rawValue) ?? .unknown
            }
             */
            self.state = central.state.rawValue
        })
        
        switch central.state {
        case .poweredOn: break
        case .poweredOff:
            DispatchQueue.main.async(execute: {
                self.devices = []
            })
        case .unauthorized:
            DispatchQueue.main.async(execute: {
                self.devices = []
            })
        case .unknown:
            DispatchQueue.main.async(execute: {
                self.devices = []
            })
        case .unsupported:
            DispatchQueue.main.async(execute: {
                self.devices = []
            })
            break
        default: break
        }
    }
    
    open func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
//        debugPrint("\(#function) \(central).")
        DispatchQueue.main.async(execute: {
            self.addPeripheral(peripheral, name: advertisementData[CBAdvertisementDataLocalNameKey] as? String )
        })
    }
    
    open func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        for device in devices.filter({element -> Bool in element.peripheral == peripheral}) {
            DispatchQueue.main.async(execute: {
                device.onConnected()
            })
        }
    }
    
    open func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        for device in devices.filter({element -> Bool in element.peripheral == peripheral}) {
            DispatchQueue.main.async(execute: {
                device.onDisConnected()
            })
        }
    }
}
