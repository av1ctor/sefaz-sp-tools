package com.sigapocket;

import android.os.SystemClock;
import android.app.Application;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import com.facebook.react.PackageList;
import com.facebook.react.ReactApplication;
import com.oblador.vectoricons.VectorIconsPackage;
import com.facebook.react.ReactInstanceManager;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactPackage;
import com.facebook.soloader.SoLoader;
import java.lang.reflect.InvocationTargetException;
import java.util.List;
import android.util.Log;

public class MainApplication extends Application implements ReactApplication 
{
	private final ReactNativeHost mReactNativeHost =
		new ReactNativeHost(this) 
		{
			@Override
			public boolean getUseDeveloperSupport() {
				return BuildConfig.DEBUG;
			}

			@Override
			protected List<ReactPackage> getPackages() {
				@SuppressWarnings("UnnecessaryLocalVariable")
				List<ReactPackage> packages = new PackageList(this).getPackages();
				// Packages that cannot be autolinked yet can be added manually here, for example:
				// packages.add(new MyReactNativePackage());
				return packages;
			}

			@Override
			protected String getJSMainModuleName() {
				return "index";
			}
		};

	@Override
	public ReactNativeHost getReactNativeHost() {
		return mReactNativeHost;
	}

	@Override
	public void onCreate() 
	{
		super.onCreate();
		SoLoader.init(this, /* native exopackage */ false);
		initializeFlipper(this, getReactNativeHost().getReactInstanceManager());
		startTimer();
	}

	private static long INTERVAL = 1000 * 60 * 5;

	private void startTimer()
	{
		AlarmManager alarmManager =
			(AlarmManager)getSystemService(Context.ALARM_SERVICE);

		Intent intent = new Intent(this, DocsSyncReceiver.class);
		intent.setAction("com.sigapocket.DOCS_SYNC");

		PendingIntent pendingIntent =
			PendingIntent.getBroadcast(this, 0, intent, PendingIntent.FLAG_CANCEL_CURRENT);

		alarmManager.setRepeating(AlarmManager.RTC_WAKEUP,
			SystemClock.elapsedRealtime() + INTERVAL, INTERVAL, pendingIntent);			
	}

	/**
	 * Loads Flipper in React Native templates. Call this in the onCreate method with something like
	 * initializeFlipper(this, getReactNativeHost().getReactInstanceManager());
	 *
	 * @param context
	 * @param reactInstanceManager
	 */
	private static void initializeFlipper(
		Context context, ReactInstanceManager reactInstanceManager) {
		if (BuildConfig.DEBUG) {
			try {
				/*
					We use reflection here to pick up the class that initializes Flipper,
				since Flipper library is not available in release mode
				*/
				Class<?> aClass = Class.forName("com.sigapocket.ReactNativeFlipper");
				aClass
					.getMethod("initializeFlipper", Context.class, ReactInstanceManager.class)
					.invoke(null, context, reactInstanceManager);
			} catch (ClassNotFoundException e) {
				e.printStackTrace();
			} catch (NoSuchMethodException e) {
				e.printStackTrace();
			} catch (IllegalAccessException e) {
				e.printStackTrace();
			} catch (InvocationTargetException e) {
				e.printStackTrace();
			}
		}
	}
}
