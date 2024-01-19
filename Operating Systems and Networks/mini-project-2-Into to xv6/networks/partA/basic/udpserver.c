#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>


int main(){
    int port = 5566;
    struct sockaddr_in server, client;
    // As with UDPClient, the server creates a UDP socket
    int server_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if(server_socket == -1){
        perror("Error in opening socket ");
        exit(EXIT_FAILURE);
    }
    printf("Socket opened\n");
    memset(&server, 0, sizeof(server));
    server.sin_family = AF_INET;
    server.sin_port = htons(port);
    server.sin_addr.s_addr = inet_addr("127.0.0.1");
    int opt = 1;
    if (setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) == -1) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }

    // bind to any incoming clients, associate the server port number with this socket:
    if(bind(server_socket, (struct sockaddr*)&server, sizeof(server)) == -1){
        perror("Binding error ");
        exit(EXIT_FAILURE);
    }

    printf("Bound the server to port:%d\n", port);
    char message_from_client[4096];
    memset(message_from_client, '\0', 4096);
    char* message_to_client = "Hi dear client. Welcome to UDP Server";
    int stlen = sizeof(client);

    // Receive data from client [Here we do not have listen and accept, which are used in TCP]
    if(recvfrom(server_socket, message_from_client, 4096, 0, (struct sockaddr*)&client, &stlen) == -1){
        perror("Error recceiving message from client ");
        exit(EXIT_FAILURE);
    }

    printf("Message received from client:\n\033[0;32m%s\033[0;37m\n", message_from_client);

    // Send a response to the client
    if(sendto(server_socket, message_to_client, 4096, 0, (struct sockaddr*)&client, sizeof(client)) == -1){
        perror("Error sending message to server");
        exit(EXIT_FAILURE);
    }

    if(close(server_socket) == -1){
        perror("Error in closing the server socket:");
        exit(EXIT_FAILURE);
    }
    printf("Closed socket\n");
}