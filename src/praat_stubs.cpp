// Temporary stub implementations for Praat symbols
// These allow the package to build while we work on full Praat integration

#include <pthread.h>

// Stub for Melder error variables
extern "C" {
pthread_mutex_t theMelder_error_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_t theMelder_error_threadId = 0;
}
