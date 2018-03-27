//
//  twi_manager.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef twi_manager_h
#define twi_manager_h

#include <stdint.h>
#include <stdbool.h>

#include <sdk_errors.h>
#include <nrf_drv_twi.h>

void initTWIManager(void);

// TWIバスアクセス
ret_code_t TwiSlave_TX(uint8_t address, uint8_t const *p_data, uint32_t length, bool xfer_pending);
ret_code_t TwiSlave_RX(uint8_t address, uint8_t *p_data, uint32_t length);
bool writeToTwiSlave(uint8_t twi_address, uint8_t target_register, const uint8_t *data, uint8_t length);
bool readFromTwiSlave(uint8_t twi_address, uint8_t target_register, uint8_t *data, uint8_t length);

//extern const nrf_drv_twi_t twi;

#endif /* twi_manager_h */
