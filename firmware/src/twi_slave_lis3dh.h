//
//  twi_slave_lis3dh.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef twi_slave_lis3dh_h
#define twi_slave_lis3dh_h

#include <stdint.h>
#include <stdbool.h>

// 16ビット 符号付き数値。フルスケールは設定レンジ値による。2, 4, 8, 16G。
typedef struct {
    int16_t x;
    int16_t y;
    int16_t z;
} AccelerationData_t;

// 加速度センサーの範囲設定値。列挙側の値は、BLEでの設定値に合わせている。
typedef enum {
    ACCELERATION_RANGE_2G   = 0x00, // +- 2g
    ACCELERATION_RANGE_4G   = 0x01, // +- 4g
    ACCELERATION_RANGE_8G   = 0x02, // +- 8g
    ACCELERATION_RANGE_16G  = 0x03, // +- 16g
} AccelerationRange_t;

// 初期化関数。センサ使用前に必ずこの関数を呼出ます。初期化に成功すればtrueを返します。
bool initLIS3DH(void);

void sleepLIS3DH(void);
void awakeLIS3DH(void);

void setLIS3DHRange(AccelerationRange_t range);

void getAccelerationData(AccelerationData_t *p_data);

#endif /* twi_slave_lis3dh_h */
