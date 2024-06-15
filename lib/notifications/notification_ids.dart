// FIXME privateに
const seed = 10;

// FIXME https://github.com/zin-/mem/issues/213
int memStartNotificationId(int memId) => memId * seed + 1;

int memEndNotificationId(int memId) => memId * seed + 2;

int memRepeatedNotificationId(int memId) => memId * seed + 3;

int activeActNotificationId(int memId) => memId * seed + 4;

int pausedActNotificationId(int memId) => memId * seed + 6;

int afterActStartedNotificationId(int memId) => memId * seed + 5;

const reminderNotificationChannelId = 'reminder';
const repeatReminderNotificationChannelId = 'repeat-reminder';
const activeActNotificationChannelId = 'active-act';
const pausedActNotificationChannelId = 'paused-act';
const afterActStartedNotificationChannelId = 'after-act-started';

const doneMemNotificationActionId = 'done-mem';
const startActNotificationActionId = 'start-act';
const finishActiveActNotificationActionId = 'finish-active_act';
const pauseActNotificationActionId = 'pause-act';
