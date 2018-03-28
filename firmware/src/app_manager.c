//
//  app_manager.c
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#include "app_manager.h"
#include "twi_slave_lis3dh.h"

/*
 * Private methods
 */

/*
 * Public methods
 */

void initAppManager(void)
{
    initLIS3DH();
}

void appManagerSleep(void)
{
    
}

void setSensorThreshold(const SensorThreshold *p_threshold)
{
    
}

void getSensorThreshold(SensorThreshold *p_threshold)
{
    
}
