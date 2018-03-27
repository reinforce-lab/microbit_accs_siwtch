//
//  app_definition.h
//  accs_switch
//
//  Created by akihiro uehara on 2018/03/27.
//

#ifndef app_definition_h
#define app_definition_h

#include <app_util.h>
#include <app_timer_appsh.h>

//アプリの動作振る舞いを決めるグローバルな定数を定義します。

// app_timer モジュールのプリスケーラなどの定義
#define APP_TIMER_PRESCALER             0 // Value of the RTC1 PRESCALER register.
#define APP_TIMER_OP_QUEUE_SIZE         8

/* Scheduler のパラメータ */
//  Maximum size of events data in the application scheduler queue aligned to 32 bits
//                                            MAX(BLE_STACK_HANDLER_SCHED_EVT_SIZE)) \

#define SCHED_MAX_EVENT_DATA_SIZE   (CEIL_DIV( \
MAX( \
MAX(sizeof(uint32_t), BLE_STACK_HANDLER_SCHED_EVT_SIZE) \
,APP_TIMER_SCHED_EVT_SIZE) \
, sizeof(uint32_t)) \
* sizeof(uint32_t))

#define SCHED_QUEUE_SIZE                20

#endif /* app_definition_h */
