#!/bin/sh

read_ignore_patterns() {
    config_file="$1"
    project_types="$2"
    common_patterns=""
    project_patterns=""

    debug_log "Loading configuration file: $config_file"

    current_section=""
    # Read the configuration file line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [ -z "$line" ] || [ "${line#\#}" != "$line" ] && continue

        # Check if the line is a section header
        if echo "$line" | grep -q '^\[.*\]$'; then
            current_section=$(echo "$line" | sed 's/^\[\(.*\)\]$/\1/')
            debug_log "Switched to section: $current_section"
            continue
        fi

        # Add patterns to the appropriate section
        case $current_section in
            Common)
                common_patterns="${common_patterns:+$common_patterns,}$line"
                ;;
            *)
                if echo "$project_types" | tr ',' '\n' | grep -qx "$current_section"; then
                    project_patterns="${project_patterns:+$project_patterns,}$line"
                fi
                ;;
        esac
    done < "$config_file"

    debug_log "Common patterns: $common_patterns"
    debug_log "Project-specific patterns: $project_patterns"

    # Combine common and project-specific patterns
    combined_patterns="${common_patterns:+$common_patterns,}${project_patterns}"
    debug_log "Final ignore patterns: $combined_patterns"

    # Format patterns with newlines and remove trailing comma
    echo "$combined_patterns" | tr ',' '\n' | sed '/^$/d'
}

DEBUG_LOG_FILE="read_patterns.log"

debug_log() {
    echo "$1" >> "${DEBUG_LOG_FILE}"
}

# Clear the debug log file if it exists
> "$DEBUG_LOG_FILE"

# Test the script
IGNORE_PATTERNS=$(read_ignore_patterns "ignore_patterns.conf" "MAUI,Flutter")
debug_log "Generated Ignore Patterns:"
debug_log "$IGNORE_PATTERNS"

# Output the results
echo "$IGNORE_PATTERNS"
