# Prompt utility functions
# Provides reusable prompting functionality

# prompt_and_execute <prompt_message> <execute_function>
# prompt_message: the message to display in the prompt
# execute_function: name of a function to execute if user confirms
prompt_and_execute() {
    local prompt_message="$1"
    local execute_func="$2"
    
    read -p "$prompt_message [Y/n]: " choice
    choice=${choice,,}  # Convert to lowercase
    choice=${choice:-y}
    if [[ $choice =~ ^[Yy](es)?$ ]]; then
        "$execute_func"
    else
        print_status "$YELLOW" "Skipping."
    fi
}