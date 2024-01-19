#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>

int main(){
    int server_port1 = 7000, server_port2 = 5566;
    // As with TCPClient, the server creates a TCP socket
    int server_socket1 = socket(AF_INET, SOCK_STREAM, 0), client1_socket, client2_socket, server_socket2 = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in server1, server2, client1, client2;
    if(server_socket1 == -1 || server_socket2 == -1){
        perror("Server socket creation error: ");
        exit(EXIT_FAILURE);
    }
    printf("Socket opened\n");
    memset(&server1, 0, sizeof(server1));
    server1.sin_family = AF_INET;
    server1.sin_port = htons(server_port1);
    server1.sin_addr.s_addr = inet_addr("127.0.0.1");

    memset(&server2, 0, sizeof(server1));
    server2.sin_family = AF_INET;
    server2.sin_port = htons(server_port2);
    server2.sin_addr.s_addr = inet_addr("127.0.0.1");

    int opt1 = 1, opt2 = 1;
    if (setsockopt(server_socket1, SOL_SOCKET, SO_REUSEADDR, &opt1, sizeof(opt1)) == -1) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }
    if (setsockopt(server_socket2, SOL_SOCKET, SO_REUSEADDR, &opt2, sizeof(opt2)) == -1) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }
    // Similar to UDPServer, we associate the server port number with this socket:
    if(bind(server_socket1, (struct sockaddr*)&server1, sizeof(server1)) == -1){
        perror("Binding error: ");
        exit(EXIT_FAILURE);
    }
    printf("Bound the server to port:%d\n", server_port1);

    if(bind(server_socket2, (struct sockaddr*)&server2, sizeof(server2)) == -1){
        perror("Binding error: ");
        exit(EXIT_FAILURE);
    }
    printf("Bound the server to port:%d\n", server_port2);
    // Listen for incoming communications
    // server_socket will be our welcoming socket. After establishing this welcoming door, we will wait and listen for some client to knock on the door:
    // here, we are taking backlog [maximum length to which the queue of pending connections for server_socket may grow.] to be 3
    // If a connection request arrives when the queue is full, the client may
    // receive an error with an indication of ECONNREFUSED or, if the
    // underlying protocol supports retransmission, the request may be ignored so that a later reattempt at connection succeeds.
    if (listen(server_socket1, 3) == -1) {
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
    int stlen = sizeof(client1);
    client1_socket = accept(server_socket1, (struct sockaddr *)&client1, &stlen);
    if (client1_socket == -1) {
        perror("Accepting error");
        exit(EXIT_FAILURE);
    }
    printf("Server connected to client with socket: %d\n", client1_socket);
  
    if (listen(server_socket2, 3) == -1) {
        perror("Listening error");
        exit(EXIT_FAILURE);
    }

    client2_socket = accept(server_socket2, (struct sockaddr *)&client2, &stlen);
    if (client2_socket == -1) {
        perror("Accepting error");
        exit(EXIT_FAILURE);
    }
    printf("Server connected to client with socket: %d\n", client2_socket);

    int c1 = 1, c2 = 1;
    while(c1 && c2){
        // Receive data from the client
        char message_from_client1[4096];
        memset(message_from_client1, '\0', 4096);
        if(recv(client1_socket, message_from_client1, 4096, 0) == -1){
            perror("Error in receiving messages from client: ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from client1:\n\033[0;32m%s\033[0;37m\n", message_from_client1);
        char message_from_client2[4096];
        memset(message_from_client2, '\0', 4096);
        if(recv(client2_socket, message_from_client2, 4096, 0) == -1){
            perror("Error in receiving messages from client: ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from client2:\n\033[0;32m%s\033[0;37m\n", message_from_client2);

        if(strcmp(message_from_client1, "Rock") == 0){
            if(strcmp(message_from_client2, "Rock") == 0){
                char *response1 = "DRAW\nDo you wish to play another game?", *response2 = "DRAW\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Paper") == 0){
                char *response1 = "LOST\nDo you wish to play another game?", *response2 = "WIN\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Scissors") == 0){
                char *response1 = "WIN\nDo you wish to play another game?", *response2 = "LOST\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
            else{
                char *response1 = "INVALID INPUT FROM CLIENT2!\nDo you wish to play another game?", *response2 = "INVALID INPUT\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
        }
        else if(strcmp(message_from_client1, "Paper") == 0){
            if(strcmp(message_from_client2, "Rock") == 0){
                char *response1 = "WIN\nDo you wish to play another game?", *response2 = "LOST\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Paper") == 0){
                char *response1 = "DRAW\nDo you wish to play another game?", *response2 = "DRAW\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Scissors") == 0){
                char *response1 = "LOST\nDo you wish to play another game?", *response2 = "WIN\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
            else{
                char *response1 = "INVALID INPUT FROM CLIENT2!\nDo you wish to play another game?", *response2 = "INVALID INPUT\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
        }
        else if(strcmp(message_from_client1, "Scissors") == 0){
            if(strcmp(message_from_client2, "Rock") == 0){
                char *response1 = "LOST\nDo you wish to play another game?", *response2 = "WIN\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Paper") == 0){
                char *response1 = "WIN\nDo you wish to play another game?", *response2 = "LOST\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Scissors") == 0){
                char *response1 = "DRAW\nDo you wish to play another game?", *response2 = "DRAW\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
            else{
                char *response1 = "INVALID INPUT FROM CLIENT2!\nDo you wish to play another game?", *response2 = "INVALID INPUT\nDo you wish to play another game?";
                if(send(client1_socket, response1, strlen(response1), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
                if(send(client2_socket, response2, strlen(response2), 0) == -1){
                    perror("Error in sending message to client: ");
                    exit(EXIT_FAILURE);
                }
            }
        }
        else{
            char *response1 = "INVALID INPUT!\nDo you wish to play another game?", *response2 = "INVALID INPUT FROM CLIENT1!\nDo you wish to play another game?";
            if(send(client1_socket, response1, strlen(response1), 0) == -1){
                perror("Error in sending message to client: ");
                exit(EXIT_FAILURE);
            }
            if(send(client2_socket, response2, strlen(response2), 0) == -1){
                perror("Error in sending message to client: ");
                exit(EXIT_FAILURE);
            }
        }
        memset(message_from_client1, '\0', 4096);
        if(recv(client1_socket, message_from_client1, 4096, 0) == -1){
            perror("Error in receiving messages from client: ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from client1:\n\033[0;32m%s\033[0;37m\n", message_from_client1);
        if(strcmp(message_from_client1, "yes"))
            c1 = 0;
        memset(message_from_client2, '\0', 4096);
        if(recv(client2_socket, message_from_client2, 4096, 0) == -1){
            perror("Error in receiving messages from client: ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from client2:\n\033[0;32m%s\033[0;37m\n", message_from_client2);
        if(strcmp(message_from_client2, "yes"))
            c2 = 0;
        if(c1 && c2){
            char *response1 = "New game. Enter your decision:", *response2 = "New game. Enter your decision:";
            if(send(client1_socket, response1, strlen(response1), 0) == -1){
                perror("Error in sending message to client: ");
                exit(EXIT_FAILURE);
            }
            if(send(client2_socket, response2, strlen(response2), 0) == -1){
                perror("Error in sending message to client: ");
                exit(EXIT_FAILURE);
            }
        }
    }
    if(c1 == 0 && c2 == 0){
        char *response1 = "Ending the game. Thank you for playing!", *response2 = "Ending the game. Thank you for playing!";
        if(send(client1_socket, response1, strlen(response1), 0) == -1){
            perror("Error in sending message to client: ");
            exit(EXIT_FAILURE);
        }
        if(send(client2_socket, response2, strlen(response2), 0) == -1){
            perror("Error in sending message to client: ");
            exit(EXIT_FAILURE);
        }
    }
    else if(c1){
        char *response1 = "Client 2 wants to end the game. Thank you for playing!", *response2 = "Ending the game. Thank you for playing!";
        if(send(client1_socket, response1, strlen(response1), 0) == -1){
            perror("Error in sending message to client: ");
            exit(EXIT_FAILURE);
        }
        if(send(client2_socket, response2, strlen(response2), 0) == -1){
            perror("Error in sending message to client: ");
            exit(EXIT_FAILURE);
        }
    }
    else if(c2){
        char *response1 = "Ending the game. Thank you for playing!", *response2 = "Client 1 wants to end the game. Thank you for playing!";
        if(send(client1_socket, response1, strlen(response1), 0) == -1){
            perror("Error in sending message to client: ");
            exit(EXIT_FAILURE);
        }
        if(send(client2_socket, response2, strlen(response2), 0) == -1){
            perror("Error in sending message to client: ");
            exit(EXIT_FAILURE);
        }
    }
    // Close sockets
    if(close(client1_socket) == -1){
        perror("Error in closing the client socket:");
        exit(EXIT_FAILURE);
    }
    if(close(client2_socket) == -1){
        perror("Error in closing the client socket:");
        exit(EXIT_FAILURE);
    }
    if(close(server_socket1) == -1){
        perror("Error in closing the server socket:");
        exit(EXIT_FAILURE);
    }
    // if(close(server_socket2) == -1){
    //     perror("Error in closing the server socket:");
    //     exit(EXIT_FAILURE);
    // }
    printf("Closed sockets\n");
    return 0;

}