// ns.c (Naming Server)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>

// #include "tries.c"

// Data structure to store information about storage servers
#define MAX_PATHS 100
#define NM_PORT 11111
#define CLIENT_PORT 54321

#define max_servers 5
int num_registered_servers = 0;

// Structure to hold SS information
struct StorageServerInfo
{
    int num_paths;
    int nm_port;
    int client_port;
    char ip_address[16];                   // Assuming IPv4 address
    char accessible_paths[MAX_PATHS][256]; // Array to store accessible paths
    int socket;
    struct TrieNode *trieRoot;
};

struct comStruct
{
    int port;
    char ip[16];
};

struct StorageServerInfo registered_servers[max_servers];

struct DataSent
{
    int ss_no;
    int file_or_dir; // 1: File 2: Dir
    char path[1024];
    int request; // 1: Create 2: Delete 3. Copy 4. Read 5. Write 6. Size & Permissions
    char file[1024];
    int ss_no2; // for copying
    char dest[1024];
};

struct TrieNode
{
    int isEndOfPath;
    struct TrieNode *children[37]; // 26 alphabetic characters + 0-9 + '/'
};

int getIndex(char c)
{
    if (c >= 'a' && c <= 'z')
    {
        return c - 'a'; // For alphabetic characters (a-z)
    }
    else if (c >= '0' && c <= '9')
    {
        return c - '0' + 26; // For numeric characters (0-9)
    }
    else if (c == '/')
    {
        return 36; // For the '/' character
    }
    else
    {
        // Handle other characters as needed
        return -1;
    }
}

struct TrieNode *createTrieNode()
{
    struct TrieNode *node = (struct TrieNode *)malloc(sizeof(struct TrieNode));
    for (int i = 0; i < 37; i++)
    {
        node->children[i] = 0;
    }
    node->isEndOfPath = 0;
    return node;
}

void insertPath(struct TrieNode *root, const char *path)
{
    printf("#%s#", path);
    struct TrieNode *node = root;
    for (int i = 0; path[i] != '\0' && path[i] != '\n'; i++)
    {
        int index = getIndex(path[i]);
        // printf("%d ",index);
        if (!node->children[index])
        {
            node->children[index] = createTrieNode();
        }
        node = node->children[index];
    }
    node->isEndOfPath = 1;
}

// Function to check if a TrieNode has any children
int hasChild(struct TrieNode *node)
{
    for (int i = 0; i < 37; i++)
    {
        if (node->children[i])
        {
            return 1;
        }
    }
    return 0;
}

// Function to remove a path from the Trie
void removePath(struct TrieNode *root, const char *path)
{
    struct TrieNode *node = (struct TrieNode *)malloc(sizeof(struct TrieNode));
    node = root;
    for (int i = 0; path[i] != '\0' && path[i] != '\n'; i++)
    {
        int index = getIndex(path[i]);
        // printf("%d ",index);
        // printf("%c ",path[i]);
        if (node->children[index] == 0)
        {
            return; // Path not found
        }

        node = node->children[index];
        // printf("%d\n ",node->isEndOfPath);
        // if (node->isEndOfPath)
        // {
        //     return 1;
        // }
    }

    // Mark the last node as not being the end of the path
    node->isEndOfPath = 0;
    // return;

    // Remove any nodes with no other children (backward deletion)
    for (int i = strlen(path) - 1; i >= 0; i--)
    {
        int index = path[i];
        if (node->children[index])
        {
            if (node->isEndOfPath || hasChild(node))
            {
                // Stop removing if this node is an end of another path
                break;
            }
            else
            {
                // free(node->children[index]);
                node->children[index] = 0;
            }
            node = node->children[index];
        }
    }
    return;
    // printf("Removed");
}

int searchPath(struct TrieNode *root, const char *path)
{
    // printf("hi *%s*",path);
    struct TrieNode *node = (struct TrieNode *)malloc(sizeof(struct TrieNode));
    node = root;
    for (int i = 0; path[i] != '\0' && path[i] != '\n'; i++)
    {
        int index = getIndex(path[i]);
        // printf("%d ",index);
        // printf("%c ",path[i]);
        if (node->children[index] == 0)
        {
            return 0; // Path not found
        }

        node = node->children[index];
        // printf("%d\n ",node->isEndOfPath);
        // if (node->isEndOfPath)
        // {
        //     return 1;
        // }
    }
    //    printf("%d ",node->isEndOfPath);
    return node->isEndOfPath;
}

