//
//  twi_slave_lis3dh.c
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#include <string.h>
#include <stdint.h>
#include <stdbool.h>

#include <nrf_delay.h>
#include <nrf_assert.h>
#include <app_error.h>
#include <sdk_errors.h>

#include "twi_manager.h"
#include "twi_slave_lis3dh.h"

#include "util.h"
#include "value_type.h"
#include "io_definition.h"

// レジスタ仕様書
// LIS3DH
// December 2016 DocID17530 Rev 2

// レジスタアドレスの列挙型
typedef enum {
    STATUS_REG_AUX  = 0x07,
    OUT_ADC1_L      = 0x08,
    OUT_ADC1_H      = 0x09,
    OUT_ADC2_L      = 0x0A,
    OUT_ADC2_H      = 0x0B,
    OUT_ADC3_L      = 0x0C,
    OUT_ADC3_H      = 0x0D,
    
    WHO_AM_I        = 0x0F,
    
    CTRL_REG0       = 0x1E,
    TEMP_CFG_REG    = 0x1F,
    CTRL_REG1       = 0x20,
    CTRL_REG2       = 0x21,
    CTRL_REG3       = 0x22,
    CTRL_REG4       = 0x23,
    CTRL_REG5       = 0x24,
    CTRL_REG6       = 0x25,
    REFERENCE       = 0x26,
    STATUS_REG      = 0x27,
    OUT_X_L         = 0x28,
    OUT_X_H         = 0x29,
    OUT_Y_L         = 0x2A,
    OUT_Y_H         = 0x2B,
    OUT_Z_L         = 0x2C,
    OUT_Z_H         = 0x2D,
    FIFO_CTRL_REG   = 0x2E,
    FIFO_SRC_REG    = 0x2F,
    INT1_CFG        = 0x30,
    INT1_SRC        = 0x31,
    INT1_THS        = 0x32,
    INT1_DURATION   = 0x33,
    INT2_CFG        = 0x34,
    INT2_SRC        = 0x35,
    INT2_THS        = 0x36,
    INT2_DURATION   = 0x37,
    CLICK_CFG       = 0x38,
    CLICK_THS       = 0x3A,
    TIME_LIMIT      = 0x3B,
    TIME_LATENCY    = 0x3C,
    TIME_WINDOW     = 0x3D,
    ACT_THS         = 0x3E,
    ACT_DUR         = 0x3F,
    
} LIS3DHRegister_t;

/**
 * private methods
 */

// TWI_LIS3DH_ADDRESS は senstick_io_definitions.h で定義されているI2Cバスのアドレスです。
static bool writeToLIS3DH(LIS3DHRegister_t target_register, const uint8_t *data, uint8_t data_length)
{
    return writeToTwiSlave(TWI_LIS3DH_ADDRESS, (uint8_t)target_register, data, data_length);
}

// LIS3DHから読み込みます。
static void readFromLIS3DH(LIS3DHRegister_t target_register, uint8_t *data, uint8_t data_length)
{
    readFromTwiSlave(TWI_LIS3DH_ADDRESS, (uint8_t)target_register, data, data_length);
}

/**
 * public methods
 */

