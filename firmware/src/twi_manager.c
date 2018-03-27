//
//  twi_manager.c
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#include <string.h>

#include <nrf_drv_twi.h>
#include <nrf_gpio.h>
#include <nrf_delay.h>
#include <sdk_errors.h>
#include <app_error.h>

#include "util.h"
#include "io_definition.h"
#include "sdk_config.h"
#include "twi_manager.h"

// twi0は9軸、twiはその他センサーが接続するバス。
const nrf_drv_twi_t twi0 = NRF_DRV_TWI_INSTANCE(0);

ret_code_t TwiSlave_TX(uint8_t address, uint8_t const *p_data, uint32_t length, bool xfer_pending)
{
    // TWI_MPU9250_ADDRESS, TWI_AK8963_ADDRESS はtwi0, その他はtwi
//    const nrf_drv_twi_t *p_twi = (address == TWI_MPU9250_ADDRESS || address == TWI_AK8963_ADDRESS) ? &twi0 : &twi;
    const nrf_drv_twi_t *p_twi = &twi0;
    ret_code_t err_code = nrf_drv_twi_tx(p_twi, address, p_data, length, xfer_pending);
    if(err_code != NRF_SUCCESS) {
        NRF_LOG_PRINTF_DEBUG("\nTwiSlave_TX(), err:0x%08x address:0x%02x.", err_code, address);
    } else {
        //        NRF_LOG_PRINTF_DEBUG("\nTwiSlave_TX(), address:0x%02x.", address);
    }
    return err_code;
}

ret_code_t TwiSlave_RX(uint8_t address, uint8_t *p_data, uint32_t length)
{
//    const nrf_drv_twi_t *p_twi = (address == TWI_MPU9250_ADDRESS || address == TWI_AK8963_ADDRESS) ? &twi0 : &twi;
    const nrf_drv_twi_t *p_twi = &twi0;
    ret_code_t err_code = nrf_drv_twi_rx(p_twi, address, p_data, length);
    if(err_code != NRF_SUCCESS) {
        NRF_LOG_PRINTF_DEBUG("\nTwiSlave_RX(), err:0x%08x address:0x%02x.", err_code, address);
    } else {
        //        NRF_LOG_PRINTF_DEBUG("\nTwiSlave_RX(), address:0x%02x.", address);
    }
    return err_code;
}

bool writeToTwiSlave(uint8_t twi_address, uint8_t target_register, const uint8_t *data, uint8_t length)
{
    ret_code_t err_code;
    
    // 先頭バイトは、レジスタアドレス
    uint8_t buffer[length + 1];
    buffer[0] = target_register;
    memcpy(&(buffer[1]), data, length);
    
    // I2C書き込み
    err_code = TwiSlave_TX(twi_address, buffer, (length + 1), false);
    return (err_code == NRF_SUCCESS);
}

bool readFromTwiSlave(uint8_t twi_address, uint8_t target_register, uint8_t *data, uint8_t length)
{
    ret_code_t err_code;
    
    // 読み出しターゲットアドレスを設定
    uint8_t buffer0 = target_register;
    err_code = TwiSlave_TX(twi_address, &buffer0, 1, true);
    if(err_code != NRF_SUCCESS) {
        return false;
    }
    
    // データを読み出し
    err_code = TwiSlave_RX(twi_address, data, length);
    
    return (err_code == NRF_SUCCESS);
}

void initTWIManager(void)
{
    // 電源安定、100ms待つ。
    nrf_delay_ms(100);
    
    // TWIインタフェース TWI0および1を使用。
    ret_code_t err_code;
    nrf_drv_twi_config_t config = NRF_DRV_TWI_DEFAULT_CONFIG;
    
    config.scl = PIN_NUMBER_TWI_SCL;
    config.sda = PIN_NUMBER_TWI_SDA;
    err_code = nrf_drv_twi_init(&twi0, &config, NULL, NULL);
    APP_ERROR_CHECK(err_code);
    nrf_drv_twi_enable(&twi0);

}

