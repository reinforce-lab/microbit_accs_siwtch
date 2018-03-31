//
//  SensorDataViewController.swift

//
//  Created by AkihiroUehara on 2016/05/22.
//  Copyright © 2016年 AkihiroUehara. All rights reserved.
//

import UIKit

import CoreMotion

// センサデバイスの、センサデータ一覧を提供します。

class SensorDataViewController : UITableViewController, DeviceDelegate, UISplitViewControllerDelegate, SensorSerivceDelegate {
    
    @IBOutlet var deviceInformationButton: UIBarButtonItem!

    @IBOutlet var highSlider: UISlider!
    @IBOutlet var lowSlider: UISlider!
    
    @IBOutlet var highThresholdLabel: UILabel!
    @IBOutlet var lowThresholdLabel: UILabel!
    
    var device: Device?
    var dataCell: SensorDataCellView?
    var dataArray:[[Double]]   = [[], [], []]
    var switchCell: SensorDataCellView?
    var switchArray:[[Double]] = [[], []]
    
//    var statusCell:             SensorStatusCellView?
//    var accelerationDataModel:  AccelerationDataModel?
//    var gyroDataModel:          GyroDataModel?
//    var magneticFieldDataModel: MagneticFieldDataModel?
//    var brightnessDataModel:    BrightnessDataModel?
//    var uvDataModel:            UVDataModel?
//    var humidityDataModel:      HumidityDataModel?
//    var pressureDataModel:      PressureDataModel?
//    var extendedTemperatureDataModel: ExtendedTemperatureDataModel?
    
    // MARK: - View life cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
//        accelerationDataModel  = AccelerationDataModel()
//        gyroDataModel          = GyroDataModel()
//        magneticFieldDataModel = MagneticFieldDataModel()
//        brightnessDataModel    = BrightnessDataModel()
//        uvDataModel            = UVDataModel()
//        humidityDataModel      = HumidityDataModel()
//        pressureDataModel      = PressureDataModel()
//        extendedTemperatureDataModel = ExtendedTemperatureDataModel()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        device?.delegate = self
        device?.connect()
        if device != nil {
            didServiceFound(device!)
        }
        
        self.splitViewController?.delegate = self
        
