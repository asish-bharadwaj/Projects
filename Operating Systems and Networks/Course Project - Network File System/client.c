#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>

#define SERVER_IP "127.0.0.1" // Naming Server's IP address
#define SERVER_PORT 11111     // Naming Server's port number

struct comStruct
{
    int port;
    char ip[16];
};

int main()
{
    int client_socket;
    struct sockaddr_in server_addr;
    int server_com;
    struct sockaddr_in com_address;
    // server_com = socket(AF_INET, SOCK_STREAM, 0);
    // if (server_com == -1)
    // {
    //     perror("Socket creation failed");
    //     exit(1);
    // }
    // Create a socket for the client
    client_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (client_socket == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Configure the server address
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(SERVER_PORT);
    server_addr.sin_addr.s_addr = inet_addr(SERVER_IP);

    // Connect to the naming server
    if (connect(client_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Connection to the naming server failed");
        close(client_socket);
        exit(1);
    }
    char response[6];
    char con[5];
    char request[1024];
    while (1)
    {
        printf("OPTIONS: \n1. CREATE \n2. DELETE \n3. COPY\n4. READ \n5. WRITE \n6. INFORMATION\n*Enter choice: ");
        // ENTER CHOICE AS 'COMMAND FILE(1)/DIR(2) PATH'
        fgets(request, sizeof(request), stdin);

        send(client_socket, request, strlen(request), 0);
        char cmd[15];
        if (sscanf(request, "%s", cmd) == 1)
        {
            // printf("First word: *%s %d*", cmd,strcmp(cmd,"INFORMATION"));
        }
        if (strcmp(cmd, "INFORMATION") == 0 || strcmp(cmd, "READ") == 0 || strcmp(cmd, "WRITE") == 0)
        {
            recv(client_socket, response, sizeof(response), 0);
            if (strcmp(response, "FAIL") == 0)
            {
                printf("Failed execution!\n");
            }
            else
            {
                struct comStruct com;
                recv(client_socket, &com, sizeof(com), 0);
                // printf("%s %d", com.ip, com.port);
                //  return 0;
                server_com = socket(AF_INET, SOCK_STREAM, 0);
                if (server_com == -1)
                {
                    perror("Socket creation failed");
                    exit(1);
                }
                // Configure the server address
                com_address.sin_family = AF_INET;
                com_address.sin_port = htons(com.port);
                com_address.sin_addr.s_addr = inet_addr(com.ip);

                // Connect to the naming server
                if (connect(server_com, (struct sockaddr *)&com_address, sizeof(com_address)) == -1)
                {
                    perror("Connection to the naming server failed");
                    int errno;
                    printf("Error: %s\n", strerror(errno));
                    close(server_com);
                    exit(1);
                }
                printf("Connected to Storage Server!\n");

                if (strcmp(cmd, "INFORMATION") == 0)
                {
                    int c;
                    printf("1. File Size\n2. Permissions\n3.Both\nEnter choice: ");
                    scanf("%d", &c);
                    send(server_com, &c, sizeof(c), 0);
                    if (c == 1)
                    {
                        char buffer[256];
                        recv(server_com, buffer, sizeof(buffer), 0);
                        if (strcmp(buffer, "Failed") == 0)
                            printf("%s\n", buffer);
                        else
                            printf("File Size: %s bytes\n", buffer);
                        // printf("File Permissions: %o\n", file_permissions);
                    }
                    else if (c == 2)
                    {
                        char buffer[256];
                        recv(server_com, buffer, sizeof(buffer), 0);
                        if (strcmp(buffer, "Failed") == 0)
                            printf("%s\n", buffer);
                        else
                            printf("File Permissions: %s\n", buffer);
                    }
                    else if (c == 3)
                    {

                        char buffer[256];
                        recv(server_com, buffer, sizeof(buffer), 0);
                        if (strcmp(buffer, "Failed") == 0)
                            printf("%s\n", buffer);
                        else
                        {
                            char buffer2[10];
                            recv(server_com, buffer2, sizeof(buffer2), 0);
                            printf("File Size: %s bytes\n", buffer);
                            printf("File Permissions: %s\n", buffer2);
                        }
                    }
                    else
                    {
                        char buffer[256];
                        recv(server_com, buffer, sizeof(buffer), 0);
                        printf("%s\n", buffer);
                    }
                }
                else if (strcmp(cmd, "READ") == 0)
                {
                    char buffer[1024];
                    int c = 0;
                    while (c == 0)
                    {
                        recv(server_com, buffer, sizeof(buffer), 0);
                        if (strcmp("DONE", buffer) == 0)
                        {
                            c = 2; // DONE WITH FILE
                            printf("Finished reading file!\n");
                            snprintf(buffer,sizeof(buffer),"ACK");
                            send(server_com, buffer, sizeof(buffer), 0);
                        }
                        else
                        {
                            printf("%s", buffer);
                           // c = 1;  //stop the loop?
                        }
                        // printf("Do you want the next line? ");
                        // scanf("%s", buffer);
                        
                        // if (strcmp(buffer, "Yes") == 0 && c != 2)
                        //     c = 0;  //Continue loop if file is not over
                    }
                    
                }
                else if (strcmp(cmd, "WRITE") == 0)
                {
                    char buffer[1024];
                    int c = 0;
                    while (c == 0)
                    {
                        printf("Enter line to write to file: ");
                        fgets(buffer,sizeof(buffer),stdin);
                        send(server_com, buffer, sizeof(buffer), 0);
                        c=1;
                        //recv(server_com,buffer,sizeof(buffer),0);
                        printf("Do you want to write the next line? ");
                        fgets(buffer,sizeof(buffer),stdin);
                        //printf("*%s*",buffer);
                        send(server_com, buffer, sizeof(buffer), 0);
                        if (strcmp(buffer, "Yes\n") == 0)
                             c = 0;
                    }
                }
                close(server_com);
                //  printf("%s",buffer);
                //   printf("%s %d",com.ip,com.port);
            }
        }
        else if (strcmp(cmd, "COPY") == 0 || strcmp(cmd, "CREATE") == 0 || strcmp(cmd, "DELETE") == 0)
        {
            recv(client_socket, response, sizeof(response), 0);
            //printf("$%s$",response);
            //return 0;
            if (strcmp(response, "ACK") == 0)
            {
                printf("Successful!\n");
            }
            else
            {
                printf("Failed execution.\n");
            }
        }


        printf("Would you like to continue? ");
        scanf("%s", con);
        int c;
        while ((c = getchar()) != '\n' && c != EOF)
            ;

        if (strcmp(con, "Yes") == 0)
        {
            continue;
        }
        else
        {
            // TELL NMS TO STOP
            close(client_socket);
            return 0;
        }
    }
    // Close the client socket
    close(client_socket);

    return 0;
}