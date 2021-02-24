package com.sigapocket;

import android.content.Intent;
import android.os.Bundle;
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
}
