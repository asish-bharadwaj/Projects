#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>

int main(){
    int server_port1 = 7000, server_port2 = 5566;
    struct sockaddr_in server1, server2, client1, client2;
    // As with UDPClient, the server creates a UDP socket
    int server_socket1 = socket(AF_INET, SOCK_DGRAM, 0), server_socket2 = socket(AF_INET, SOCK_DGRAM, 0);
    if(server_socket1 == -1 || server_socket2 == -1){
        perror("Error in opening socket ");
        exit(EXIT_FAILURE);
    }
    printf("Sockets opened\n");
    memset(&server1, 0, sizeof(server1));
    server1.sin_family = AF_INET;
    server1.sin_port = htons(server_port1);
    server1.sin_addr.s_addr = inet_addr("127.0.0.1");

    memset(&server2, 0, sizeof(server1));
    server2.sin_family = AF_INET;
    server2.sin_port = htons(server_port2);
    server2.sin_addr.s_addr = inet_addr("127.0.0.1");
    int stlen = sizeof(client1);
    int opt1 = 1, opt2 = 1;
    if (setsockopt(server_socket1, SOL_SOCKET, SO_REUSEADDR, &opt1, sizeof(opt1)) == -1) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }
    if (setsockopt(server_socket2, SOL_SOCKET, SO_REUSEADDR, &opt2, sizeof(opt2)) == -1) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }
    // bind to any incoming clients, associate the server port number with this socket:
    if(bind(server_socket1, (struct sockaddr*)&server1, sizeof(server1)) == -1){
        perror("Binding error ");
        exit(EXIT_FAILURE);
    }
    printf("Bound the server to port:%d\n", server_port1);

    if(bind(server_socket2, (struct sockaddr*)&server2, sizeof(server2)) == -1){
        perror("Binding error: ");
        exit(EXIT_FAILURE);
    }
    printf("Bound the server to port:%d\n", server_port2);

    int c1 = 1, c2 = 1;
    while(c1 && c2){
        // Receive data from the client
        char message_from_client1[4096], message_from_client2[4096];
        memset(message_from_client1, '\0', 4096);
        memset(message_from_client2, '\0', 4096);
        if(recvfrom(server_socket1, message_from_client1, 4096, 0, (struct sockaddr*)&client1, &stlen) == -1){
            perror("Error recceiving message from client ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from client1:\n\033[0;32m%s\033[0;37m\n", message_from_client1);
        if(recvfrom(server_socket2, message_from_client2, 4096, 0, (struct sockaddr*)&client2, &stlen) == -1){
            perror("Error recceiving message from client ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from client2:\n\033[0;32m%s\033[0;37m\n", message_from_client2);

        if(strcmp(message_from_client1, "Rock") == 0){
            if(strcmp(message_from_client2, "Rock") == 0){
                char *response1 = "DRAW\nDo you wish to play another game?", *response2 = "DRAW\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Paper") == 0){
                char *response1 = "LOST\nDo you wish to play another game?", *response2 = "WIN\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Scissors") == 0){
                char *response1 = "WIN\nDo you wish to play another game?", *response2 = "LOST\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
            else{
                char *response1 = "INVALID INPUT FROM CLIENT2!\nDo you wish to play another game?", *response2 = "INVALID INPUT\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
        }
        else if(strcmp(message_from_client1, "Paper") == 0){
            if(strcmp(message_from_client2, "Rock") == 0){
                char *response1 = "WIN\nDo you wish to play another game?", *response2 = "LOST\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Paper") == 0){
                char *response1 = "DRAW\nDo you wish to play another game?", *response2 = "DRAW\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Scissors") == 0){
                char *response1 = "LOST\nDo you wish to play another game?", *response2 = "WIN\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
            else{
                char *response1 = "INVALID INPUT FROM CLIENT2!\nDo you wish to play another game?", *response2 = "INVALID INPUT\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
        }
        else if(strcmp(message_from_client1, "Scissors") == 0){
            if(strcmp(message_from_client2, "Rock") == 0){
                char *response1 = "LOST\nDo you wish to play another game?", *response2 = "WIN\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Paper") == 0){
                char *response1 = "WIN\nDo you wish to play another game?", *response2 = "LOST\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
            else if(strcmp(message_from_client2, "Scissors") == 0){
                char *response1 = "DRAW\nDo you wish to play another game?", *response2 = "DRAW\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
            else{
                char *response1 = "INVALID INPUT FROM CLIENT2!\nDo you wish to play another game?", *response2 = "INVALID INPUT\nDo you wish to play another game?";
                if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
                if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            }
        }
        else{
            char *response1 = "INVALID INPUT!\nDo you wish to play another game?", *response2 = "INVALID INPUT FROM CLIENT1!\nDo you wish to play another game?";
            if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
            if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                    perror("Error sending message to server");
                    exit(EXIT_FAILURE);
                }
        }
        memset(message_from_client1, '\0', 4096);
        if(recvfrom(server_socket1, message_from_client1, 4096, 0, (struct sockaddr*)&client1, &stlen) == -1){
            perror("Error recceiving message from client ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from client1:\n\033[0;32m%s\033[0;37m\n", message_from_client1);
        if(strcmp(message_from_client1, "yes"))
            c1 = 0;
        memset(message_from_client2, '\0', 4096);
        if(recvfrom(server_socket2, message_from_client2, 4096, 0, (struct sockaddr*)&client2, &stlen) == -1){
            perror("Error recceiving message from client ");
            exit(EXIT_FAILURE);
        }
        printf("Message received from client2:\n\033[0;32m%s\033[0;37m\n", message_from_client2);
        if(strcmp(message_from_client2, "yes"))
            c2 = 0;
        if(c1 && c2){
            char *response1 = "New game. Enter your decision:", *response2 = "New game. Enter your decision:";
            if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
                perror("Error sending message to server");
                exit(EXIT_FAILURE);
            }
            if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
                perror("Error sending message to server");
                exit(EXIT_FAILURE);
            }
        }
    }

    if(c1 == 0 && c2 == 0){
        char *response1 = "Ending the game. Thank you for playing!", *response2 = "Ending the game. Thank you for playing!";
        if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
            perror("Error sending message to server");
            exit(EXIT_FAILURE);
        }
        if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
            perror("Error sending message to server");
            exit(EXIT_FAILURE);
        }
    }
    else if(c1){
        char *response1 = "Client 2 wants to end the game. Thank you for playing!", *response2 = "Ending the game. Thank you for playing!";
        if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
            perror("Error sending message to server");
            exit(EXIT_FAILURE);
        }
        if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
            perror("Error sending message to server");
            exit(EXIT_FAILURE);
        }
    }
    else if(c2){
        char *response1 = "Ending the game. Thank you for playing!", *response2 = "Client 1 wants to end the game. Thank you for playing!";
        if(sendto(server_socket1, response1, 4096, 0, (struct sockaddr*)&client1, sizeof(client1)) == -1){
            perror("Error sending message to server");
            exit(EXIT_FAILURE);
        }
        if(sendto(server_socket2, response2, 4096, 0, (struct sockaddr*)&client2, sizeof(client2)) == -1){
            perror("Error sending message to server");
            exit(EXIT_FAILURE);
        }
    }
    // Close sockets
    if(close(server_socket1) == -1){
        perror("Error in closing the server socket:");
        exit(EXIT_FAILURE);
    }
    if(close(server_socket2) == -1){
        perror("Error in closing the server socket:");
        exit(EXIT_FAILURE);
    }
    printf("Closed sockets\n");
    return 0;
}