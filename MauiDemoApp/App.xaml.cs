#if IOS
using UIKit;
#endif

namespace MauiDemoApp;

public partial class App : Application
{
	public App(IServiceProvider services)
	{
		InitializeComponent();

#if IOS
        UIApplication.SharedApplication.SetStatusBarStyle(UIStatusBarStyle.LightContent, false);
        UIApplication.SharedApplication.SetStatusBarHidden(false, false);
#endif

		MainPage = new NavigationPage(services.GetRequiredService<MainPage>());
	}
}