bool initLIS3DH(void)
{
    uint8_t data;
    // WHO_AM_I (0fh)
    // 固定値 0x33 が読みだせる。
    readFromLIS3DH(WHO_AM_I, &data, sizeof(data));
    if( data != 0x33 ) {
        NRF_LOG_PRINTF_DEBUG("Error in reading LIS3DH who am I register.\n");
    }

    // CTRL_REG0
    // D7: SDO_PU_DISC  Disconnect SDO/SA0 pull-up, default value: 0.
    // D[6:0]           固定値 0010000
    // SA0は、GNDに落としている。SA0のプルアップ抵抗の電流をカットする。
    // 1001_0000 = 0x90
    const uint8_t ctrl_reg0_data[] = {0x90};
    writeToLIS3DH(CTRL_REG0, ctrl_reg0_data, sizeof(ctrl_reg0_data));

    // CTRL_REG1
    // D[7:4]   ODR[3:0]    Data rate selection.
    // ODR[3:0] Power mode selection
    // 0 0 0 0  Power-down mode
    // 0 0 0 1  HR / Normal / Low-power mode (1 Hz)
    // 0 0 1 0  HR / Normal / Low-power mode (10 Hz)
    // 0 0 1 1  HR / Normal / Low-power mode (25 Hz)
    // 0 1 0 0  HR / Normal / Low-power mode (50 Hz)
    // 0 1 0 1  HR / Normal / Low-power mode (100 Hz)
    // 0 1 1 0  HR / Normal / Low-power mode (200 Hz)
    // 0 1 1 1  HR / Normal / Low-power mode (400 Hz)
    // 1 0 0 0  Low power mode (1.60 kHz)
    // 1 0 0 1  HR / normal (1.344 kHz); Low-power mode (5.376 kHz)
    //
    // D3       LPen        Low-power mode enable. 1: low-power mode.
    // D2       Zen         Z-axis enable.
    // D1       Yen
    // D0       Xen
    //
    // Data rate 100Hz, 0101
    // Low-power mode, 1
    // Z,Y,X enabled    111
    // 0101_1111 = 0x5f
    const uint8_t ctrl_reg1_data[] = {0x5f};
    writeToLIS3DH(CTRL_REG1, ctrl_reg1_data, sizeof(ctrl_reg1_data));
    
    // CTRL_REG4
    // D7: BDU  Block data update, default value: 0, 0: continus update
    // D6: BLE  Big/little endian data selection, default value: 0.
    // D[5:4]: FS[1:0]  Fll-scale selection. default value: 00.
    //  00 +-2g, 01:+-4g, 10:+- 8g, 11: +-16g
    // D3   HR  High-resolution output mode
    // D[2:1]   ST[1:0]     Self-test enabled. default value: 00.
    // D0:  SIM SPI serial interface mode selection. default value: 0.
    //
    // range: +-8g
    // 0010_0000 = 0x20
    const uint8_t ctrl_reg4_data[] = {0x20};
    writeToLIS3DH(CTRL_REG4, ctrl_reg4_data, sizeof(ctrl_reg4_data));
    
    return true;
}

void setLIS3DHRange(AccelerationRange_t range)
{
    //    Register 28 – Accelerometer Configuration
    //    ACCEL_CONFIG    = 0x1c,
    //
    //    7     ax_st_en, X Accel self-test//
    //    6     ay_st_en, Y Accel self-test
    //    5     az_st_en, Z Accel self-test
    //    [4:3] ACCEL_FS_SEL[1:0]
    //              Accel Full Scale Select:
    //              ±2g (00), ±4g (01), ±8g (10), ±16g (11)
    //    [2:0]
    
//    uint8_t value = 0;
//
//    switch (range) {
//            case ACCELERATION_RANGE_2G: value = 0x00 << 3; break;
//            case ACCELERATION_RANGE_4G: value = 0x01 << 3; break;
//            case ACCELERATION_RANGE_8G: value = 0x02 << 3; break;
//            case ACCELERATION_RANGE_16G:value = 0x03 << 3; break;
//        default: break;
//    }
//
//    uint8_t data[] = {value};
//    writeToLIS3DH( ACCEL_CONFIG, data, sizeof(data));
}

void getAccelerationData(AccelerationData_t *p_acceleration)
{
    // 加速度のデータは一連の連続するアドレスから読み出す。
//    OUT_X_L         = 0x28,
//    OUT_X_H         = 0x29,
//    OUT_Y_L         = 0x2A,
//    OUT_Y_H         = 0x2B,
//    OUT_Z_L         = 0x2C,
//    OUT_Z_H         = 0x2D,
    uint8_t buffer[6];
    readFromLIS3DH(OUT_X_L, buffer, sizeof(buffer));
    p_acceleration->x = readInt16AsLittleEndian(&(buffer[0]));
    p_acceleration->y = readInt16AsLittleEndian(&(buffer[2]));
    p_acceleration->z = readInt16AsLittleEndian(&(buffer[4]));
}
