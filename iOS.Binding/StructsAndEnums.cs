using ObjCRuntime;

namespace iOS.Binding
{
	[Native]
	public enum ResultTypeObjc : long
	{
		Ok = 0,
		Cancelled = 1,
		GeneralError = 2,
		NetworkError = 3,
		ServiceError = 4,
		SessionEnded = 5
	}
}
