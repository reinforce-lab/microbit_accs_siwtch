#include <string.h>
#include <stdint.h>
#include <stdbool.h>

#include <ble.h>
#include <sdk_errors.h>
#include <nordic_common.h>

#include <nrf_log.h>
#include <nrf_delay.h>
#include <nrf_assert.h>
#include <ble_hci.h>

#include <nrf_nvic.h>
#include <fstorage.h>
#include <ble_conn_state.h>
#include <peer_manager.h>
#include <nrf_log_ctrl.h>

#include <app_scheduler.h>
#include <app_timer_appsh.h>
#include <app_error.h>

#include "util.h"
#include "app_gap.h"
#include "advertising_manager.h"
#include "ble_stack.h"
#include "device_information_service.h"
#include "battery_service.h"
#include "io_definition.h"
#include "ble_parameter_config.h"
#include "app_definition.h"
#include "twi_manager.h"
#include "app_manager.h"
#include "sensor_service.h"

static ble_uuid_t m_advertisiong_uuid;
sensor_service_t sensor_service_context;

// 関数宣言
static void printBLEEvent(ble_evt_t * p_ble_evt);

// Value used as error code on stack dump, can be used to identify stack location on stack unwind.
#define DEAD_BEEF 0xDEADBEEF

// アプリケーションエラーハンドラ
void app_error_fault_handler(uint32_t id, uint32_t pc, uint32_t info)
{
    NRF_LOG_PRINTF_DEBUG("\napp_error: id:0x%08x pc:0x%08x info:0x%08x.", id, pc, info);
    nrf_delay_ms(200);
    
    sd_nvic_SystemReset();
}

// アサーションエラーハンドラ
void assert_nrf_callback(uint16_t line_num, const uint8_t * p_file_name)
{
    NRF_LOG_PRINTF_DEBUG("\nassert_nrf_callback: line:%d file:%s", line_num, (uint32_t)p_file_name);
    app_error_handler(DEAD_BEEF, line_num, p_file_name);
}

// システムイベントをモジュールに分配する。
static void disposeSystemEvent(uint32_t sys_evt)
{
    fs_sys_event_handler(sys_evt);
    ble_advertising_on_sys_evt(sys_evt);
}

// BLEイベントを分配する。
static void diposeBLEEvent(ble_evt_t * p_ble_evt)
{
    ret_code_t err_code;
    
    // Forward BLE events to the Connection State module.
    // This must be called before any event handler that uses this module.
    ble_conn_state_on_ble_evt(p_ble_evt);
    
    // Forward BLE events to the Peer Manager
    pm_on_ble_evt(p_ble_evt);
    
    app_gap_on_ble_event(p_ble_evt);
    ble_advertising_on_ble_evt(p_ble_evt);
    
    handle_battery_service_ble_event(p_ble_evt);
    
    sensorService_handleBLEEvent(&sensor_service_context, p_ble_evt);
    
    printBLEEvent(p_ble_evt);
    
    switch (p_ble_evt->header.evt_id)
    {
            case BLE_GAP_EVT_CONNECTED:
            break;
            
            case BLE_GAP_EVT_DISCONNECTED:
            startAdvertising();
            break;
            
            case BLE_GATTS_EVT_TIMEOUT:

            err_code = sd_ble_gap_disconnect(p_ble_evt->evt.gatts_evt.conn_handle, BLE_HCI_REMOTE_USER_TERMINATED_CONNECTION);
            APP_ERROR_CHECK(err_code);

            break;
            
//nRF52, S132v3
//#if (NRF_SD_BLE_API_VERSION == 3)
//            case BLE_GATTS_EVT_EXCHANGE_MTU_REQUEST:
//            // S132では、ble_gatts.hで、GATT_MTU_SIZE_DEFAULTは、23に定義されている。
//            err_code = sd_ble_gatts_exchange_mtu_reply(p_ble_evt->evt.gatts_evt.conn_handle, GATT_MTU_SIZE_DEFAULT);
//            APP_ERROR_CHECK(err_code);
//            break; // BLE_GATTS_EVT_EXCHANGE_MTU_REQUEST
//#endif
    }
}

