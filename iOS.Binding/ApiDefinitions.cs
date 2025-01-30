using Foundation;
using UIKit;
using ObjCRuntime;

namespace iOS.Binding
{
	// @interface CemRendererResultObjc : NSObject
	[BaseType (typeof(NSObject))]
	[DisableDefaultCtor]
	interface CemRendererResultObjc
	{
		// @property (readonly, nonatomic) enum ResultTypeObjc type;
		[Export ("type")]
		ResultTypeObjc Type { get; }

		// @property (readonly, nonatomic, strong) NSNumber * _Nullable code;
		[NullAllowed, Export ("code", ArgumentSemantic.Strong)]
		NSNumber Code { get; }

		// @property (readonly, copy, nonatomic) NSString * _Nullable toolName;
		[NullAllowed, Export ("toolName")]
		string ToolName { get; }

		// @property (readonly, copy, nonatomic) NSString * _Nullable toolTitle;
		[NullAllowed, Export ("toolTitle")]
		string ToolTitle { get; }

		// @property (readonly, nonatomic, strong) NSNumber * _Nullable rootToolWorkflow;
		[NullAllowed, Export ("rootToolWorkflow", ArgumentSemantic.Strong)]
		NSNumber RootToolWorkflow { get; }

		// @property (readonly, copy, nonatomic) NSString * _Nullable message;
		[NullAllowed, Export ("message")]
		string Message { get; }
	}

	// @protocol CemRendererViewDelegate
    [BaseType(typeof(NSObject))]
	[Protocol, Model]
	interface CemRendererViewDelegate
	{
		// @required -(void)onResult:(CemRendererResultObjc * _Nonnull)result;
		[Abstract]
		[Export ("onResult:")]
		void OnResult (CemRendererResultObjc result);
	}

	// @interface CemRendererViewWrapper : NSObject
	[BaseType (typeof(NSObject))]
	[DisableDefaultCtor]
	interface CemRendererViewWrapper
	{
		// -(instancetype _Nonnull)initWithDelegate:(id<CemRendererViewDelegate> _Nullable)delegate __attribute__((objc_designated_initializer));
		[Export ("initWithDelegate:")]
		[DesignatedInitializer]
		NativeHandle Constructor ([NullAllowed] CemRendererViewDelegate @delegate);

		// -(UIViewController * _Nonnull)createFlutterViewControllerWithSessionToken:(NSString * _Nonnull)sessionToken baseUrl:(NSString * _Nonnull)baseUrl toolName:(NSString * _Nullable)toolName __attribute__((warn_unused_result("")));
		[Export ("createFlutterViewControllerWithSessionToken:baseUrl:toolName:")]
		UIViewController CreateFlutterViewControllerWithSessionToken (string sessionToken, string baseUrl, [NullAllowed] string toolName);

		// +(void)destroyView;
		[Static]
		[Export ("destroyView")]
		void DestroyView ();
	}
}
