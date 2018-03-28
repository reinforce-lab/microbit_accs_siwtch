//
//  util.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef util_h
#define util_h

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include <ble.h>
#include <ble_srv_common.h>
#include <nrf_assert.h>
#include <sdk_errors.h>
#include <app_error.h>

#include <sdk_config.h>
#include <nrf_log.h>

#ifdef DEBUG
// SDK12をSDK10に合わせるための、マクロ定義
#ifndef NRF_LOG_PRINTF
#define NRF_LOG_PRINTF(...)             NRF_LOG_INTERNAL_DEBUG( __VA_ARGS__)
#endif

#ifndef NRF_LOG_PRINTF_DEBUG
#define NRF_LOG_PRINTF_DEBUG(...)       NRF_LOG_INTERNAL_DEBUG( __VA_ARGS__)
#endif

#else // RELEASE

#ifndef NRF_LOG_PRINTF
#define NRF_LOG_PRINTF(...)
#endif

#ifndef NRF_LOG_PRINTF_DEBUG
#define NRF_LOG_PRINTF_DEBUG(...)
#endif

#endif

#endif /* util_h */
