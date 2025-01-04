!/bin/bash

# Read the first line of the HTTP request
read -r request_line
echo "Received request: $request_line" >> debug.log

# Extract the HTTP method and path
method=$(echo "$request_line" | awk '{print $1}')
path=$(echo "$request_line" | awk '{print $2}')

# Initialize variables
content_length=0

# Read headers until a blank line
while read -r line; do
    [[ "$line" == $'\r' ]] && break
    echo "Header: $line" >> debug.log

    # Extract Content-Length header
    if [[ "$line" =~ ^Content-Length:\ ([0-9]+) ]]; then
        content_length="${BASH_REMATCH[1]}"
    fi
done
# Handle GET request to serve the registration form
if [[ "$method" == "GET" && ( "$path" == "/" || "$path" == "/register" ) ]]; then
    echo "Serving registration form" >> debug.log

    # Registration form HTML
    body='<!DOCTYPE html>
<html>
<head>
    <title>Bus Ride Registration</title>
</head>
<body>
    <h1>Please, register for a Bus Ride</h1>
    <form method="POST" action="/register">
        <label for="name">Full Name:</label><br>
        <input type="text" name="name" required><br>
        <label for="seats">Number of Seats:</label><br>
        <input type="number" name="seats" min="1" required><br>
        <label for="email">Email:</label><br>
        <input type="email" name="email" required><br>
        <label for="route">Bus Route:</label><br>
        <input type="text" name="route" required><br><br>
        <input type="submit" value="Register">
    </form>
</body>
</html>'
content_length=$(echo -n "$body" | wc -c)
    # Send the HTTP response    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: $content_length\r\nConnection: keep-alive\r\>
# Handle POST request for form submission
elif [[ "$method" == "POST" && "$path" == "/register" ]]; then    echo "Processing form submission" >> debug.log
    # Read the POST data based on Content-Length
    if [[ "$content_length" -gt 0 ]]; then        read -n "$content_length" post_data
        echo "POST data: $post_data" >> debug.log    else
        echo "No POST data received" >> debug.log    fi
    # Extract form data
    name=$(echo "$post_data" | grep -oP "(?<=name=)[^&]*" | tr "+" " " | sed "s/%40/@/")    seats=$(echo "$post_data" | grep -oP "(?<=seats=)[^&]*")
    email=$(echo "$post_data" | grep -oP "(?<=email=)[^&]*" | sed "s/%40/@/")    route=$(echo "$post_data" | grep -oP "(?<=route=)[^&]*" | tr "+" " ")
    echo "Extracted Data: Name=$name, Seats=$seats, Email=$email, Route=$route" >> debug.log
    # Insert data into MariaDB    DB_NAME="bus_registration";
    DB_USER="vboxuser";    DB_PASS="VirtualBox_1511";
    mysql -u $DB_USER -p$DB_PASS $DB_NAME -e "    USE bus_registration;
    INSERT INTO registrations (name, seats, email, route)    VALUES ('$name', $seats, '$email', '$route');
    " >> debug.log 2>&1
    if [[ $? -eq 0 ]]; then        echo "Data successfully inserted into database" >> debug.log
    else        echo "Error inserting data into database" >> debug.log
    fi
    # Send a response back to the client
    body="<h1>Thank You</h1><p>Your registration has been received. Name: $name, Seats: $seats, Email: $email, Route: $>
    content_length=$(echo -n "$body" | wc -c)

    echo "Sending response with length $content_length" >> debug.log
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: $content_length\r\nConnection: close\r\n\r\n>

    # Explicitly close the connection
    echo "Connection closed after response" >> debug.log
fi