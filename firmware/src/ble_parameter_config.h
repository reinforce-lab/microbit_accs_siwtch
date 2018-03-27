//
//  ble_parameter_config.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef ble_parameter_config_h
#define ble_parameter_config_h

#include <ble_gap.h>

// コネクションパラメータモジュールの設定値
// アドバタイジング:
//  1. 30秒間  インターバル 100ミリ秒
//  2. 150秒間 インターバル 1秒
//  3. 停止 (スリープ)

#define ADV_FAST_INTERVAL_0625UNIT      (640)  // 400ミリ秒。アドバタイジング・インターバルは、0.625ミリ秒単位で指定する。
#define ADV_FAST_TIMEOUT_SEC            (30)

#define ADV_SLOW_INTERVAL_0625UNIT      (1600) // 1000ミリ秒 / 0.625ミリ秒 = 1600
#define ADV_SLOW_TIMEOUT_SEC            (600)

// コネクション・インターバル
// min:60ミリ秒 max:240ミリ秒
// super vision timeout 4000ミリ秒
// slave latency 0

#define DEFAULT_MIN_CONN_INTERVAL_MILLISEC      (60)
#define DEFAULT_MAX_CONN_INTERVAL_MILLISEC      (240)
#define DEFAULT_SLAVE_LATENCY                   0
#define DEFAULT_CONN_SUP_TIMEOUT_MILISEC        (4 * 1000)

// セキュリティ・パラメータ
#define SEC_PARAM_BOND                   0                                          /**< Perform bonding. */
#define SEC_PARAM_MITM                   0                                          /**< Man In The Middle protection not required. */
#define SEC_PARAM_LESC                   0                     // Enable LE Secure Connection pairing.
#define SEC_PARAM_KEYPRESS               0                     // Enable generation of keypress notifications.
#define SEC_PARAM_IO_CAPABILITIES        BLE_GAP_IO_CAPS_NONE                       /**< No I/O capabilities. */
#define SEC_PARAM_OOB                    0                                          /**< Out Of Band data not available. */
#define SEC_PARAM_MIN_KEY_SIZE           7                                          /**< Minimum encryption key size. */
#define SEC_PARAM_MAX_KEY_SIZE           16                                         /**< Maximum encryption key size. */


#endif /* ble_parameter_config_h */
