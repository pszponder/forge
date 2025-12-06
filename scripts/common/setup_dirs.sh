#!/usr/bin/env bash

setup_dirs() {
    # Base directory (defaults to $HOME/Development unless you pass a custom path)
    local BASE_DIR="${1:-$HOME/Development}"

    echo "Creating developer directory structure in: $BASE_DIR"
    if [[ ! -d "$BASE_DIR" ]]; then
        mkdir -p "$BASE_DIR"
        echo "Created: $BASE_DIR"
    else
        echo "Base directory already exists: $BASE_DIR"
    fi

    # Repository directories
    local REPOS=(
        "repos/github/pszponder"
        # "repos/gitlab/pszponder"
    )

    # Other top-level directories
    local OTHER_DIRS=(
        "sandbox"
        "courses"
        "resources"
    )

    # Create repos + providers
    for dir in "${REPOS[@]}"; do
        if [[ ! -d "$BASE_DIR/$dir" ]]; then
            mkdir -p "$BASE_DIR/$dir"
            echo "Created: $BASE_DIR/$dir"
        else
            echo "Already exists: $BASE_DIR/$dir"
        fi
    done

    # Create other directories
    for dir in "${OTHER_DIRS[@]}"; do
        if [[ ! -d "$BASE_DIR/$dir" ]]; then
            mkdir -p "$BASE_DIR/$dir"
            echo "Created: $BASE_DIR/$dir"
        else
            echo "Already exists: $BASE_DIR/$dir"
        fi
    done

    echo "All developer directories have been created successfully!"
}

# If this script is run directly, call the function
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    setup_dirs "$@"
fi
