//
//  app_config.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef app_config_h
#define app_config_h

// sdk_config.h に対する差分で設定をまとめる。
// このファイルはsdk_config.hから読み込まれる。そのために、C/C++で、USE_APP_CONFIG を定義しておくこと。

// IO設定を読み込む。
#include "io_definition.h"

#define CRC32_ENABLED       1
#define FSTORAGE_ENABLED    1
#define NRF_QUEUE_ENABLED   1

// ====
// BLE Services
// battery serviceを使う。
#define BLE_BAS_ENABLED 1
// device information serviceを使う。
#define BLE_DIS_ENABLED 1

// nRF51のADCを使用する。
//==========================================================
#define ADC_ENABLED 1

// ===
// TWI。
#define TWI_ENABLED 1
// 周波数。26738688=> 100k, 67108864=> 250k, 104857600=> 400k
//#define TWI_DEFAULT_CONFIG_FREQUENCY 104857600
#define TWI_DEFAULT_CONFIG_FREQUENCY 26738688

// TWI0を使用する。
#define TWI0_ENABLED 1
#define TWI0_USE_EASY_DMA 0

// UARTは使用しない。
#define UART_ENABLED 0

// ===
// ライブラリ。
//#define APP_MAILBOX_ENABLED   1
#define APP_SCHEDULER_ENABLED 1

// ===
// ログ
#define NRF_LOG_ENABLED  1
#define NRF_LOG_DEFERRED 0
#define NRF_LOG_BACKEND_SERIAL_USES_UART 0
#define NRF_LOG_BACKEND_SERIAL_USES_RTT  1
// <0=> Off
// <1=> Error
// <2=> Warning
// <3=> Info
// <4=> Debug
#define NRF_LOG_DEFAULT_LEVEL 4

#endif /* app_config_h */
