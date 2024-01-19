#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>

int main(){
    // Creating a socket [an endpoint for communication]
    // AF_INET => domain selects IPv4 Internet protocols
    // SOCK_STREAM => It is a TCP Socket [socket is of the type that provides sequenced, reliable, two-way, connection-based byte streams.]
    // protocol = 0 => since only single protocol is used to support the socket
    int client_socket = socket(AF_INET, SOCK_STREAM, 0);

    // returns -1 on error
    if(client_socket == -1){
        perror("Client socket creation error: ");
        exit(EXIT_FAILURE);
    }
    printf("socket opened\n");
    // Server credentials
    struct sockaddr_in server;
    server.sin_family = AF_INET;
    // Server's port number
    server.sin_port = htons(7000);
    // Server's IP address
    server.sin_addr.s_addr = inet_addr("127.0.0.1");

    // Establish TCP connection between server and client, the three-way handshake is
    // performed and a TCP connection is established between the client and server.
    if(connect(client_socket, (struct sockaddr*)&server, sizeof(server)) == -1){
        perror("Error connecting client to the server: ");
        exit(EXIT_FAILURE);
    }
    printf("Connected to server\n");
    // Send data to the server
    // sends the sentence through the client’s socket and into the TCP connection.
    // the program does not explicitly create a packet and attach the destination address to the packet, as was
    // the case with UDP sockets. Instead the client program simply drops the bytes in the string sentence
    // into the TCP connection. The client then waits to receive bytes from the server.
    char message_to_server[4096];
    while(1){
        memset(message_to_server, '\0', 4096);
        scanf(" %s", message_to_server);
        // for simplicity, we are using 0 flag
        if(send(client_socket, message_to_server, strlen(message_to_server), 0) == -1){
            perror("Error sending message to the server: ");
            exit(EXIT_FAILURE);
        }
        printf("Message sent to server\n");
        // Recieve data from server
        char message_from_server[4096];
        memset(message_from_server, '\0', 4096);
        if(recv(client_socket, message_from_server, 4096, 0) == -1){
            perror("Error receiving data from the server: ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from server:\n\033[0;32m%s\033[0;37m\n", message_from_server);

        memset(message_to_server, '\0', 4096);
        scanf("%s", message_to_server);
        if(send(client_socket, message_to_server, strlen(message_to_server), 0) == -1){
            perror("Error sending message to the server: ");
            exit(EXIT_FAILURE);
        }
        printf("Message sent to server\n");
        memset(message_from_server, '\0', 4096);
        if(recv(client_socket, message_from_server, 4096, 0) == -1){
            perror("Error receiving data from the server: ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from server:\n\033[0;32m%s\033[0;37m\n", message_from_server);
        if(message_from_server[0] == 'E' || message_from_server[0] == 'C')
            break;
    }
    // Finally, close the socket
    // closes the TCP connection between the client and the
    // server. It causes TCP in the client to send a TCP message to TCP in the server
    if(close(client_socket) == -1){
        perror("Error closing the client socket: ");
        exit(EXIT_FAILURE);
    }
    printf("Closed socket\n");
    return 0;
}