int findStorageServerForPath(const char *path, struct StorageServerInfo *registered_servers, int num_servers)
{
    // printf("hii %d %s ",num_servers,path);
    for (int i = 0; i < num_servers; i++)
    {
        struct TrieNode *root = registered_servers[i].trieRoot;
        // printf("hi %d ",registered_servers[i].trieRoot->isEndOfPath);
        if (searchPath(root, path))
        {
            return i; // Return the index of the storage server where the path was found
        }
    }
    return -1; // Return -1 if the path was not found in any storage server
}

// Mutex for ensuring thread safety while updating the server list
pthread_mutex_t server_list_mutex = PTHREAD_MUTEX_INITIALIZER;

pthread_mutex_t output_mutex = PTHREAD_MUTEX_INITIALIZER;
void *acceptStorageServerConnections(void *server_socket)
{
    struct DataSent data;
    int client;
    struct sockaddr_in server_address, client_address;
    socklen_t client_address_len = sizeof(client_address);
    char buffer[1024];
    int serversock = *((int *)server_socket);

    while (1)
    {
        // printf("HI %d", serversock);
        int ss_socket = accept(serversock, (struct sockaddr *)&client_address, &client_address_len);
        if (ss_socket == -1)
        {
            perror("Can't accept connection");
            close(serversock);
            exit(EXIT_FAILURE);
        }

        pthread_mutex_lock(&output_mutex);
        printf("Connected to storage server\n");
        pthread_mutex_unlock(&output_mutex);

        struct StorageServerInfo received_ss_info;
        if (recv(ss_socket, &received_ss_info, sizeof(received_ss_info), 0) != -1)
        {
            printf("%d *%s* %s %s\n", received_ss_info.num_paths, received_ss_info.ip_address, received_ss_info.accessible_paths[0], received_ss_info.accessible_paths[1]);
            // Add the received SS information to the list of registered servers
            if (num_registered_servers < max_servers)
            {
                pthread_mutex_lock(&server_list_mutex);
                received_ss_info.socket = ss_socket;
                received_ss_info.trieRoot = createTrieNode();
                for (int i = 0; i < received_ss_info.num_paths; i++)
                {
                    insertPath(received_ss_info.trieRoot, received_ss_info.accessible_paths[i]);
                }
                registered_servers[num_registered_servers] = received_ss_info;
                // printf("%d ", received_ss_info.trieRoot->isEndOfPath);
                num_registered_servers++;
                pthread_mutex_unlock(&server_list_mutex);
            }
            else
            {
                break;
                // Handle the case when the maximum number of SSs is reached
                // You may want to implement error handling or log this event
            }
        }
        else
        {
            // Handle incomplete or incorrect SS registration data
            // You may want to implement error handling or log this event
        }
        printf("Storage Server Initialized\n");
    }
}

int find_ss_for_path(const char *path, struct StorageServerInfo *registered_servers, int num_servers)
{
    for (int i = 0; i < num_servers; i++)
    {
        struct StorageServerInfo ss = registered_servers[i];
        // printf("%d ",ss.num_paths);
        //  Check if the path matches any of the accessible paths for this SS
        for (int j = 0; j < ss.num_paths; j++)
        {
            // printf("%s %s\n",path,ss.accessible_paths[j]);
            if (strcmp(path, ss.accessible_paths[j]) == 0)
            {
                // Found a match, return this SS as the selected SS
                return i;
            }
        }
    }

    // If no matching SS is found, return an error or handle it appropriately
    return -1; // Or use a specific error indicator
}

