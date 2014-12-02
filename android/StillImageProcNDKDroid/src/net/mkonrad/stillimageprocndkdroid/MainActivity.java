package net.mkonrad.stillimageprocndkdroid;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.ImageView;


public class MainActivity extends Activity {
	private final String TAG = this.getClass().getSimpleName();
	
	private ImageView imgView;
	private Bitmap origImgBm;
	private BitmapDrawable origImgBmDr;
	
	
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
		imgView = (ImageView)findViewById(R.id.img_view);
		
		origImgBm = BitmapFactory.decodeResource(getResources(), R.drawable.leafs_1024x786);
		origImgBmDr = new BitmapDrawable(getResources(), origImgBm);
		imgView.setImageDrawable(origImgBmDr);
		
		imgView.setOnClickListener(new ImageViewClickListener(origImgBm));
    }

	private class ImageViewClickListener implements View.OnClickListener {
		private JNIImgProc imgProc;
		private boolean filtered;
		private Bitmap bitmap;
		private int bitmapW;
		private int bitmapH;
		private int bitmapData[];
		
		
		public ImageViewClickListener(Bitmap bitmap) {
			imgProc = new JNIImgProc();
			bitmapW = bitmap.getWidth();
			bitmapH = bitmap.getHeight();
			bitmapData = new int[bitmapW * bitmapH];
			bitmap.getPixels(bitmapData, 0, bitmapW, 0, 0, bitmapW, bitmapH);
			
			this.filtered = false;
			this.bitmap = bitmap;			
		}
		
		@Override
		public void onClick(View v) {
			ImageView imgView = (ImageView)v;
			Bitmap processedBm;

			if (!filtered) {
				processedBm = Bitmap.createBitmap(
						bitmapW,
						bitmapH,
						Bitmap.Config.ARGB_8888);
				
				imgProc.grayscale(bitmapData);
				processedBm.setPixels(bitmapData, 0, bitmapW, 0, 0, bitmapW, bitmapH);
				
				filtered = true;
			} else {
				processedBm = bitmap;
				filtered = false;
			}

			BitmapDrawable filteredBitmapDrawable = new BitmapDrawable(getResources(), processedBm);
			
			imgView.setImageDrawable(filteredBitmapDrawable);
		}
		
	}
}
