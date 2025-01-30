using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows.Input;
using iOS.Binding;
using System.Text.Json;

namespace MauiDemoApp
{
    public class MainViewModel : INotifyPropertyChanged
    {
        private bool _isLoading;
        private string? _errorMessage;
        private string? _token;
        private readonly IDispatcher _dispatcher;  // Add this for UI thread handling

        // public string BaseUrl { get; } = "https://demo.cempresso.com";
        public string BaseUrl { get; } = "http://selfcare-development-service-i-cempresso.k8s.lab.bulb.hr:31711";

        public bool IsLoading
        {
            get => _isLoading;
            set
            {
                if (_isLoading != value)
                {
                    _isLoading = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(IsNotLoading));
                }
            }
        }

        public bool IsNotLoading => !IsLoading;

        public string? ErrorMessage
        {
            get => _errorMessage;
            set
            {
                if (_errorMessage != value)
                {
                    _errorMessage = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(HasError));
                }
            }
        }

        public bool HasError => !string.IsNullOrEmpty(ErrorMessage);

        public ICommand LoginCommand { get; }

        public MainViewModel(IDispatcher dispatcher)
        {
            _dispatcher = dispatcher;
            LoginCommand = new Command(async () => await Login(), () => !IsLoading);
        }

        private async Task Login()
        {
            if (IsLoading) return;

            try
            {
                IsLoading = true;
                ErrorMessage = null;

                // string username = "mobileappwifi";
                // string password = "changeme123";
                // string oib = "7777777777";
                // string loginIdentifier = "customer.oib";
                // string domain = "Landline.services";
                // string principal = "Selfcare user";

                string username = "test";
                string password = "test123";
                string oib = "2";
                string loginIdentifier = "campaignId";
                string domain = "telesales";
                string principal = "Selfcare user";

                using var client = new HttpClient();
                var url = $"{BaseUrl}/servicei-core/api/selfcare";

                var payload = new Dictionary<string, object>
                {
                    ["domain"] = domain,
                    ["principal"] = principal,
                    ["params"] = new Dictionary<string, string>
                    {
                        [loginIdentifier] = oib,
                        ["platform"] = DeviceInfo.Platform == DevicePlatform.iOS ? "ios" : "android"
                    }
                };

                var jsonBody = JsonSerializer.Serialize(payload);

                var authHeader = Convert.ToBase64String(
                    System.Text.Encoding.UTF8.GetBytes($"{username}:{password}")
                );

                using var request = new HttpRequestMessage(HttpMethod.Post, url);
                request.Content = new StringContent(jsonBody, System.Text.Encoding.UTF8, "application/json");
                request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", authHeader);
                request.Headers.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));

                var response = await client.SendAsync(request);
                response.EnsureSuccessStatusCode();

                var responseJson = await response.Content.ReadAsStringAsync();
                var loginResponse = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(responseJson)
                    ?? throw new Exception("Invalid login response");

                if (!loginResponse.ContainsKey("status") ||
                    loginResponse["status"].ValueKind != JsonValueKind.Object)
                {
                    throw new Exception($"Invalid status code: {loginResponse.GetValueOrDefault("status")}");
                }

                if (!loginResponse.ContainsKey("token"))
                {
                    throw new Exception("Invalid token: " + responseJson);
                }

                _token = loginResponse["token"].GetString();

                if (_token != null)
                {
                    await _dispatcher.DispatchAsync(async () =>
                    {
                        await Application.Current!.MainPage!.Navigation.PushAsync(
                            new FlutterPage(
                                sessionToken: _token,
                                baseUrl: BaseUrl,
                                toolName: null,
                                onResult: HandleCemRendererResult
                            )
                        );
                    });
                }
            }
            catch (Exception ex)
            {
                await _dispatcher.DispatchAsync(() =>
                {
                    ErrorMessage = ex.Message;
                });
            }
            finally
            {
                IsLoading = false;
            }
        }

        private void HandleCemRendererResult(CemRendererResultObjc result)
        {
            _dispatcher.Dispatch(() =>
            {
                string message = result.Type switch
                {
                    ResultTypeObjc.Ok => result.ToolName != null
                        ? $"Tool \"{result.ToolName}\" Completed Successfully"
                        : "Tool Completed Successfully",

                    ResultTypeObjc.Cancelled => result.ToolName != null
                        ? $"Workflow for \"{result.ToolName}\" Cancelled"
                        : "Workflow Cancelled",

                    ResultTypeObjc.SessionEnded => "Session Ended",

                    _ => result.ToolName != null
                        ? $"Workflow for \"{result.ToolName}\" failed to Execute: {result.Message}"
                        : $"Workflow failed to Execute: {result.Message}"
                };

                ErrorMessage = message;
            });
        }

        public event PropertyChangedEventHandler? PropertyChanged;
        protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}