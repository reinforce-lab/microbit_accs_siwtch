//
//  sensor_manager.c
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#include "sensor_manager.h"

// 機能
// 1. 加速度センサーの加速度データを、一定周期で読み出します。
// 2. センササービスに、読み出した加速度の値を通知します。
// 3. 加速度の値と閾値とを比較して、GPIOのLOW/HIGHを設定します。
// 4. 閾値を永続化します。

/*
 * Private methods
 */

/*
 * Public methods
 */
void initSensorManager(void)
{}
