#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>

int main(){
    int port = 7000;
    struct sockaddr_in client;

    // Creating a socket [an endpoint for communication]
    // AF_INET => domain selects IPv4 Internet protocols
    // SOCK_DGRAM => It is a UDP Socket 
    // protocol = 0 => since only single protocol is used to support the socket
    int client_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if(client_socket == -1){
        perror("Error in opening socket ");
        exit(EXIT_FAILURE);
    }
    printf("Socket opened\n");
    memset(&client, 0, sizeof(client));
    client.sin_family = AF_INET;
    client.sin_port = htons(port);
    client.sin_addr.s_addr = inet_addr("127.0.0.1");


    // Send data to the server
    // the program explicitly createS a packet and attachES the destination address to the packet
    char message_to_server[4096];
    while(1){
        memset(message_to_server, '\0', 4096);
        scanf(" %s", message_to_server);
        // for simplicity, we are using 0 flag
        if(sendto(client_socket, message_to_server, 1024, 0, (struct sockaddr*)&client, sizeof(client)) == -1){
            perror("Error sending message to server ");
            exit(EXIT_FAILURE);
        }
        printf("Message sent to server\n");
        char message_from_server[4096];
        memset(message_from_server, '\0', 4096);
        int stlen = sizeof(client);
        // Recieve data from server
        if(recvfrom(client_socket, message_from_server, 4096, 0, (struct sockaddr*)&client, &stlen) == -1){
            perror("Error receiving message from server ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from server:\n\033[0;32m%s\033[0;37m\n", message_from_server);

        memset(message_to_server, '\0', 4096);
        scanf("%s", message_to_server);
        if(sendto(client_socket, message_to_server, 1024, 0, (struct sockaddr*)&client, sizeof(client)) == -1){
            perror("Error sending message to server ");
            exit(EXIT_FAILURE);
        }
        printf("Message sent to server\n");
        memset(message_from_server, '\0', 4096);
        if(recvfrom(client_socket, message_from_server, 4096, 0, (struct sockaddr*)&client, &stlen) == -1){
            perror("Error receiving message from server ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from server:\n\033[0;32m%s\033[0;37m\n", message_from_server);
        if(message_from_server[0] == 'E' || message_from_server[0] == 'C')
            break;
    }
    if(close(client_socket) == -1){
        perror("Error closing the client socket: ");
        exit(EXIT_FAILURE);
    }
    printf("Closed socket\n");
    return 0;
}