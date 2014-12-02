package net.mkonrad.stillimageprocndkdroid;

public class JNIImgProc {
	static {
		System.loadLibrary("jni_img_proc");
	}
	
	static public native double testFunc(double x, double y);
}
