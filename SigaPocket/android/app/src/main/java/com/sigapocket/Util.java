package com.sigapocket;

import android.os.Bundle;
import android.os.Build;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.graphics.Color;
import androidx.core.app.NotificationCompat;
import androidx.annotation.RequiresApi;
import android.app.Application;
import android.app.ActivityManager;
import android.app.job.JobParameters;
import android.app.job.JobService;
import android.app.job.JobInfo;
import android.app.job.JobScheduler;
import android.content.ComponentName;
import android.content.Intent;
import android.util.Log;

public class Util
{
    public static void scheduleJob(Context context, long seconds, Class klass)
    {
		ComponentName serviceComponent = new ComponentName(context, klass);
        JobInfo.Builder builder = new JobInfo.Builder(0, serviceComponent);
		builder.setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY);
		builder.setMinimumLatency(seconds * 1000);
		builder.setOverrideDeadline((seconds + (seconds / 4)) * 1000);
        JobScheduler jobScheduler = context.getSystemService(JobScheduler.class);
        jobScheduler.schedule(builder.build());		
    }

	@RequiresApi(Build.VERSION_CODES.O)
	public static String createNotificationChannel(
        Context context, String channelId, String channelName)
	{
		NotificationChannel chan = new NotificationChannel(
            channelId, channelName, NotificationManager.IMPORTANCE_NONE);
		chan.setLightColor(Color.BLUE);
		chan.setLockscreenVisibility(Notification.VISIBILITY_PRIVATE);
		NotificationManager service = (NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);
		service.createNotificationChannel(chan);
		return channelId;
	}	

}
