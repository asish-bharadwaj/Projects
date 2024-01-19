#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>

int main(){
    int server_port = 7000;
    // As with TCPClient, the server creates a TCP socket
    int server_socket = socket(AF_INET, SOCK_STREAM, 0), client_socket;
    struct sockaddr_in server, client;
    if(server_socket == -1){
        perror("Server socket creation error: ");
        exit(EXIT_FAILURE);
    }
    printf("Socket opened\n");
    memset(&server, 0, sizeof(server));
    server.sin_family = AF_INET;
    server.sin_port = htons(server_port);
    // bind to any incoming clients
    server.sin_addr.s_addr = inet_addr("127.0.0.1");
    int opt = 1;
	if (setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) == -1) {
	    perror("setsockopt");
	    exit(EXIT_FAILURE);
	}

    // Similar to UDPServer, we associate the server port number with this socket:
    if(bind(server_socket, (struct sockaddr*)&server, sizeof(server)) == -1){
        perror("Binding error: ");
        exit(EXIT_FAILURE);
    }
    printf("Bound the server to port:%d\n", server_port);
    // Listen for incoming communications
    // server_socket will be our welcoming socket. After establishing this welcoming door, we will wait and listen for some client to knock on the door:
    // here, we are taking backlog [maximum length to which the queue of pending connections for server_socket may grow.] to be 3
    // If a connection request arrives when the queue is full, the client may
    // receive an error with an indication of ECONNREFUSED or, if the
    // underlying protocol supports retransmission, the request may be ignored so that a later reattempt at connection succeeds.
    if (listen(server_socket, 3) == -1) {
        perror("Listening error");
        exit(EXIT_FAILURE);
    }

    // Accept incoming connections
    // When a client knocks on this door, the program invokes the accept() method for server_socket, which
    // creates a new socket in the server, called ­
    // client_socket , dedicated to this particular client.
    // The client and server then complete the handshaking, creating a TCP connection between the client’s
    // client_socket and the server’s connectionSocket . With the TCP connection established, the
    // client and server can now send bytes to each other over the connection. With TCP, all bytes sent from
    // one side not are not only guaranteed to arrive at the other side but also guaranteed arrive in order.
    int stlen = sizeof(client);
    client_socket = accept(server_socket, (struct sockaddr *)&client, &stlen);
    if (client_socket == -1) {
        perror("Accepting error");
        exit(EXIT_FAILURE);
    }
    printf("Server connected to client with socket: %d\n", client_socket);
    
    // Receive data from the client
    char message_from_client[4096];
    if(recv(client_socket, message_from_client, 4096, 0) == -1){
        perror("Error in receiving messages from client: ");
        exit(EXIT_FAILURE);
    }
    printf("Message received from client:\n\033[0;32m%s\033[0;37m\n", message_from_client);

    // Send a response to the client
    char *response = "Hello dear client. Nice to meet you\n";
    if(send(client_socket, response, strlen(response), 0) == -1){
        perror("Error in sending message to client: ");
        exit(EXIT_FAILURE);
    }

    // Close sockets
    if(close(client_socket) == -1){
        perror("Error in closing the client socket:");
        exit(EXIT_FAILURE);
    }
    if(close(server_socket) == -1){
        perror("Error in closing the server socket:");
        exit(EXIT_FAILURE);
    }
    printf("Closed sockets\n");
    return 0;

}
