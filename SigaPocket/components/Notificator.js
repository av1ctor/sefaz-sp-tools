import PushNotificationIOS from '@react-native-community/push-notification-ios';
import PushNotification from 'react-native-push-notification';

PushNotification.configure({
	onNotification: function (notification) 
	{
		const callback = Notificator.onNotification;
		callback && callback(notification.message);
		notification.finish(PushNotificationIOS.FetchResult.NoData);
	},

	popInitialNotification: true,
	requestPermissions: false,
});

export default class Notificator
{
	static onNotification = null;

	static config(onNotification)
	{
		Notificator.onNotification = onNotification;
	}

	static notify(msg, channelId)
	{
		PushNotification.localNotification({
			channelId: channelId,
			message: msg
		});
	}
}
