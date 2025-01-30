namespace MauiDemoApp;

using iOS.Binding;

public partial class FlutterPage : ContentPage
{
    public string SessionToken { get; }
    public string BaseUrl { get; }
    public string ToolName { get; }
    private readonly Action<CemRendererResultObjc> _onResult;

    public FlutterPage(string sessionToken, string baseUrl, string toolName, Action<CemRendererResultObjc> onResult)
    {
        SessionToken = sessionToken;
        BaseUrl = baseUrl;
        ToolName = toolName;
        _onResult = onResult;
    }

    public void HandleResult(CemRendererResultObjc result)
    {
        _onResult?.Invoke(result);
    }
}