// デバッグ用、BLEイベントをprintfします。
static void printBLEEvent(ble_evt_t * p_ble_evt)
{
    switch (p_ble_evt->header.evt_id)
    {
            case BLE_GAP_EVT_CONNECTED:
            NRF_LOG_PRINTF_DEBUG("\nBLE_GAP_EVT_CONNECTED");
            break;
            
            case BLE_GAP_EVT_DISCONNECTED:
            NRF_LOG_PRINTF_DEBUG("\nBLE_GAP_EVT_DISCONNECTED");
            break;
            
            case BLE_GAP_EVT_SEC_PARAMS_REQUEST:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GAP_EVT_SEC_PARAMS_REQUEST.\n  invoked by SMP Paring request, replying parameters.");
            break;
            
            case BLE_GAP_EVT_CONN_SEC_UPDATE:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GAP_EVT_CONN_SEC_UPDATE.\n  Encrypted with STK.");
            break;
            
            case BLE_GAP_EVT_AUTH_STATUS:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GAP_EVT_AUTH_STATUS.");
            break;
            
            case BLE_GAP_EVT_SEC_INFO_REQUEST:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GAP_EVT_SEC_INFO_REQUEST");
            break;
            
            case BLE_EVT_TX_COMPLETE:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_EVT_TX_COMPLETE");
            break;
            
            case BLE_GAP_EVT_CONN_PARAM_UPDATE:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GAP_EVT_CONN_PARAM_UPDATE.");
            break;
            
            case BLE_GATTS_EVT_SYS_ATTR_MISSING:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GATTS_EVT_SYS_ATTR_MISSING.");
            break;
            
            case BLE_GAP_EVT_TIMEOUT:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GAP_EVT_TIMEOUT.");
            break;
            
            case BLE_GATTC_EVT_PRIM_SRVC_DISC_RSP:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GATTC_EVT_PRIM_SRVC_DISC_RSP");
            break;
            case BLE_GATTC_EVT_CHAR_DISC_RSP:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GATTC_EVT_CHAR_DISC_RSP");
            break;
            case BLE_GATTC_EVT_DESC_DISC_RSP:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GATTC_EVT_DESC_DISC_RSP");
            break;
            case BLE_GATTC_EVT_WRITE_RSP:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GATTC_EVT_WRITE_RSP");
            break;
            case BLE_GATTC_EVT_HVX:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GATTC_EVT_HVX");
            break;
            
            case BLE_GATTC_EVT_TIMEOUT:
            //            NRF_LOG_PRINTF_DEBUG("\nBLE_GATTC_EVT_TIMEOUT. disconnecting.");
            break;
            
            case BLE_GATTS_EVT_WRITE:
            //          NRF_LOG_PRINTF_DEBUG("\nBLE_GATTS_EVT_WRITE");
            break;
            
            case BLE_GATTS_EVT_TIMEOUT:
            NRF_LOG_PRINTF_DEBUG("\nBLE_GATTS_EVT_TIMEOUT. disconnecting.");
            break;
            
        default:
            //No implementation needed
            //            NRF_LOG_PRINTF_DEBUG("\nunknown event id: 0x%02x.", p_ble_evt->header.evt_id);
            break;
    }
}

/**
 * main関数
 */
// アドバタイジングを開始する。アドバタイジングするUUIDは以下のベースUUIDの XXXX = 0x2000。
// base UUID: F000XXXX-0451-4000-B000-000000000000
const ble_uuid128_t custom_base_uuid = {
    {   0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0xB0,
        0x00, 0x40,
        0x51, 0x04,
        0x00, 0x00, 0x00, 0xF0 }
};

int main(void)
{
    ret_code_t err_code;
    
    // RTTログを有効に
    NRF_LOG_INIT(NULL);
    
    // タイマーモジュール、スケジューラ設定。
    APP_SCHED_INIT(SCHED_MAX_EVENT_DATA_SIZE, SCHED_QUEUE_SIZE);
    APP_TIMER_APPSH_INIT(APP_TIMER_PRESCALER, APP_TIMER_OP_QUEUE_SIZE, true);
    
    // IO
    initTWIManager();
    
    // fstorageを初期化。device managerを呼び出す前に、この処理を行わなくてはならない。
    err_code = fs_init();
    APP_ERROR_CHECK(err_code);
    
    // スタックの初期化。GAPパラメータを設定
    init_ble_stack(disposeSystemEvent, diposeBLEEvent);
    
    // 128-bit UUIDを登録
    uint8_t    uuid_type;
    err_code = sd_ble_uuid_vs_add(&custom_base_uuid, &uuid_type);
    APP_ERROR_CHECK(err_code);
    
    // 初期設定
    init_app_gap();
    
    // SENSOR_SERVICE_UUID  をアドバタイジングする。
    m_advertisiong_uuid.uuid = 0x2100;
    m_advertisiong_uuid.type = uuid_type;
    init_advertising_manager(&m_advertisiong_uuid);
    
    // BLEサービス
    init_device_information_service();
    init_battery_service();
    initSensorService(&sensor_service_context, uuid_type);
    
    // AppManagerの初期化は、BLEサービスの初期化の後で行うこと。このハンドラは内部でTWIデバイスを初期化する。
    initAppManager();
    
    // アドバタイジングを開始する。
    startAdvertising();
    
    NRF_LOG_PRINTF_DEBUG("Start....\n");
    for (;;) {
        NRF_LOG_FLUSH();
        
        // アプリケーション割り込みイベント待ち (sleep状態)
        err_code = sd_app_evt_wait();
        APP_ERROR_CHECK(err_code);
        
        // スケジューラのタスク実行
        app_sched_execute();
    }
}

