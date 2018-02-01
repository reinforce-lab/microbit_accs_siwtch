//
//  DeviceListTableViewController.swift
//  MicrobitViewer
//
//  Created by AkihiroUehara on 2016/04/26.
//  Copyright © 2016年 AkihiroUehara. All rights reserved.
//

import UIKit


// デバイスのリストビューを提供します。
// テーブルをぷるすると、BLEデバイスのスキャンを開始して、デバイスリストをリフレッシュします。
// デバイスのセルをタップすると、接続処理が開始され、接続すればデバイス詳細ビューに表示遷移します。

class DeviceListTableViewController: UITableViewController, MicrobitDeviceDelegate {
    
//    var detailViewController: DetailViewController? = nil
    var selectedDevice: MicrobitDevice?
    
    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView.alpha = 1
        self.tableView.isUserInteractionEnabled = true
        
        MicrobitDeviceManager.sharedInstance.addObserver(self, forKeyPath: "devices", options: .new, context:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MicrobitDeviceManager.sharedInstance.removeObserver(self, forKeyPath: "devices")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: refresh event handler
    
    /*@objc*/ @objc func onRefresh()
    {
        MicrobitDeviceManager.sharedInstance.scan(5.0, callback: { (remaining: TimeInterval)  in
            if remaining <= 0 {
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dataview = segue.destination as? SensorDataViewController {
            dataview.device = self.selectedDevice!
        }
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "devices") {
            self.tableView.reloadData()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MicrobitDeviceManager.sharedInstance.devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath) as! DeviceListCellView

        cell.device = MicrobitDeviceManager.sharedInstance.devices[indexPath.row]
        
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedDevice = MicrobitDeviceManager.sharedInstance.devices[indexPath.row]
        
        // 接続していれば画面遷移
        if self.selectedDevice!.isConnected {
            performSegue(withIdentifier: "dataView", sender: self)
        } else {
            // 今のVCを半透明、操作無効
            self.tableView.alpha = 0.5
            self.tableView.isUserInteractionEnabled = false
            self.refreshControl?.endRefreshing()
            
            self.selectedDevice!.delegate = self
            self.selectedDevice!.connect()
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(5 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {
                if !self.selectedDevice!.isConnected {
                    self.selectedDevice!.cancelConnection()
                    self.showAlert()
                }
            })
        }
    }
    
    func showAlert()
    {
        self.tableView.alpha = 1
        self.tableView.isUserInteractionEnabled = true
        
        let alert = UIAlertController(title: "Failed to connect", message: "Failed to connect.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - MicrobitDeviceDelegate
    
    func didServiceFound(_ sender:MicrobitDevice)
    {
    }
    
    func didConnected(_ sender:MicrobitDevice)
    {
        performSegue(withIdentifier: "dataView", sender: self)
    }
    
    func didDisconnected(_ sender:MicrobitDevice)
    {
        showAlert()
    }
}
