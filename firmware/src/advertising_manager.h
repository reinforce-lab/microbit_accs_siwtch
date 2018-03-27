//
//  advertising_manager.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef advertising_manager_h
#define advertising_manager_h

#include <ble.h>
#include <ble_advertising.h>

void init_advertising_manager(ble_uuid_t *p_uuid);
void startAdvertising(void);
void stopAdvertising(void);

#endif /* advertising_manager_h */
