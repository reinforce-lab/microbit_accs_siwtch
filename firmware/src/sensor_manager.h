//
//  sensor_manager.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef sensor_manager_h
#define sensor_manager_h

typedef struct {
    int highThreshold;
    int lowThreshold;
} SensorThreshold;

// このメソッドを呼ぶ前に、センサマネージャーを初期化します。twi_manager, twi_slave_lis3dh、そして、sensor_serviceのセットアップが完了していなければなりません。
void initSensorManager(void);

// センサ閾値を設定します。センサ閾値は、内部で永続化されます。
void setSensorThreshold(const SensorThreshold *p_threshold);
// センサ閾値を読み出します。
void getSensorThreshold(SensorThreshold *p_threshold);

#endif /* sensor_manager_h */
