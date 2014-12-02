#ifndef JNI_IMG_PROC_H
#define JNI_IMG_PROC_H

// the jni library MUST be included
#include <jni.h>

// the log lib is included
#include <android/log.h>

// usage of log
#define LOGINF(...) __android_log_print(ANDROID_LOG_INFO, "jni_img_proc", __VA_ARGS__)
#define LOGERR(...) __android_log_print(ANDROID_LOG_ERROR, "jni_img_proc", __VA_ARGS__)

extern "C" {

/**
 * Grayscale conversion function.
 *
 * Accepts an ARGB "int" array <pixels> and will modify this data in-place.
 */
JNIEXPORT void JNICALL Java_net_mkonrad_stillimageprocndkdroid_JNIImgProc_grayscale(JNIEnv *env, jobject obj, jintArray pixels);

}


#endif
