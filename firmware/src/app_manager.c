//
//  app_manager.c
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#include <app_timer_appsh.h>
#include <fstorage.h>
#include <nrf_gpio.h>

#include "util.h"
#include "app_definition.h"
#include "value_type.h"
#include "app_manager.h"
#include "twi_slave_lis3dh.h"
#include "sensor_service.h"

APP_TIMER_DEF(m_timer_id);

static SensorThreshold _threshold;
static int _high_pin_count;
static int _low_pin_count;

// main.cで宣言しているコンテキストを参照する。
extern sensor_service_t sensor_service_context;

// スイッチ出力のばたつき防止の、時定数。
#define COUNT_VALUE 10 // 20ミリ秒 * 10 = 200ミリ秒。

// 関数宣言
static void fs_evt_handler(fs_evt_t const * const evt, fs_ret_t result);
// fstorageの領域確保とイベントハンドラの設定
FS_REGISTER_CFG(fs_config_t fs_config) =
{
    .callback  = fs_evt_handler, // Function for event callbacks.
    .num_pages = 1,              // Number of physical flash pages required.
    .priority  = 0xFE            // Priority for flash usage.
};

#define MAGIC_WORD 0xab

/*
 * Private methods
 */

static void fs_evt_handler(fs_evt_t const * const evt, fs_ret_t result)
{
    if (result != FS_SUCCESS)
    {
        // An error occurred.
        NRF_LOG_PRINTF_DEBUG("error: fs_evt_handler, result:%d.\n", result);
    }
}

static void set_io_value(bool compare_result, uint32_t pin_number, int *p_count)
{
    // 比較した結果がtrueなら、閾値を超えている。カウント値を初期値にする。falseなら、1減算する。
    if(compare_result) {
        *p_count = COUNT_VALUE;
    } else {
        if(p_count > 0) {
            *p_count -= 1;
        }
    }

    // カウント値が0であればLOWに落とす。
    if( p_count == 0 ) {
        nrf_gpio_pin_clear(pin_number);
    } else {
        nrf_gpio_pin_set(pin_number);
    }
}

static void _timer_handler(void *p_arg)
{
    // センサ値を取得。
    AccelerationData_t data;
    getAccelerationData(&data);
    
    // べき乗の和を求める。8ビット精度だから、べき乗して16ビット、3つ足して18ビットに収まる。
    int mag = data.x * data.x + data.y * data.y + data.z * data.z;

    // 閾値を越えているか?
    bool high_compare_result = (mag > (_threshold.highThreshold * _threshold.highThreshold));
    set_io_value(high_compare_result, PIN_HIGH_THRESHOLD, &_high_pin_count);
    
    bool low_compare_result = (mag > (_threshold.lowThreshold * _threshold.lowThreshold));
    set_io_value(low_compare_result, PIN_LOW_THRESHOLD, &_low_pin_count);

    // BLEで通知する。
    uint8_t buff[8];
    int16ToByteArrayLittleEndian(&buff[0], data.x);
    int16ToByteArrayLittleEndian(&buff[2], data.y);
    int16ToByteArrayLittleEndian(&buff[4], data.z);
    buff[6] = high_compare_result;
    buff[7] = low_compare_result;
    sensorServiceNotifyData(&sensor_service_context, buff, sizeof(buff));
}

/*
 * Public methods
 */

void initAppManager(void)
{
    ret_code_t err_code;
    
    // 変数の初期化。
    _threshold.highThreshold = 30; // 2G   / 64mg/digit = 30
    _threshold.lowThreshold  = 20; // 1.3G / 64mg/digit = 20
    _high_pin_count = 0;
    _low_pin_count  = 0;
    
    // フラッシュのアドレスを取得。先頭がマジックワードであれば、設定値として読み出す。
    uint8_t *buffer = (uint8_t *)fs_config.p_start_addr;
    if(buffer[0] == MAGIC_WORD) {
        memcpy(&_threshold, &buffer[1], sizeof(_threshold));
    }
    
    // IO初期化。
    initLIS3DH();
    
    // TWIの電源のIOピン設定, ドライブストレンクスを"強"に
    nrf_gpio_cfg(PIN_HIGH_THRESHOLD,
                 NRF_GPIO_PIN_DIR_OUTPUT,
                 NRF_GPIO_PIN_INPUT_DISCONNECT,
                 NRF_GPIO_PIN_NOPULL,
                 NRF_GPIO_PIN_H0H1,   // 0にハイドライブ、1にハイドライブ
                 NRF_GPIO_PIN_NOSENSE);
    nrf_gpio_cfg(PIN_LOW_THRESHOLD,
                 NRF_GPIO_PIN_DIR_OUTPUT,
                 NRF_GPIO_PIN_INPUT_DISCONNECT,
                 NRF_GPIO_PIN_NOPULL,
                 NRF_GPIO_PIN_H0H1,   // 0にハイドライブ、1にハイドライブ
                 NRF_GPIO_PIN_NOSENSE);
    nrf_gpio_pin_clear(PIN_HIGH_THRESHOLD);
    nrf_gpio_pin_clear(PIN_LOW_THRESHOLD);
    
    // タイマー起動。
    err_code = app_timer_create(&(m_timer_id), APP_TIMER_MODE_REPEATED, _timer_handler);
    APP_ERROR_CHECK(err_code);
    err_code = app_timer_start(m_timer_id,
                               APP_TIMER_TICKS(20, APP_TIMER_PRESCALER), // 1 / 50 秒 = 20ミリ秒
                               NULL);
    APP_ERROR_CHECK(err_code);
}

void appManagerSleep(void)
{
    // 実装すべきだけど、特に何もしないでおく。
}

void setSensorThreshold(const SensorThreshold *p_threshold)
{
    _threshold = *p_threshold;

    // バッファに展開。先頭はマジックワード。
    const int buffer_length = 1 + sizeof(_threshold);
    uint8_t buffer[buffer_length];
    buffer[0] = MAGIC_WORD;
    memcpy(&buffer[1], (uint8_t *)&_threshold, sizeof(_threshold));
    
    // デバイス名の永続化。fstorageのページを消去、後に保存。
    fs_ret_t ret;
    ret = fs_erase(&fs_config, fs_config.p_start_addr, 1, NULL);
    APP_ERROR_CHECK(ret); // FS_SUCCESSは0。APP_ERROR_CHECKで代用する。
    ret = fs_store(&fs_config, fs_config.p_start_addr, (uint32_t *)buffer, sizeof(buffer) / sizeof(uint32_t) + 1, NULL);
    APP_ERROR_CHECK(ret); // FS_SUCCESSは0。APP_ERROR_CHECKで代用する。
}

void getSensorThreshold(SensorThreshold *p_threshold)
{
    *p_threshold = _threshold;
}
