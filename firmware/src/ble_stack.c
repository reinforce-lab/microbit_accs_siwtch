//
//  ble_stack.c
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#include <string.h>

#include <ble.h>
#include <ble_gatts.h>
#include <app_error.h>
#include <sdk_errors.h>
#include <softdevice_handler_appsh.h>

#include "ble_stack.h"

// Include or not the service_changed characteristic. if not enabled, the server's database cannot be changed for the lifetime of the device
#define IS_SRVC_CHANGED_CHARACT_PRESENT  1

// セントラル及びペリフェラルとしての、接続数の定義
#define CENTRAL_LINK_COUNT    0
#define PERIPHERAL_LINK_COUNT 1

// GATT MTUサイズの定義, GATT_MTU_SIZE_DEFAULT は ble_gatt.h で23に定義されている。
#define NRF_BLE_MAX_MTU_SIZE GATT_MTU_SIZE_DEFAULT

void init_ble_stack(sys_evt_handler_t systemHandler, ble_evt_handler_t bleHandler)
{
    ret_code_t err_code;
    
    // Initialize the SoftDevice handler module.
    // LFCLK crystal oscillator. 32kHz Xtalなし。内部RC発振回路を使用。
    nrf_clock_lf_cfg_t clock_lf_cfg = {
        .source        = NRF_CLOCK_LF_SRC_RC, //NRF_CLOCK_LF_SRC_XTAL,
        // Calibration timer interval in 1/4 second units (nRF51: 1-64, nRF52: 1-32).
        // この時間間隔は、最大でも0.5度程度の温度変化が起きる程度。
        .rc_ctiv       = 32,
        .rc_temp_ctiv  = 0,
        .xtal_accuracy = NRF_CLOCK_LF_XTAL_ACCURACY_20_PPM // RCでは、このフィールドは無視される。
    };
    
    SOFTDEVICE_HANDLER_APPSH_INIT(&clock_lf_cfg, true);      // BLEのスタックの処理は、スケジューラを使う。
    
    ble_enable_params_t ble_enable_params;
    err_code = softdevice_enable_get_default_config(CENTRAL_LINK_COUNT, PERIPHERAL_LINK_COUNT, &ble_enable_params);
    APP_ERROR_CHECK(err_code);
    
    // Check the ram settings against the used number of links
    CHECK_RAM_START_ADDR(CENTRAL_LINK_COUNT, PERIPHERAL_LINK_COUNT);
    
    // デフォルトのテーブルサイズを設定する。
    ble_enable_params.gatts_enable_params.attr_tab_size   = 0x580;
    ble_enable_params.gatts_enable_params.service_changed = IS_SRVC_CHANGED_CHARACT_PRESENT;

    // Enable BLE stack.
    err_code = softdevice_enable(&ble_enable_params);
    APP_ERROR_CHECK(err_code);
    
    // Register with the SoftDevice handler module for BLE events.
    err_code = softdevice_ble_evt_handler_set(bleHandler);
    APP_ERROR_CHECK(err_code);
    
    // Register with the SoftDevice handler module for BLE events.
    err_code = softdevice_sys_evt_handler_set(systemHandler);
    APP_ERROR_CHECK(err_code);
}
