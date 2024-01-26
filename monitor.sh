#!/bin/bash
# For this to work you will need to add --metrics-endpoints IP_TO_YOUR_FARMER:8080 to your farmer commands. Should be your farmers IP.
# For it to work on a node, you will need to add --prometheus-port 9615 --prometheus-external to the node commands.


# Farmers and nodes:
declare -A urls
urls["http://IP_TO_FARMER:8080/metrics"]="MyFarmer"
urls["http://IP_TO_NODE:9615/metrics"]="MyNode"

# Discord Webhook URL
discord_webhook_url=""

# Associative array to track the state of each URL
declare -A url_states

# Sleep duration in seconds (adjust as needed)
sleep_duration=10

while true; do
    for url in "${!urls[@]}"; do
        name="${urls[$url]}"
        # Use curl to ping the URL and check for a response
        response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")

        current_state="$url-$response_code"
        previous_state="${url_states[$url]}"

        if [ "$response_code" -ne 200 ]; then
            # URL is not responding
            if [ "$current_state" != "$previous_state" ]; then
                # State has changed, send alert to Discord
                echo "❗ $name ($url) is not responding (HTTP Code: $response_code)"
                message="❗ Alert: $name ($url) is not responding (HTTP Code: $response_code)"
                curl -H "Content-Type: application/json" -X POST -d '{"content":"'"$message"'"}' "$discord_webhook_url"
            fi
        else
            # URL is responding
            if [ "$current_state" != "$previous_state" ]; then
                # State has changed, print success message
                echo "✅ $name ($url) is responding (HTTP Code: $response_code)"
                message=" ✅ $name ($url) is responding (HTTP Code: $response_code)"
                curl -H "Content-Type: application/json" -X POST -d '{"content":"'"$message"'"}' "$discord_webhook_url"
            fi
        fi

        # Update the state for the current URL
        url_states["$url"]=$current_state
    done

    # Sleep for the specified duration before the next iteration
    sleep "$sleep_duration"
done