#!/bin/sh

# Function to check if file should be ignored
should_ignore() {
    local file="$1"
    local fullpath="$INPUT_DIR/$file"
    # First check standard ignore patterns
    if echo "$file" | grep -E "($ignore_pattern)" >/dev/null 2>&1; then
        return 0
    fi
    
    # Skip if file doesn't exist
    if [ ! -f "$fullpath" ]; then
        return 0
    fi
    
    # Get file size in bytes (macOS compatible)
    local size
    size=$(stat -f %z "$fullpath")
    if [ -z "$size" ]; then
        return 0
    fi
    
    # Skip large binary files but record their existence
    case "$file" in
        *.aar|*.jar|*.so)
            echo "## Binary Asset - $file" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "### Metadata" >> "$OUTPUT_FILE"
            echo "\`\`\`" >> "$OUTPUT_FILE"
            echo "File: $file" >> "$OUTPUT_FILE"
            echo "Size: $size bytes" >> "$OUTPUT_FILE"
            echo "Type: Binary file (content excluded)" >> "$OUTPUT_FILE"
            echo "\`\`\`" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            return 0
            ;;
    esac
    
    # If file is larger than 1MB, treat it as binary and skip content
    if [ "$size" -gt 1048576 ]; then
        echo "## Large File - $file" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "### Metadata" >> "$OUTPUT_FILE"
        echo "\`\`\`" >> "$OUTPUT_FILE"
        echo "File: $file" >> "$OUTPUT_FILE"
        echo "Size: $size bytes" >> "$OUTPUT_FILE"
        echo "Type: Large file (content excluded)" >> "$OUTPUT_FILE"
        echo "\`\`\`" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        return 0
    fi
    
    return 1
}

# Function to categorize file by platform
get_platform_category() {
    local file="$1"
    if echo "$file" | grep -q "\.dart$\|/flutter/\|pubspec\.yaml$"; then
        echo "Flutter"
    elif echo "$file" | grep -q "\.cs$\|\.xaml$\|\.csproj$\|/maui/"; then
        echo "MAUI"
    elif echo "$file" | grep -q "/android/\|\.gradle$\|\.\(java\|kt\|xml\)$"; then
        echo "Android"
    elif echo "$file" | grep -q "/ios/\|\.\(swift\|h\|m\|mm\)$\|\.xcodeproj/"; then
        echo "iOS"
    else
        echo "Common"
    fi
}

# Function to get file metadata
get_file_metadata() {
    local file="$1"
    echo "File: $file"
    echo "Size: $(stat -f %z "$file" 2>/dev/null || stat -c %s "$file") bytes"
    echo "Last Modified: $(stat -f %Sm "$file" 2>/dev/null || stat -c %y "$file")"
    echo "File Type: $(file -b "$file")"
    
    # Add extra metadata for specific file types
    case "$file" in
        *.csproj)
            if grep -q "TargetFramework" "$file"; then
                echo -e "\nTarget Framework(s):"
                grep -o "<TargetFramework[^>]*>[^<]*" "$file" | sed 's/<TargetFramework[^>]*>//'
            fi
            ;;
        pubspec.yaml)
            if grep -q "^sdk:" "$file"; then
                echo -e "\nFlutter SDK Version:"
                grep "^sdk:" "$file" | sed 's/sdk://'
            fi
            ;;
        *.gradle)
            if grep -q "com.android.tools.build:gradle" "$file"; then
                echo -e "\nAndroid Plugin Version:"
                grep "com.android.tools.build:gradle" "$file" | grep -o "[0-9][0-9.]*" | head -1
            fi
            ;;
        *.pbxproj)
            if grep -q "IPHONEOS_DEPLOYMENT_TARGET" "$file"; then
                echo -e "\niOS Development Target:"
                grep "IPHONEOS_DEPLOYMENT_TARGET" "$file" | head -1 | grep -o "[0-9][0-9.]*"
            fi
            ;;
    esac
}

# Function to determine the language from file extension
get_language() {
    case "$1" in
        # Flutter/Dart
        *.dart) echo "dart" ;;
        *.yaml|*.yml) echo "yaml" ;;
        *.arb) echo "json" ;;
        
        # MAUI/.NET
        *.cs) echo "csharp" ;;
        *.xaml) echo "xml" ;;
        *.csproj|*.props|*.targets) echo "xml" ;;
        *.sln) echo "text" ;;
        
        # Android
        *.java) echo "java" ;;
        *.kt|*.kts) echo "kotlin" ;;
        *.gradle) echo "groovy" ;;
        *.xml) echo "xml" ;;
        *.aidl) echo "java" ;;
        
        # iOS
        *.swift) echo "swift" ;;
        *.h) echo "objectivec" ;;
        *.m|*.mm) echo "objectivec" ;;
        *.plist) echo "xml" ;;
        *.storyboard|*.xib) echo "xml" ;;
        *.pbxproj) echo "text" ;;
        *.xcconfig) echo "text" ;;
        *.podspec|*.rb) echo "ruby" ;;
        
        # Common
        *.json) echo "json" ;;
        *.md|*.markdown) echo "markdown" ;;
        *.txt) echo "text" ;;
        *.sh) echo "bash" ;;
        *.bat) echo "batch" ;;
        *.ps1) echo "powershell" ;;
        *) echo "text" ;;
    esac
}

