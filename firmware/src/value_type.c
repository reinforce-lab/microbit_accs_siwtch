//
//  value_type.c
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/28.
//

#include "value_type.h"

int16_t readInt16AsLittleEndian(const uint8_t *ptr)
{
    return ((int16_t)ptr[0] | (int16_t)ptr[1] << 8);
}

void int16ToByteArrayLittleEndian(uint8_t *p_dst, int16_t src)
{
    p_dst[0] = (0x0ff & (src >> 0));
    p_dst[1] = (0x0ff & (src >> 8));
}

static uint8_t getChecksumOfSensorThreshold(const SensorThreshold *p_data)
{
    int sum = p_data->highThreshold + p_data->lowThreshold;
    uint8_t checksum = (uint8_t)(sum & 0x0f);
    
    return checksum;
}

// 閾値データをバイト配列に展開します。バイト配列は5バイト以上の長さがなければなりません。
// 返り値: 有効なバイト配列の長さを返します。
// フォーマット: highThreshold(下位バイト), highThreshold(上位バイト), lowThreshold(下位バイト), lowThreshold(上位バイト), 上位バイトと下位バイトを足し算したものの下位1バイトの値。
int serializeSensorThreshold(uint8_t *ptr, const SensorThreshold *p_threshold)
{
    int16ToByteArrayLittleEndian(&ptr[0], p_threshold->highThreshold);
    int16ToByteArrayLittleEndian(&ptr[2], p_threshold->lowThreshold);
    ptr[4] = getChecksumOfSensorThreshold(p_threshold);
    
    return 5;
}

// バイト配列を閾値データに展開します。バイト配列のフォーマットが正しくない場合は、SensorThreshold構造体は何も書き込まれません。
bool deSerializeSensorThreshold(SensorThreshold *p_threshold, const uint8_t *ptr)
{
    // バイト配列から読み込む。
    SensorThreshold data;
    data.highThreshold = readInt16AsLittleEndian(&ptr[0]);
    data.lowThreshold  = readInt16AsLittleEndian(&ptr[2]);

    // チェックサムを確認。
    uint8_t checksum = getChecksumOfSensorThreshold(&data);
    bool isMatch = (ptr[4] == checksum);
    if(isMatch) {
        *p_threshold = data;
    }
    
    return isMatch;
}
