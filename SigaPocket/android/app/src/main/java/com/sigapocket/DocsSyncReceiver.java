package com.sigapocket;

import java.util.List;
import android.app.Application;
import android.app.ActivityManager;
import android.content.Context;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import com.facebook.react.HeadlessJsTaskService;
import android.util.Log;

public class DocsSyncReceiver extends BroadcastReceiver 
{
	@Override
	public void onReceive(final Context context, final Intent intent) 
	{
		try
		{
			if(isAppOnForeground(context)) 
			{
				return;
			}
				
			Intent serviceIntent = new Intent(context, DocsSyncService.class);
			context.startService(serviceIntent);
			HeadlessJsTaskService.acquireWakeLockNow(context);
		}
		catch(Exception e)
		{
			Log.e("DocsSyncReceiver", e.getMessage());
		}
	}

	private boolean isAppOnForeground(Context context) 
	{
		/**
			 We need to check if app is in foreground otherwise the app will crash.
			http://stackoverflow.com/questions/8489993/check-android-application-is-in-foreground-or-not
		**/
		ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
		List<ActivityManager.RunningAppProcessInfo> appProcesses =
		activityManager.getRunningAppProcesses();
		if (appProcesses == null) {
			return false;
		}
		final String packageName = context.getPackageName();
		for (ActivityManager.RunningAppProcessInfo appProcess : appProcesses) {
			if (appProcess.importance ==
			ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
				appProcess.processName.equals(packageName)) {
				return true;
			}
		}
		return false;
	}
}
