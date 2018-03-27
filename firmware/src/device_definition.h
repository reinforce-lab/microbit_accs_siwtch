//
//  device_definition.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef device_definition_h
#define device_definition_h

#define MANUFACTURER_NAME          "unknown"   /* 製造者名 */

//アドバタイジング、GAPのデバイス名
#define DEVICE_NAME                "AccsSwitch"

// ハードウェアバージョン
#define HARDWARE_REVISION_STRING    "rev 1.0"  // ハードウェアのリビジョンを表す文字列。Device Information Serviceで使います。

// ファームウェアは、機能が同じであるならば、同じ番号を用いる。
// FIRMWARE_REVISIONは、ファームウェアのリビジョン。先頭1バイトがメジャーバージョン、後ろ1バイトがマイナーバージョン 0xJJMN の表記。
// FIRMWARE_REVISION_STRINGは、ファームウェアのリビジョンを表す文字列。Device Information Serviceで使います
#define FIRMWARE_REVISION         0x0100
#define FIRMWARE_REVISION_STRING  "rev 1.00"

#endif /* device_definition_h */
