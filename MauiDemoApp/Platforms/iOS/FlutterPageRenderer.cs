using Microsoft.Maui.Controls.Compatibility.Platform.iOS;
using Microsoft.Maui.Controls.Platform;
using Microsoft.Maui.Controls.PlatformConfiguration;
using UIKit;

namespace MauiDemoApp
{
    public class FlutterPageRenderer : UIViewController, IVisualElementRenderer
    {
        public FlutterPageRenderer()
        {
            ViewController = (new iOS.Binding.Binding()).FlutterViewController;
        }

        public VisualElement? Element { get; private set; }

        public event EventHandler<VisualElementChangedEventArgs> ElementChanged;

        public UIView? NativeView => ViewController.View;

        public SizeRequest GetDesiredSize(double widthConstraint, double heightConstraint)
        {
            return NativeView.GetSizeRequest(widthConstraint, heightConstraint);
        }

        public void SetElement(VisualElement element)
        {
            Element = element;
        }

        public void SetElementSize(Size size)
        {
            Element?.Layout(new Rect(Element.X, Element.Y, size.Width, size.Height));
        }

        public UIViewController ViewController { get; }
    }
}