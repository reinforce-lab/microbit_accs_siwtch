//
//  app_manager.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef app_manager_h
#define app_manager_h

#include "value_type.h"

void initAppManager(void);

void appManagerSleep(void);

// センサ閾値を設定します。センサ閾値は、内部で永続化されます。
void setSensorThreshold(const SensorThreshold *p_threshold);
// センサ閾値を読み出します。
void getSensorThreshold(SensorThreshold *p_threshold);

#endif /* app_manager_h */
