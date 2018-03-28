//
//  value_type.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef value_type_h
#define value_type_h

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

typedef struct SensorThreshold_t {
    int highThreshold;
    int lowThreshold;
} SensorThreshold;

int16_t readInt16AsLittleEndian(const uint8_t *ptr);
void int16ToByteArrayLittleEndian(uint8_t *p_dst, int16_t src);

// 閾値データをバイト配列に展開します。バイト配列は5バイト以上の長さがなければなりません。
// 返り値: 有効なバイト配列の長さを返します。
// フォーマット: highThreshold(下位バイト), highThreshold(上位バイト), lowThreshold(下位バイト), lowThreshold(上位バイト), 上位バイトと下位バイトを足し算したものの下位1バイトの値。
int serializeSensorThreshold(uint8_t *ptr, const SensorThreshold *p_threshold);
// バイト配列を閾値データに展開します。バイト配列のフォーマットが正しくない場合は、SensorThreshold構造体は何も書き込まれません。
bool deSerializeSensorThreshold(SensorThreshold *p_threshold, const uint8_t *ptr);

#endif /* value_type_h */
