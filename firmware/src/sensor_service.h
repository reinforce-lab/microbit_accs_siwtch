//
//  sensor_service.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef sensor_service_h
#define sensor_service_h

#include "util.h"

#define SENSOR_SERVICE_UUID            0x2100
#define SENSOR_DATA_CHAR_UUID          0x7100
#define SENSOR_SETTING_CHAR_UUID       0x7200

// サービスのコンテキスト構造体。サービスの実行に必要な情報が含まれる。
typedef struct sensor_service_s {
    uint16_t connection_handle;
    
    uint16_t service_handle;

    ble_gatts_char_handles_t sensor_data_char_handle;
    ble_gatts_char_handles_t sensor_setting_char_handle;
    
    bool is_sensor_data_notifying;
} sensor_service_t;

// 初期化します
ret_code_t initSensorService(sensor_service_t *p_context, uint8_t uuid_type);

// BLEイベントを受け取ります。
void sensorService_handleBLEEvent(sensor_service_t *p_context, ble_evt_t * p_ble_evt);

// リアルタイムセンサーデータをNotifyします。エラー発生時はfalseを返します。
bool sensorServiceNotifyData(sensor_service_t *p_context, uint8_t *p_data, uint16_t length);

#endif /* sensor_service_h */
