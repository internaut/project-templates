# Must define the LOCAL_PATH and return the current dir
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := jni_img_proc

LOCAL_SRC_FILES := jni_img_proc.cpp

LOCAL_LDLIBS += -llog
include $(BUILD_SHARED_LIBRARY)