# Function to detect project types in the directory
detect_project_types() {
    local dir="$1"
    local project_types=""
    
    # Flutter detection
    if [ -f "$dir/pubspec.yaml" ] || find "$dir" -maxdepth 3 -name "pubspec.yaml" -quit; then
        project_types="$project_types Flutter"
    fi
    
    # MAUI detection
    if find "$dir" -maxdepth 3 -name "*.csproj" -exec grep -l "Microsoft.NET.Sdk.Maui" {} \; -quit; then
        project_types="$project_types MAUI"
    fi
    
    # Android detection (Native)
    if [ -f "$dir/gradlew" ] || [ -d "$dir/app/src/main/java" ] || [ -d "$dir/app/src/main/kotlin" ]; then
        project_types="$project_types Android"
    fi
    
    # iOS detection (Native)
    if [ -d "$dir/Pods" ] || find "$dir" -maxdepth 3 -name "*.xcodeproj" -quit || find "$dir" -maxdepth 3 -name "*.xcworkspace" -quit; then
        project_types="$project_types iOS"
    fi
    
    echo "$project_types"
}

# Generate ignore patterns based on project types
generate_ignore_patterns() {
    local project_types="$1"
    local patterns="node_modules|.git|.svn|.hg|.DS_Store|Thumbs.db|.vs|.idea|artifact_.*\.md|generate_artifacts.sh"
    
    # Flutter specific
    if echo "$project_types" | grep -q "Flutter"; then
        patterns="$patterns|build/|.dart_tool/|.flutter-plugins|.pub-cache|.pub/|.packages"
    fi
    
    # MAUI specific
    if echo "$project_types" | grep -q "MAUI"; then
        patterns="$patterns|bin/|obj/|.vs/|packages/|TestResults/"
    fi
    
    # Android specific
    if echo "$project_types" | grep -q "Android"; then
        patterns="$patterns|build/|.gradle/|.idea/|captures/|.externalNativeBuild/|.cxx/|local.properties"
    fi
    
    # iOS specific
    if echo "$project_types" | grep -q "iOS"; then
        patterns="$patterns|Pods/|.symlinks/|DerivedData/|.build/|xcuserdata/|.xcuserstate|.xcassets/"
    fi
    
    echo "$patterns"
}

# Check if input directory is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <directory_path>"
    exit 1
fi

# Input directory path
INPUT_DIR="$1"
# Output file name - using current timestamp to make it unique
OUTPUT_FILE="artifact_$(date +%Y%m%d_%H%M%S).md"

# Check if directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Directory '$INPUT_DIR' does not exist."
    exit 1
fi

# Initialize the markdown file with a header
detected_projects=$(detect_project_types "$INPUT_DIR")
echo "Detected project types: $detected_projects"
ignore_pattern=$(generate_ignore_patterns "$detected_projects")
echo "Using ignore pattern: $ignore_pattern"

# Create initial markdown file
cat > "$OUTPUT_FILE" << EOL
# Cross-Platform Project Documentation
Generated on: $(date)
Source Directory: $INPUT_DIR

## Detected Project Types
$(echo "$detected_projects" | tr ' ' '\n' | sed 's/^/- /')

## Project Structure Overview
This documentation covers a cross-platform project including detected frameworks and technologies.

## Table of Contents
EOL

# Process and write files to documentation
echo "# Source Files" >> "$OUTPUT_FILE"

# Use find with a temp file to handle null-separated filenames
find "$INPUT_DIR" -type f -not -path "*.xcframework/*" -not -path "*.framework/*" -print0 > /tmp/files.txt

# Read the temp file
while IFS= read -r -d '' file; do
    relative_path="${file#$INPUT_DIR/}"
    
    if ! should_ignore "$relative_path"; then
        platform=$(get_platform_category "$relative_path")
        echo "## $platform - $relative_path" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "### Metadata" >> "$OUTPUT_FILE"
        echo "\`\`\`" >> "$OUTPUT_FILE"
        get_file_metadata "$file" >> "$OUTPUT_FILE"
        echo "\`\`\`" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        echo "### Content" >> "$OUTPUT_FILE"
        language=$(get_language "$file")
        echo "\`\`\`$language" >> "$OUTPUT_FILE"
        cat "$file" >> "$OUTPUT_FILE"
        echo "\`\`\`" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        echo "Processed: $relative_path"
    fi
done < /tmp/files.txt

# Clean up temp file
rm /tmp/files.txt

# Add summary section
echo "" >> "$OUTPUT_FILE"
echo "# Project Summary" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "## Project Types" >> "$OUTPUT_FILE"
echo "This project contains the following detected frameworks/technologies:" >> "$OUTPUT_FILE"
echo "$detected_projects" | tr ' ' '\n' | sed 's/^/- /' >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "## File Statistics" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "File counts by category:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Count files by category
for platform in Flutter MAUI Android iOS Common; do
    count=$(grep -c "^## $platform -" "$OUTPUT_FILE")
    if [ "$count" -gt 0 ]; then
        echo "- $platform: $count files ($(date))" >> "$OUTPUT_FILE"
    fi
done

echo "Documentation generated: $OUTPUT_FILE"