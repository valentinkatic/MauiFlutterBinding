using UIKit;
using iOS.Binding;
using Microsoft.Maui.Controls.Compatibility.Platform.iOS;

namespace MauiDemoApp
{
    [Obsolete]
    public class FlutterPageRenderer : PageRenderer
    {
        private UIViewController? _controller;
        private CemRendererViewWrapper _wrapper;

        public FlutterPageRenderer()
        {
            // Initialize wrapper with this as delegate for OnResult callback
            _wrapper = new CemRendererViewWrapper(new FlutterPageRendererDelegate(OnResult));
        }

        public override void ViewDidLoad()
        {
            base.ViewDidLoad();

            // Get the actual values from the bound FlutterPage
            var flutterPage = Element as FlutterPage;
            if (flutterPage != null)
            {
                _controller = _wrapper.CreateFlutterViewControllerWithSessionToken(
                    flutterPage.SessionToken,
                    flutterPage.BaseUrl,
                    flutterPage.ToolName
                );

                if (_controller != null)
                {
                    // Add Flutter view controller as child
                    AddChildViewController(_controller);
                    View.AddSubview(_controller.View);
                    _controller.DidMoveToParentViewController(this);

                    // Set Flutter view constraints to fill parent
                    _controller.View.TranslatesAutoresizingMaskIntoConstraints = false;
                    NSLayoutConstraint.ActivateConstraints(
                    [
                        _controller.View.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor),
                        _controller.View.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor),
                        _controller.View.TopAnchor.ConstraintEqualTo(View.TopAnchor),
                        _controller.View.BottomAnchor.ConstraintEqualTo(View.BottomAnchor)
                    ]);
                }
            }
        }

        public void OnResult(CemRendererResultObjc result)
        {
            var flutterPage = Element as FlutterPage;
            flutterPage?.HandleResult(result);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                CemRendererViewWrapper.DestroyView();
                _controller?.Dispose();
                _controller = null;
            }
            base.Dispose(disposing);
        }
    }
}

public class FlutterPageRendererDelegate : CemRendererViewDelegate
{
    private Action<CemRendererResultObjc> _resultHandler;

    public FlutterPageRendererDelegate(Action<CemRendererResultObjc> resultHandler)
    {
        _resultHandler = resultHandler;
    }

    public override void OnResult(CemRendererResultObjc result)
    {
        _resultHandler?.Invoke(result);
    }
}