#!/bin/sh

# Default configuration
DEBUG=false
PROJECT_PATH="."
IGNORE_PATTERNS_FILE="ignore_patterns.conf"
OUTPUT_FILE="artifact_$(date +%Y%m%d_%H%M%S).md"

# Function to print debug messages
debug_log() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] $1"
    fi
}

# Function to print usage information
print_usage() {
    echo "Usage: $0 [OPTIONS] [PATH]"
    echo "Options:"
    echo "  -d, --debug          Enable debug mode"
    echo "  -o, --output FILE    Specify output file (default: artifact_YYYYMMDD_HHMMSS.md)"
    echo "  -h, --help           Show this help message"
}

# Parse command line arguments
while [ $# -gt 0 ]; do
    case $1 in
        -d|--debug)
            DEBUG=true
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            PROJECT_PATH="$1"
            shift
            ;;
    esac
done

# Function to get ignore patterns for a specific section
get_section_patterns() {
    section="$1"
    awk -v section="[$section]" '
        $0 == section {p=1; next}
        /^\[.*\]/ {p=0}
        p && !/^#/ && NF {print}
    ' "$IGNORE_PATTERNS_FILE"
}

# Function to detect project type
detect_project_type() {
    path="$1"
    project_types=""
    
    # Android Native
    if [ -f "$path/app/build.gradle" ] || [ -f "$path/app/src/main/AndroidManifest.xml" ]; then
        project_types="$project_types Android"
    fi
    
    # Flutter
    if [ -f "$path/pubspec.yaml" ]; then
        project_types="$project_types Flutter"
    fi
    
    # MAUI
    if find "$path" -name "*.csproj" -type f | grep -q .; then
        project_types="$project_types MAUI"
    fi
    
    # iOS
    if [ -f "$path/*.xcodeproj/project.pbxproj" ]; then
        project_types="$project_types iOS"
    fi
    
    # Java
    if [ -f "$path/pom.xml" ] || [ -f "$path/build.gradle" ]; then
        project_types="$project_types Java"
    fi
    
    # Web
    if [ -f "$path/package.json" ] || [ -f "$path/angular.json" ]; then
        project_types="$project_types Web"
    fi
    
    echo "$project_types"
}

# Function to generate artifact content
generate_artifact_content() {
    path="$1"
    detected_types=$(detect_project_type "$path")
    
    # Create temporary ignore patterns file
    tmp_ignore_file=$(mktemp)
    
    # Add common patterns
    get_section_patterns "Common" > "$tmp_ignore_file"
    
    # Add patterns for each detected project type
    for type in $detected_types; do
        get_section_patterns "$type" >> "$tmp_ignore_file"
    done
    
    # Process patterns to make them more grep-friendly
    sed -i.bak -e '/^$/d' \
        -e 's|^/|*/|' \
        -e 's|/$|/*|' \
        -e 's|^\.|\.\.|' \
        -e 's|[.[\^$*]|\\&|g' "$tmp_ignore_file"
    
    # Remove duplicates
    sort -u "$tmp_ignore_file" > "${tmp_ignore_file}.sorted"
    mv "${tmp_ignore_file}.sorted" "$tmp_ignore_file"
    
    {
        echo "# Project Artifact"
        echo "Generated on: $(date)"
        echo
        echo "## Project Overview"
        echo "Path: $path"
        if [ -n "$detected_types" ]; then
            echo "Detected project types: $detected_types"
        else
            echo "No specific project type detected"
        fi
        echo
        
        echo "## Directory Structure"
        echo '```'
        if command -v tree >/dev/null 2>&1; then
            (cd "$path" && tree -a --gitignore -I "$(tr '\n' '|' < "$tmp_ignore_file")")
        else
            (cd "$path" && find . -type f -o -type d | \
            while read -r file; do
                if ! grep -q -f "$tmp_ignore_file" <<< "$file"; then
                    echo "$file" | sed -e 's|[^/]*/|  |g' -e 's|^./||'
                fi
            done | sort)
        fi
        echo '```'
        echo
        
        echo "## File Statistics"
        echo "### File Types Distribution"
        echo '```'
        (cd "$path" && find . -type f | grep -v -f "$tmp_ignore_file" | sed -e 's|^\./||' -e 's|.*\.||' | sort | uniq -c | sort -rn)
        echo '```'
        echo
        
        # Project-specific information
        for type in $detected_types; do
            echo "## $type Project Details"
            case $type in
                "Android")
                    if [ -f "$path/app/build.gradle" ]; then
                        echo "### Build Configuration (build.gradle)"
                        echo '```gradle'
                        cat "$path/app/build.gradle"
                        echo '```'
                        echo
                    fi
                    if [ -f "$path/app/src/main/AndroidManifest.xml" ]; then
                        echo "### Android Manifest"
                        echo '```xml'
                        cat "$path/app/src/main/AndroidManifest.xml"
                        echo '```'
                        echo
                    fi
                    echo "### Source Files"
                    find "$path" \( -name "*.java" -o -name "*.kt" \) -type f | while read -r file; do
                        echo "#### $(basename "$file")"
                        echo '```'
                        [ "${file##*.}" = "java" ] && echo "java" || echo "kotlin"
                        cat "$file"
                        echo '```'
                        echo
                    done
                    ;;
                "Flutter")
                    if [ -f "$path/pubspec.yaml" ]; then
                        echo "### Project Configuration (pubspec.yaml)"
                        echo '```yaml'
                        cat "$path/pubspec.yaml"
                        echo '```'
                        echo
                    fi
                    echo "### Source Files"
                    find "$path/lib" -name "*.dart" -type f | while read -r file; do
                        echo "#### $(basename "$file")"
                        echo '```dart'
                        cat "$file"
                        echo '```'
                        echo
                    done
                    ;;
                "MAUI")
                    csproj_file=$(find "$path" -name "*.csproj" -type f | head -n 1)
                    if [ -n "$csproj_file" ]; then
                        echo "### Project Configuration ($(basename "$csproj_file"))"
                        echo '```xml'
                        cat "$csproj_file"
                        echo '```'
                        echo
                        echo "### Source Files"
                        find "$path" -name "*.cs" -type f | while read -r file; do
                            echo "#### $(basename "$file")"
                            echo '```csharp'
                            cat "$file"
                            echo '```'
                            echo
                        done
                        echo "### XAML Files"
                        find "$path" -name "*.xaml" -type f | while read -r file; do
                            echo "#### $(basename "$file")"
                            echo '```xml'
                            cat "$file"
                            echo '```'
                            echo
                        done
                    fi
                    ;;
            esac
            echo
        done
        
        echo "## Additional Notes"
        echo "- Generated using generate_artifacts.sh"
        echo "- Debug mode: $DEBUG"
        if [ -f "$IGNORE_PATTERNS_FILE" ]; then
            echo "- Using ignore patterns from: $IGNORE_PATTERNS_FILE"
        fi
        
    } > "$OUTPUT_FILE"
    
    # Cleanup
    rm -f "$tmp_ignore_file" "$tmp_ignore_file.bak"
}

# Main execution
debug_log "Starting artifact generation for path: $PROJECT_PATH"
debug_log "Output file: $OUTPUT_FILE"

if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Directory '$PROJECT_PATH' does not exist"
    exit 1
fi

if [ ! -f "$IGNORE_PATTERNS_FILE" ]; then
    echo "Warning: Ignore patterns file '$IGNORE_PATTERNS_FILE' not found"
fi

generate_artifact_content "$PROJECT_PATH"
debug_log "Artifact generation complete"

echo "Artifact generated successfully: $OUTPUT_FILE"