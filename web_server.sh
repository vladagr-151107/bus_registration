#!/bin/bash
PORT=8080
echo "Starting web server on http://localhost:$PORT"

while true; do
    socat TCP-LISTEN:$PORT,reuseaddr,fork EXEC:./handle_request.sh
done