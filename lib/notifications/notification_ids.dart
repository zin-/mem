const seed = 10;

int memStartNotificationId(int memId) => memId * seed + 1;

int memEndNotificationId(int memId) => memId * seed + 2;

int memRepeatedNotificationId(int memId) => memId * seed + 3;