int copyDirectory(const char *source_dir, const char *destination_dir, int ss_no2)
{

    struct stat st;
    if (stat(destination_dir, &st) != 0)
    {
        // If the destination directory does not exist, create it
        mkdir(destination_dir, 0777);
    }

    DIR *dir = opendir(source_dir);
    struct dirent *entry;

    if (dir == NULL)
    {
        printf("Failed to open source directory: %s\n", source_dir);
        return 0;
    }

    while ((entry = readdir(dir)) != NULL)
    {
        if (entry->d_type == DT_REG)
        {
            // If the entry is a file, copy it to the destination directory
            char source_path[PATH_MAX];
            char destination_path[PATH_MAX];

            snprintf(source_path, sizeof(source_path), "%s/%s", source_dir, entry->d_name);
            snprintf(destination_path, sizeof(destination_path), "%s/%s", destination_dir, entry->d_name);

            FILE *source_file = fopen(source_path, "rb");
            FILE *destination_file = fopen(destination_path, "wb");

            if (source_file == NULL || destination_file == NULL)
            {
                printf("Failed to copy file: %s\n", entry->d_name);
                fclose(source_file);
                fclose(destination_file);
                continue;
            }

            char ch;
            while ((ch = fgetc(source_file)) != EOF)
                fputc(ch, destination_file);

            fclose(source_file);
            fclose(destination_file);
            insertPath(registered_servers[ss_no2].trieRoot, destination_path);
        }
        else if (entry->d_type == DT_DIR && strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0)
        {
            // If the entry is a subdirectory, recursively copy it
            char sub_source_dir[PATH_MAX];
            char sub_destination_dir[PATH_MAX];

            snprintf(sub_source_dir, sizeof(sub_source_dir), "%s/%s", source_dir, entry->d_name);
            snprintf(sub_destination_dir, sizeof(sub_destination_dir), "%s/%s", destination_dir, entry->d_name);

            int x = copyDirectory(sub_source_dir, sub_destination_dir, ss_no2);
        }
    }

    closedir(dir);
    return 1;
}
int main()
{
    // ...
    struct DataSent data;
    int serversock, client;
    struct sockaddr_in server_address, client_address;
    socklen_t client_address_len = sizeof(client_address);
    char buffer[1024];

    // Create a TCP socket
    serversock = socket(AF_INET, SOCK_STREAM, 0);
    if (serversock == -1)
    {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(11111); // set port
    server_address.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket to a specific address and port
    if (bind(serversock, (struct sockaddr *)&server_address, sizeof(server_address)) == -1)
    {
        perror("Can't bind socket");
        close(serversock);
        exit(EXIT_FAILURE);
    }

    // Listen for incoming connections
    if (listen(serversock, 5) == -1) // maximum length to which the queue of pending connections for sockfd may grow.
    {
        perror("Error listening");
        close(serversock);
        exit(EXIT_FAILURE);
    }

    pthread_t accept_storage_server_tid;
    if (pthread_create(&accept_storage_server_tid, NULL, acceptStorageServerConnections, (void *)&serversock) != 0)
    {
        perror("Failed to create the storage server connection handling thread");
        close(serversock);
        exit(EXIT_FAILURE);
    }

    int input = 0;
    struct sockaddr_in client_connection;
    socklen_t client_connection_len = sizeof(client_connection);
    int client_socket = accept(serversock, (struct sockaddr *)&client_connection, &client_connection_len);
    if (client_socket == -1)
    {
        perror("Error accepting client connection");
        // continue;
    }
    char command[1024];
    char opt[2];
    char path[1024];
    char dest[1024];
    int pathind, cmdind, destind, i, option;
    while (1)
    {
        // printf("HIIII");
        char req[1024];
        command[0] = '\0';
        path[0] = '\0';
        dest[0] = '0';
        // printf("%d ",input);
        pathind = 0, cmdind = 0, destind = 0, i = 0;
        int rec_data = recv(client_socket, req, sizeof(req), 0);
        if (rec_data != -1)
        {
            req[rec_data] = '\0';
            for (; req[i] != ' '; i++)
            {
                command[cmdind++] = req[i];
            }
            command[cmdind] = '\0';
            i++;
            for (; req[i] != ' '; i++)
            {
                opt[0] = req[i];
            }
            i++;
            opt[1] = '\0';
            option = atoi(opt);
            command[cmdind] = '\0';
            if(req[i]=='.' && req[i+1]=='/')
            i+=2;
            for (; req[i] != ' ' && req[i] != '\0' && req[i] != '\n'; i++)
            {
                path[pathind++] = req[i];
            }
            path[pathind] = '\0';

             printf("%s\n%s ", command, path);
            // char *command2 = strtok(req, " "); // Split by space and newline
            // char *file_path = strtok(NULL, "\n");  // Get the remaining part

            // if (command2 != NULL && file_path != NULL)
            // {
            //     printf("Command: %s\n", command2);
            //     printf("File Path: %s\n", file_path);
            //     if (strcmp(command2, "CREATE") == 0)
            //         input = 1;
            //     else if (strcmp(command2, "DELETE") == 0)
            //         input = 2;
            //     else if (strcmp(command2, "COPY") == 0)
            //         input = 3;
            //     else if (strcmp(command2, "READ") == 0)
            //     {
            //         input = 4;
            //         printf("hi");
            //     }
            // }

            if (strcmp(command, "CREATE") == 0)
                input = 1;
            else if (strcmp(command, "DELETE") == 0)
                input = 2;
            else if (strcmp(command, "COPY") == 0)
                input = 3;
            else if (strcmp(command, "READ") == 0)
            {
                input = 4;
                // printf("hi");
            }
            else if (strcmp(command, "WRITE") == 0)
                input = 5;
            else if (strcmp(command, "INFORMATION") == 0)
                input = 6;
            else
            {
                printf("Invalid input");
                char buffer[] = "FAIL";
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }
            printf("%d", input);
        }
        else
        {
            printf("Fail\n");
            char buffer[] = "FAIL";
            int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
            continue;
        }
        // printf("Done cli");

        // printf("%d", input);
        // return 0;
        if (input == 1 || input == 2)
        {
            // char path[1024];
            char dir[1024];
            char file[1024];
            // printf("1. File\n2. Directory\nEnter choice: ");
            // int option;
            // scanf("%d", &option);
            // printf("Enter path: ");
            // scanf("%s", path);

            char *lastSlash = strrchr(path, '/'); // Find the last occurrence of '/'
            if (lastSlash != NULL)
            {
                // Copy the directory part (excluding the last '/')
                strncpy(dir, path, lastSlash - path);
                dir[lastSlash - path] = '\0'; // Null-terminate the directory string

                // Copy the filename part (after the last '/')
                strcpy(file, lastSlash + 1);
            }
            else
            {
                // No '/' found, consider the whole path as the filename
                strcpy(dir, "");
                strcpy(file, path);
            }

            // printf("%s\n%s", dir, file);

            // int ss_no = find_ss_for_path(dir, registered_servers, num_registered_servers);
            int ss_no;
            if (input == 1)
            {
                ss_no = findStorageServerForPath(dir, registered_servers, num_registered_servers);
            }
            if (input == 2)
            {
                ss_no = findStorageServerForPath(path, registered_servers, num_registered_servers);
            }
            if (ss_no == -1)
            {
                printf("Invalid path\n");
                char buffer[] = "FAIL";
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }

            // int ss_no2 = searchPath(registered_servers[0].trieRoot, dir);
            printf("#%d ", ss_no);
            data.file_or_dir = option;
            data.request = input;
            data.ss_no = ss_no;
            snprintf(data.path, 1024, "%s", path);

            int ss_sock;
            struct sockaddr_in server_addr;
            int server_com;
            struct sockaddr_in com_address;
            ss_sock = socket(AF_INET, SOCK_STREAM, 0);
            if (ss_sock == -1)
            {
                perror("Socket creation failed");
                exit(1);
            }

            // Configure the server address
            server_addr.sin_family = AF_INET;
            server_addr.sin_port = htons(registered_servers[ss_no].nm_port);
            server_addr.sin_addr.s_addr = inet_addr(registered_servers[ss_no].ip_address);

            // Connect to the naming server
            if (connect(ss_sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
            {
                perror("Connection to the naming server failed");
                close(ss_sock);
                exit(1);
            }

            int sent_data = send(ss_sock, &data, sizeof(data), 0);
            if (sent_data == -1)
            {
                perror("Can't send data");
                close(serversock);
                close(ss_sock);
                exit(EXIT_FAILURE);
            }
            if (input == 1)
            {
                // printf("hi");
                insertPath(registered_servers[ss_no].trieRoot, path);
                // return 0;
            }
            if (input == 2)
            {
                removePath(registered_servers[ss_no].trieRoot, path);
                // int s = findStorageServerForPath(path, registered_servers, num_registered_servers);
                // printf("hihi *%d",s);
                // return 0;
                //   received_data = recv(ss_sock, &registered_servers[data.ss_no], sizeof(registered_servers[data.ss_no]), 0);
                //   if (received_data == -1)
                //   {
                //       perror("Can't send data");
                //       close(serversock);
                //       close(ss_sock);
                //       exit(EXIT_FAILURE);
                //   }
            }

            // printf("*%s* ",registered_servers[data.ss_no].ip_address);
            char buffer[6];
            int received_data = recv(ss_sock, buffer, sizeof(buffer), 0);
            if (received_data == -1)
            {
                perror("Can't send data");
                close(serversock);
                close(ss_sock);
                exit(EXIT_FAILURE);
            }
            // printf("$%s ",buffer);
            // return 0;
            if (strcmp(buffer, "ACK") == 0)
            {
                sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }

            else
            {
                // printf("%s ",buffer);
                printf("Failed Execution.\n");
                sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }

            // printf("%s",path);
        }
        else if (input == 3)
        {
            i++;
            for (; req[i] != ' ' && req[i] != '\n' && req[i] != '\0'; i++)
            {
                dest[destind++] = req[i];
            }
            dest[destind] = '\0';

            char dir[1024];
            char file[1024];
            // printf("1. File\n2. Directory\nEnter choice: ");
            // int option;
            // scanf("%d", &option);
            // printf("Enter path: ");
            // scanf("%s", path);

            char *lastSlash = strrchr(path, '/'); // Find the last occurrence of '/'
            if (lastSlash != NULL)
            {
                // Copy the directory part (excluding the last '/')
                strncpy(dir, path, lastSlash - path);
                dir[lastSlash - path] = '\0'; // Null-terminate the directory string

                // Copy the filename part (after the last '/')
                strcpy(file, lastSlash + 1);
            }
            else
            {
                // No '/' found, consider the whole path as the filename
                strcpy(dir, "");
                strcpy(file, path);
            }

            char dir2[1024];
            char file2[1024];
            char *lastSlash2 = strrchr(dest, '/'); // Find the last occurrence of '/'
            if (lastSlash2 != NULL)
            {
                // Copy the directory part (excluding the last '/')
                strncpy(dir2, dest, lastSlash2 - dest);
                dir2[lastSlash2 - dest] = '\0'; // Null-terminate the directory string

                // Copy the filename part (after the last '/')
                strcpy(file2, lastSlash2 + 1);
            }
            else
            {
                // No '/' found, consider the whole path as the filename
                strcpy(dir2, "");
                strcpy(file2, dest);
            }

            // printf("%s %s\n %s %s", dir, file,dir2,file2);
            // return 0;

            // int ss_no = find_ss_for_path(dir, registered_servers, num_registered_servers);

            int ss_no = findStorageServerForPath(path, registered_servers, num_registered_servers);
            if (ss_no == -1)
            {
                printf("Invalid path\n");
                char buffer[] = "FAIL";
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }
            int ss_no2 = findStorageServerForPath(dest, registered_servers, num_registered_servers);
            if (ss_no2 == -1)
            {
                printf("Invalid path\n");
                char buffer[] = "FAIL";
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }
            // int ss_no2 = searchPath(registered_servers[0].trieRoot, dir);
            printf("#%d %d ", ss_no, ss_no2);
            // return 0;
            data.file_or_dir = option;
            data.request = input;
            data.ss_no = ss_no;
            data.ss_no2 = ss_no2;
            snprintf(data.path, 1024, "%s", path);
            snprintf(data.dest, 1024, "%s", dest);

            int ss_sock;
            struct sockaddr_in server_addr;
            int server_com;
            struct sockaddr_in com_address;
            ss_sock = socket(AF_INET, SOCK_STREAM, 0);
            if (ss_sock == -1)
            {
                perror("Socket creation failed");
                exit(1);
            }

            // Configure the server address
            server_addr.sin_family = AF_INET;
            server_addr.sin_port = htons(registered_servers[ss_no].nm_port);
            server_addr.sin_addr.s_addr = inet_addr(registered_servers[ss_no].ip_address);

            // Connect to the naming server
            if (connect(ss_sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
            {
                perror("Connection to the naming server failed");
                close(ss_sock);
                exit(1);
            }

            int sent_data = send(ss_sock, &data, sizeof(data), 0);
            if (sent_data == -1)
            {
                perror("Can't send data");
                close(serversock);
                close(ss_sock);
                exit(EXIT_FAILURE);
            }
            if (ss_no != ss_no2)
            {
                int sent_data = send(registered_servers[ss_no2].socket, &data, sizeof(data), 0);
                if (sent_data == -1)
                {
                    perror("Can't send data");
                    close(serversock);
                    close(ss_sock);
                    exit(EXIT_FAILURE);
                }
            }

            if (data.file_or_dir == 1)
            {
                FILE *source_file = fopen(data.path, "r");
                if (source_file == NULL)
                {
                    printf("Failed to open source file: %s\n", data.path);
                    char buffer[] = "FAIL";
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    continue;
                }

                strcat(data.dest,"/");
                strcat(data.dest,file);
                insertPath(registered_servers[ss_no2].trieRoot,data.dest);

                FILE *destination_file = fopen(data.dest, "w");
                if (destination_file == NULL)
                {
                    printf("Failed to create or open destination file: %s\n", data.dest);
                    fclose(source_file);
                    char buffer[] = "FAIL";
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    continue;
                }

                // char buffer2[4096];
                // size_t bytes_read;

                // while (bytes_read = fread(buffer2, 1, sizeof(buffer2), source_file) > 0)
                // {
                //     size_t bytes_written = fwrite(buffer2, 1, bytes_read, destination_file);

                //     if (bytes_written != bytes_read)
                //     {
                //         printf("Failed to write to destination file.\n");
                //         fclose(source_file);
                //         fclose(destination_file);
                //         char buffer[] = "FAIL";
                //         int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                //         // Handle error and exit loop or continue as needed.
                //         break;
                //     }
                // }
                char ch;
                while ((ch = fgetc(source_file)) != EOF)
                    fputc(ch, destination_file);
                fclose(source_file);
                fclose(destination_file);
                char buffer[] = "ACK";
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                insertPath(registered_servers[ss_no2].trieRoot, path);
                continue;
            }
            if (data.file_or_dir == 2)
            {
                int x = copyDirectory(path, dest, ss_no2);
                if (x == 0)
                {
                    char buffer[] = "FAIL";
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                }
                else
                {
                    char buffer[] = "ACK";
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                }
            }

            // int sent_data = send(ss_sock, &data, sizeof(data), 0);
            // if (sent_data == -1)
            // {
            //     perror("Can't send data");
            //     close(serversock);
            //     close(ss_sock);
            //     exit(EXIT_FAILURE);
            // }

            // printf("*%s* ",registered_servers[data.ss_no].ip_address);
            // char buffer[6];
            // int received_data = recv(ss_sock, buffer, sizeof(buffer), 0);
            // if (received_data == -1)
            // {
            //     perror("Can't send data");
            //     close(serversock);
            //     close(ss_sock);
            //     exit(EXIT_FAILURE);
            // }
            // printf("$%s ",buffer);
            // if (strcmp(buffer, "ACK") == 0)
            // {
            //     sent_data = send(client_socket, buffer, sizeof(buffer), 0);
            //     continue;
            // }

            // else
            // {
            //     // printf("%s ",buffer);
            //     printf("Failed Execution.\n");
            //     sent_data = send(client_socket, buffer, sizeof(buffer), 0);
            //     continue;
            // }
        }
        // else if (input == 4)
        // {
        // }
        // else if (input == 5)
        // {
        // }
        else if (input == 4 || input == 5 || input == 6)
        {
            int ss_no = findStorageServerForPath(path, registered_servers, num_registered_servers);
            //  printf("%d ",ss_no);
            //  return 0;
            if (ss_no == -1)
            {
                printf("Invalid path\n");
                char buffer[] = "FAIL";
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }
            else
            {
                char buffer[] = "FOUND";
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                struct comStruct com;
                com.port = registered_servers[ss_no].client_port;
                snprintf(com.ip, 17, "%s", registered_servers[ss_no].ip_address);
                printf("%s %d", com.ip, com.port);

                data.file_or_dir = option;
                data.request = input;
                data.ss_no = ss_no;
                snprintf(data.path, 1024, "%s", path);

                int ss_sock;
                struct sockaddr_in server_addr;
                int server_com;
                struct sockaddr_in com_address;
                ss_sock = socket(AF_INET, SOCK_STREAM, 0);
                if (ss_sock == -1)
                {
                    perror("Socket creation failed");
                    exit(1);
                }

                // Configure the server address
                server_addr.sin_family = AF_INET;
                server_addr.sin_port = htons(registered_servers[ss_no].nm_port);
                server_addr.sin_addr.s_addr = inet_addr(registered_servers[ss_no].ip_address);

                // Connect to the naming server
                if (connect(ss_sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
                {
                    perror("Connection to the naming server failed");
                    close(ss_sock);
                    exit(1);
                }
                //  printf("%d",data.request);
                //  return 0;
                sent_data = send(ss_sock, &data, sizeof(data), 0);
                if (sent_data == -1)
                {
                    perror("Can't send data");
                    close(serversock);
                    close(ss_sock);
                    exit(EXIT_FAILURE);
                }
                sent_data = send(client_socket, &com, sizeof(com), 0);
                // rec_data = recv(client_socket, req, sizeof(req), 0);
                // return 0;
            }
        }

        // close(client_socket);
    }
    close(client_socket);
    // Join the storage server connection handling thread
    pthread_join(accept_storage_server_tid, NULL);
    return 0;

    // ...
}
