package com.sigapocket;

import android.content.Intent;
import android.os.Bundle;
import android.os.Build;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.graphics.Color;
import androidx.core.app.NotificationCompat;
import androidx.annotation.RequiresApi;
import com.facebook.react.HeadlessJsTaskService;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.jstasks.HeadlessJsTaskConfig;
import javax.annotation.Nullable;
import android.util.Log;

public class DocsSyncService extends HeadlessJsTaskService
{
	@Override
	protected @Nullable HeadlessJsTaskConfig getTaskConfig(Intent intent) 
	{
	  	Bundle extras = intent.getExtras();

		return new HeadlessJsTaskConfig(
			"DocsSyncTask",
			Arguments.fromBundle(extras != null? extras: new Bundle()),
			10000,
			false
		);
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) 
	{
		HeadlessJsTaskConfig taskConfig = getTaskConfig(intent);
		if (taskConfig != null) 
		{
			keepRunning();
			startTask(taskConfig);

			return START_REDELIVER_INTENT;
		}

		return START_NOT_STICKY;
	}

    private void keepRunning()
    {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) 
        {
            NotificationCompat.Builder builder = 
                new NotificationCompat.Builder(
                    this, 
                    Util.createNotificationChannel(
                        this, 
                        "siga-pocket-chan", 
                        "SigaPocket"));
            builder.setPriority(NotificationCompat.PRIORITY_MIN);

            startForeground(1, builder.build());
        }
    }	
}
