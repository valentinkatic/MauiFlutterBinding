#!/bin/sh

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --no-flutter-build    Skip Flutter build step"
    echo "  --help                Show this help message"
}

# Function to handle errors
handle_error() {
    echo "Error: Script failed on line $1"
    exit 1
}

# Set up error trap
trap 'handle_error $LINENO' ERR

# Exit on any error
set -e

# Default value
SKIP_FLUTTER_BUILD=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --no-flutter-build) SKIP_FLUTTER_BUILD=true ;;
        --help) show_usage; exit 0 ;;
        *) echo "Unknown parameter: $1"; echo ""; show_usage; exit 1 ;;
    esac
    shift
done

if [ "$SKIP_FLUTTER_BUILD" = false ]; then
  echo "Running flutter app build"
  (cd flutter_app && ./build.sh)
fi

echo "Running Android.Native build"
(cd Android.Native && ./build.sh)

echo "Running iOS.Native build"
(cd iOS.Native && ./build.sh)

echo "Deleting all bin/ and obj/"
find . -type d \( -name bin -o -name obj \) -exec rm -rf {} +

echo "Restoring Binding solutions"
dotnet restore Android.Binding/Android.Binding.csproj
dotnet restore iOS.Binding/iOS.Binding.csproj

echo "Building Binding solutions"
dotnet build Android.Binding/Android.Binding.csproj
dotnet build iOS.Binding/iOS.Binding.csproj

echo "Restoring MauiDemoApp"
dotnet restore MauiDemoApp/MauiDemoApp.csproj

echo "Building MauiDemoApp"
dotnet build MauiDemoApp/MauiDemoApp.csproj