        // 右上のバーボタンアイテムのenable設定。ログ停止中のみ遷移可能
        /*
         if let control = device?.controlService {
         self.deviceInformationButton.enabled = (control.command == .Stopping)
         } else {
         self.deviceInformationButton.enabled = false
         }*/
    }
    
    // UISplitViewControllerDelegate
    public func splitViewController(_ splitViewController: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool
    {
        return true
    }
    
    // Override this method to customize the behavior of `showDetailViewController:` on a split view controller. Return YES to indicate that you've
    // handled the action yourself; return NO to cause the default behavior to be executed.
    public func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool
    {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        device?.delegate = nil
        
        // リスト表示に戻る場合は、デバイスとのBLE接続を切る
        if let backToListView = self.navigationController?.viewControllers.contains(self) {
            // ListViewに戻る時、ナビゲーションに自身が含まれていない。
            if backToListView == false {
                device?.cancelConnection()
            }
        }
    }

    // MARK: - Public methods
    
    func clearGraph()
    {
//        accelerationDataModel?.clearPlot()
//        gyroDataModel?.clearPlot()
//        magneticFieldDataModel?.clearPlot()
//        brightnessDataModel?.clearPlot()
//        uvDataModel?.clearPlot()
//        humidityDataModel?.clearPlot()
//        pressureDataModel?.clearPlot()
//        extendedTemperatureDataModel?.clearPlot()
    }

    // MARK: - DeviceDelegate
    
    func didServiceFound(_ sender: Device) {
        device?.sensorService?.delegate = self
//        self.statusCell?.name       = device?.name
//        self.statusCell?.service    = device?.controlService
        
//        accelerationDataModel?.service  = device?.accelerationSensorService
//        gyroDataModel?.service          = device?.gyroSensorService
//        magneticFieldDataModel?.service = device?.magneticFieldSensorService
//        brightnessDataModel?.service    = device?.brightnessSensorService
//        uvDataModel?.service            = device?.uvSensorService
//        humidityDataModel?.service      = device?.humiditySensorService
//        pressureDataModel?.service      = device?.pressureSensorService
//        extendedTemperatureDataModel?.service = device?.extendedTemperatureSensorService
//        extendedTemperatureDataModel?.maxValue = 45
//        extendedTemperatureDataModel?.minValue = 15
    }
    
    func didConnected(_ sender:Device)
    {
    }
    
    func didDisconnected(_ sender:Device)
    {
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: - SensorSerivceDelegate
    func didThresholdUpdate(_ sender: SensorSerivce, highThreshold: Int, lowThreshold: Int)
    {
        self.highSlider.value = Float(highThreshold)
        self.lowSlider.value  = Float(lowThreshold)
        updateThreshold()
    }
    
    func didUpdate(_ sender: SensorSerivce, data: SensorData)
    {
        dataArray[0].append(Double(data.Acceleration))
        if dataArray[0].count > 100 {
            dataArray[0].remove(at: 0)
//            dataArray[1].remove(at: 0)
//            dataArray[2].remove(at: 0)
        }
        self.dataCell?.graphView?.plotData(dataArray)

        switchArray[1].append(Double(data.HighThresholdOutput) * 2)
        switchArray[0].append(Double(data.LowThresholdOutput))
        if switchArray[0].count > 100 {
            switchArray[0].remove(at: 0)
            switchArray[1].remove(at: 0)
        }
        self.switchCell?.graphView?.plotData(switchArray)
    }
        
    // MARK: - Private methods
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        switch ((indexPath as NSIndexPath).row) {
        case 0:
            self.dataCell = (cell as? SensorDataCellView)!
            self.dataCell?.graphView?.shouldPlot = [true, false, false]
            self.dataCell?.graphView?.maxValue   = 8000
            self.dataCell?.graphView?.minValue   = 0

        case 1:
            self.switchCell = (cell as? SensorDataCellView)!
            self.switchCell?.graphView?.shouldPlot = [true, true, false]
            self.switchCell?.graphView?.maxValue   =  2.5
            self.switchCell?.graphView?.minValue   = -0.2
            device?.sensorService?.readThreshold()

        default: break
        }
    }
    
    @IBAction func didHighThresholdValueChanged(_ sender: UISlider)
    {
        // HIGH/LOW閾値の大小関係を保たせる。HIGHを下げているなら、LOWをその分、下げる。
        if( self.highSlider.value < self.lowSlider.value ) {
            self.lowSlider.value = self.highSlider.value
        }
        updateThreshold()
    }
    
    @IBAction func didLowThresholdValueChanged(_ sender: UISlider)
    {
        // HIGH/LOW閾値の大小関係を保たせる。Lowを持ち上げているなら、HIGHをその分、持ち上げる。
        if( self.lowSlider.value > self.highSlider.value ) {
            self.highSlider.value = self.lowSlider.value
        }
        updateThreshold()
    }

    func updateThreshold()
    {
        self.device?.sensorService?.updateThreshold(highThreshold: Int(self.highSlider.value), lowThreshold: Int(self.lowSlider.value))
        self.highThresholdLabel.text = "\(Int(highSlider.value))"
        self.lowThresholdLabel.text  = "\(Int(lowSlider.value))"
    }
    
    // MARK: - Segues
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        // デバイス詳細情報表示に遷移
        if identifier == "deviceInformation" {
            return (device?.deviceInformationService != nil)
        }
        
        // 詳細表示遷移できるのはログ停止時だけ
//        if let control = device?.controlService {
//            return (control.command == .stopping)
//        } else {
//            return false
//        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
//        if let vc = segue.destination as? DeviceInformationViewController {
//            vc.device = self.device
//        }
        
//        if let vc = segue.destination as?  LogListViewController {
//            vc.device = self.device
//        }
        
        //        debugPrint("  \(segue.destinationViewController)")
//        if let vc = segue.destination as? SamplingDurationViewController {
//            let indexPath = self.tableView.indexPathForSelectedRow!
//            switch((indexPath as NSIndexPath).row) {
//            case 1:
//                vc.target = device?.accelerationSensorService
//            case 2:
//                vc.target = device?.extendedTemperatureSensorService
//            default: break
//            }
//        }
    }
}
