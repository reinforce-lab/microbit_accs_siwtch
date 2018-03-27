//
//  io_definition.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef io_definition_h
#define io_definition_h

// 配線(役割)
// IO     In/Out    概要
// P0.0x    In      電源電圧。
#define ADC_INPUT_SUPPLY_MONITORING NRF_ADC_CONFIG_INPUT_0 // AIN_0 ~ 7
// TWI
// P0.6            SDA
// P0.4            SCL
#define PIN_NUMBER_TWI_SDA   6
#define PIN_NUMBER_TWI_SCL   4

// IOポートのアドレス定義
// I2Cバス上の、スレーブ・アドレス
#define TWI_LIS3DH_ADDRESS     0x18 // 00011000 加速度センサ。最下位ビットはピンの値(SA0)で与えられる。この基板はLOW固定。

#endif /* io_definition_h */
