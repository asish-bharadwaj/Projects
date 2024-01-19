#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <dirent.h>
#include "headers.h"

#define MAX_PATHS 100
#define NM_PORT 11111

struct TrieNode
{
    int isEndOfPath;
    struct TrieNode *children[37]; // 26 alphabetic characters + 1 for '/'
};
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
    char cwd[256]; // change
};

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
    for (int i = 0; i < 27; i++)
    {
        node->children[i] = 0;
    }
    node->isEndOfPath = 0;
    return node;
}

void insertPath(struct TrieNode *root, const char *path)
{
    struct TrieNode *node = root;
    for (int i = 0; path[i] != '\0'; i++)
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

int

delete_directory(const char *path)
{
    DIR *dir;
    struct dirent *entry;
    char file_path[1024];

    if ((dir = opendir(path)) == NULL)
    {
        return -1;
    }

    while ((entry = readdir(dir)) != NULL)
    {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
        {
            continue;
        }

        snprintf(file_path, sizeof(file_path), "%s/%s", path, entry->d_name);

        if (entry->d_type == DT_DIR)
        {
            delete_directory(file_path);
        }
        else
        {
            remove(file_path);
        }
    }

    closedir(dir);
    rmdir(path);
    return 0;
}

int main(int argc, char *argv[])
{

    int clientsock;
    struct sockaddr_in server_address;
    char buffer[1024];

    // Create a TCP socket
    clientsock = socket(AF_INET, SOCK_STREAM, 0);
    if (clientsock == -1)
    {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(11111);
    server_address.sin_addr.s_addr = inet_addr("127.0.0.1"); // Server IP address

    // Connect to the server
    if (connect(clientsock, (struct sockaddr *)&server_address, sizeof(server_address)) == -1)
    {
        perror("Error connecting to server");
        close(clientsock);
        exit(EXIT_FAILURE);
    }

    char initial_req[] = "rss";
    int sent_initial_req = send(clientsock, initial_req, sizeof(initial_req), 0);
    if (sent_initial_req == -1)
    {
        perror("Error sending data");
        close(clientsock);
        exit(EXIT_FAILURE);
    }

    printf("Connected to server\n");
    // Number of Storage Servers to initialize (you can change this as needed)
    int num_registered_servers = 0;
    int max_servers = 5;
    struct StorageServerInfo registered_servers[max_servers];
    if (argc != 4)
    {
        fprintf(stderr, "Usage: %s <IP address> <Port>\n", argv[0]);
        exit(1);
    }
    // for (int i = 0; i < num_servers; i++)
    // {
    // Initialize SS_i details
    struct StorageServerInfo ss_i;
    ss_i.num_paths = __INT_MAX__;
    const char *ip = argv[1];
    int port = atoi(argv[2]);
    int port2 = atoi(argv[3]);
    ss_i.nm_port = port2;
    snprintf(ss_i.ip_address, sizeof(ss_i.ip_address), "%s", ip);
    ss_i.client_port = port;
    ss_i.trieRoot = createTrieNode();

    char cwd[256];
    if (getcwd(cwd, sizeof(cwd)) != NULL)
    {
        snprintf(ss_i.cwd, sizeof(cwd), "%s", cwd);
    }

    int server_com, cli_comm, nm_comm, nm_com;
    struct sockaddr_in com_address, client_address;
    socklen_t client_address_len = sizeof(client_address);
    server_com = socket(AF_INET, SOCK_STREAM, 0);
    if (server_com == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Configure the server address
    com_address.sin_family = AF_INET;
    com_address.sin_port = htons(port);
    com_address.sin_addr.s_addr = inet_addr(ip);

    if (bind(server_com, (struct sockaddr *)&com_address, sizeof(com_address)) == -1)
    {
        perror("Can't bind socket");
        close(server_com);
        exit(EXIT_FAILURE);
    }

    // Listen for incoming connections
    if (listen(server_com, 5) == -1) // maximum length to which the queue of pending connections for sockfd may grow.
    {
        perror("Error listening");
        close(server_com);
        exit(EXIT_FAILURE);
    }

    struct sockaddr_in nm_address, rec_address;
    socklen_t rec_address_len = sizeof(rec_address);
    nm_com = socket(AF_INET, SOCK_STREAM, 0);
    if (nm_com == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Configure the server address
    nm_address.sin_family = AF_INET;
    // printf("*%d*", ss_i.nm_port);
    nm_address.sin_port = htons(ss_i.nm_port);
    nm_address.sin_addr.s_addr = inet_addr(ip);

    if (bind(nm_com, (struct sockaddr *)&nm_address, sizeof(nm_address)) == -1)
    {
        perror("*Can't bind socket");
        close(nm_com);
        exit(EXIT_FAILURE);
    }

    // Listen for incoming connections
    if (listen(nm_com, 5) == -1) // maximum length to which the queue of pending connections for sockfd may grow.
    {
        perror("Error listening");
        close(server_com);
        exit(EXIT_FAILURE);
    }
    // printf("Server listening on port 12345...\n");
    //  Accept incoming connections

    // return 0;
    //  INPUT ACCESSIBLE PATHS
    // printf("Enter Accessible Paths for this Storage Server: \n");
    // char *s = (char *)malloc(sizeof(char) * 256);
    // for (int i = 0; i < ss_i.num_paths; i++)
    // {
    //     scanf("%s", s);
    //     if (s[0] == '.' && s[1] == '/')
    //     {
    //         char s2[256];
    //         int i = 2;
    //         for (; i < strlen(s) && s[i] != '\n' && s[i] != '\0'; i++)
    //             s2[i - 2] = s[i];
    //         s2[i - 2] = '\0';
    //         snprintf(ss_i.accessible_paths[i], sizeof(ss_i.accessible_paths[i]), "%s", s2);
    //     }
    //     else if (s[0] == '/' && s[1] == '\0')
    //     {
    //         snprintf(ss_i.accessible_paths[i], sizeof(ss_i.accessible_paths[i]), "%s", cwd);
    //     }
    //     else if (s[0] == '/')
    //     {
    //         char s2[256];
    //         int i = 1;
    //         for (; i < strlen(s) && s[i] != '\n' && s[i] != '\0'; i++)
    //             s2[i - 2] = s[i];
    //         s2[i - 2] = '\0';
    //         snprintf(ss_i.accessible_paths[i], sizeof(ss_i.accessible_paths[i]), "%s", s2);
    //     }
    //     else
    //         snprintf(ss_i.accessible_paths[i], sizeof(ss_i.accessible_paths[i]), "%s", s);
    //     // insertPath(ss_i.trieRoot,s);
    // }
    // printf("%d ",ss_i.trieRoot->children[0]);

    // snprintf(ss_i.accessible_paths[1], sizeof(ss_i.accessible_paths[1]), "ss2/stuff");

    // printf("%s %d\n", ss_i.ip_address, ss_i.num_paths);
    // Send SS_i details to the Naming Server
    int sent_data = send(clientsock, &ss_i, sizeof(ss_i), 0);
    if (sent_data == -1)
    {
        perror("Error sending data");
        close(clientsock);
        exit(EXIT_FAILURE);
    }

    registered_servers[num_registered_servers] = ss_i;
    num_registered_servers++;
    //}

    while (1)
    {
        // printf("HIII");
        struct DataSent data;
        nm_comm = accept(nm_com, (struct sockaddr *)&rec_address, &rec_address_len);
        if (nm_comm == -1)
        {
            perror("Can't accept connection");
            // close(cli_comm);
            // close(server_com);
            exit(EXIT_FAILURE);
        }
        int received_data = recv(nm_comm, &data, sizeof(data), 0);
        if (received_data == -1)
        {
            perror("Error receiving data");
            close(nm_comm);
            exit(EXIT_FAILURE);
        }
        printf("%d %d %d %s\n", data.file_or_dir, data.request, data.ss_no, data.path);

        if (data.request == 1 || data.request == 2)
        {
            if (data.file_or_dir == 1)
            {
                if (data.request == 1)
                {
                    FILE *file = fopen(data.path, "w");
                    if (file == NULL)
                    {
                        char buffer[256] = CANT_FILE_015;
                        // printf("Here??");
                        int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
                        if (sent_data == -1)
                        {
                            perror("Error sending data");
                            close(nm_comm);
                            exit(EXIT_FAILURE);
                        }
                    }
                    else
                    {
                        // char *buffer = (char *)malloc(sizeof(char) * 6);
                        // strcpy(buffer, "ACK");
                        char buffer[] = "ACK";
                        // printf("worked na");
                        int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
                        if (sent_data == -1)
                        {
                            perror("Error sending data");
                            close(nm_comm);
                            exit(EXIT_FAILURE);
                        }
                    }
                    // printf("%s ",buffer);
                    fclose(file);
                }
                else if (data.request == 2)
                {
                    // printf("%s ",data.path);
                    // return 0;

                    if (remove(data.path) == 0)
                    {
                        // printf("worked??");
                        char buffer[] = "ACK";
                        int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
                        if (sent_data == -1)
                        {
                            perror("Error sending data");
                            close(nm_comm);
                            exit(EXIT_FAILURE);
                        }
                    }
                    else
                    {
                        // char *buffer = (char *)malloc(sizeof(char) * 6);
                        // strcpy(buffer, "FAIL");
                        char buffer[256] = CANT_DEL_FILE_016;
                        int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
                        if (sent_data == -1)
                        {
                            perror("Error sending data");
                            close(nm_comm);
                            exit(EXIT_FAILURE);
                        }
                    }
                }
            }
            else if (data.file_or_dir == 2)
            {

                // printf("HIII %d",MAX_PATHS);
                // struct StorageServerInfo ss_i = registered_servers[data.ss_no];
                // printf("%d ",ss_i.num_paths);
                if (ss_i.num_paths < MAX_PATHS)
                {
                    if (data.request == 1)
                    {
                        int dir = mkdir(data.path, 0777); // Create the directory with read, write, and execute permissions
                        // printf("DONe");
                        //  printf("%d ",dir);
                        //  return 0;
                        if (dir != -1)
                        {
                            // perror("fail");
                            // return 0;
                            char buffer[] = "ACK";
                            int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
                            if (sent_data == -1)
                            {
                                perror("Error sending data");
                                close(nm_comm);
                                exit(EXIT_FAILURE);
                            }
                        }
                        else
                        {
                            char buffer[256] = CANT_DIR_017;
                            int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
                            if (sent_data == -1)
                            {
                                perror("Error sending data");
                                close(nm_comm);
                                exit(EXIT_FAILURE);
                            }
                        }
                        // snprintf(ss_i.accessible_paths[ss_i.num_paths], sizeof(ss_i.accessible_paths[ss_i.num_paths]), "%s", data.path);
                        // ss_i.num_paths++;
                    }

                    else if (data.request == 2)
                    {
                        int x = delete_directory(data.path);
                        if (x == -1)
                        {
                            char buffer[256] = CANT_DEL_DIR_018;
                            int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
                            if (sent_data == -1)
                            {
                                perror("Error sending data");
                                close(nm_comm);
                                exit(EXIT_FAILURE);
                            }
                        }
                        else
                        {
                            char buffer[] = "ACK";
                            int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
                            if (sent_data == -1)
                            {
                                perror("Error sending data");
                                close(nm_comm);
                                exit(EXIT_FAILURE);
                            }
                        }

                        // for (int j = 0; j < ss_i.num_paths; j++)
                        // {
                        //     if (strcmp(data.path, ss_i.accessible_paths[j]) == 0)
                        //     {
                        //         strcpy(ss_i.accessible_paths[j], ss_i.accessible_paths[ss_i.num_paths - 1]);
                        //         break;
                        //     }
                        // }
                        // ss_i.num_paths--;

                        // delete from list of dirs
                    }

                    // for (int j = 0; j < ss_i.num_paths; j++)
                    //     printf("%s ", ss_i.accessible_paths[j]);

                    // char *buffer = (char *)malloc(sizeof(char) * 6);
                    // strcpy(buffer, "ACK");
                    // sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
                    // if (sent_data == -1)
                    // {
                    //     perror("Error sending data");
                    //     close(nm_comm);
                    //     exit(EXIT_FAILURE);
                    // }
                }
                else
                {
                    // printf("%d %d",ss_i.num_paths,MAX_PATHS);
                    char buffer[] = "FAIL";
                    int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
                    if (sent_data == -1)
                    {
                        perror("Error sending data");
                        close(nm_comm);
                        exit(EXIT_FAILURE);
                    }
                }

                int sent_data = send(nm_comm, &ss_i, sizeof(ss_i), 0);
                if (sent_data == -1)
                {
                    perror("Error sending data");
                    close(nm_comm);
                    // close(cli_comm);
                    exit(EXIT_FAILURE);
                }
            }
        }
        else if (data.request == 3)
        {
            //("%d %s", data.ss_no2, data.dest);
            continue;
            // if (data.file_or_dir == 1)
            // {
            //     FILE *source_file = fopen(data.path, "rb");
            //     if (source_file == NULL)
            //     {
            //         printf("Failed to open source file: %s\n", source_path);
            //         char buffer[] = "FAIL";
            //         int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
            //         if (sent_data == -1)
            //         {
            //             perror("Error sending data");
            //             close(nm_comm);
            //             exit(EXIT_FAILURE);
            //         }
            //         continue;
            //     }

            //     FILE *destination_file = fopen(data.dest, "wb");
            //     if (destination_file == NULL)
            //     {
            //         printf("Failed to create or open destination file: %s\n", destination_path);
            //         fclose(source_file);
            //         char buffer[] = "FAIL";
            //         int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
            //         if (sent_data == -1)
            //         {
            //             perror("Error sending data");
            //             close(nm_comm);
            //             exit(EXIT_FAILURE);
            //         }
            //         continue;
            //     }

            //     char buffer2[4096];
            //     size_t bytes_read;

            //     while ((bytes_read = fread(buffer2, 1, sizeof(buffer2), source_file) > 0))
            //     {
            //         size_t bytes_written = fwrite(buffer2, 1, bytes_read, destination_file);

            //         if (bytes_written != bytes_read)
            //         {
            //             printf("Failed to write to destination file.\n");
            //             fclose(source_file);
            //             fclose(destination_file);
            //             char buffer[] = "FAIL";
            //             int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
            //             if (sent_data == -1)
            //             {
            //                 perror("Error sending data");
            //                 close(nm_comm);
            //                 exit(EXIT_FAILURE);
            //             }
            //             continue;
            //             return 1;
            //         }
            //     }

            //     fclose(source_file);
            //     fclose(destination_file);
            //     char buffer[] = "ACK";
            //     int sent_data = send(nm_comm, buffer, sizeof(buffer), 0);
            //     if (sent_data == -1)
            //     {
            //         perror("Error sending data");
            //         close(nm_comm);
            //         exit(EXIT_FAILURE);
            //     }
            //     continue;
            // }
            // if (data.file_or_dir == 2)
            // {
            // }
        }
        else if (data.request == 4)
        {
            cli_comm = accept(server_com, (struct sockaddr *)&client_address, &client_address_len);
            if (cli_comm == -1)
            {
                perror("Can't accept connection");
                // close(cli_comm);
                // close(server_com);
                exit(EXIT_FAILURE);
            }

            char buffer[1024];
            int c = 0;
            // while (c == 0)
            // {
            FILE *file = fopen(data.path, "r"); // Open the file for reading

            if (file == NULL)
            {
                perror("Failed to open the file");
            }
            if (fgets(buffer, sizeof(buffer), file) == NULL)
            {
            }
            else
            {
                //printf("%s",buffer);
                send(cli_comm, buffer, sizeof(buffer), 0);
                while (fgets(buffer, sizeof(buffer), file) != NULL)
                {
                    //printf("%s",buffer);
                    send(cli_comm, buffer, sizeof(buffer), 0);

                    // if (strcmp(buffer, "Yes") != 0)
                    // {
                    //     c = 1;  //Stop, don't send DONE packet
                    //     break;
                    // }
                }
            }
            // if (c == 0) //Reached EOF, send done packet
            // {
            snprintf(buffer, sizeof(buffer), "DONE");
            send(cli_comm, buffer, sizeof(buffer), 0);
            recv(cli_comm, buffer, sizeof(buffer), 0);
            // }

            fclose(file);
            //}
        }
        else if (data.request == 5)
        {

            cli_comm = accept(server_com, (struct sockaddr *)&client_address, &client_address_len);
            if (cli_comm == -1)
            {
                perror("Can't accept connection");
                // close(cli_comm);
                // close(server_com);
                exit(EXIT_FAILURE);
            }

            char buffer3[1024];
            int c = 0;
            // while (c == 0)
            // {
            FILE *file = fopen(data.path, "w"); // Open the file for reading

            if (file == NULL)
            {
                perror("Failed to open the file");
            }

            while (c == 0)
            {
                int r = recv(cli_comm, buffer3, sizeof(buffer3), 0);
                buffer3[r] = '\0';
                // write
                // printf("*%s %s*", buffer3, data.path);
                // return 0;
                fwrite(buffer3, 1, strlen(buffer3), file);
                // fprintf(file, "%s", buffer);
                recv(cli_comm, buffer3, sizeof(buffer3), 0);
                if (strcmp(buffer3, "Yes\n") != 0)
                {
                    c = 1; // Stop, don't send DONE packet
                    break;
                }
            }
            // if (c == 0) //Reached EOF, send done packet
            // {
            //     snprintf(buffer, sizeof(buffer), "DONE");
            //     send(cli_comm, buffer, sizeof(buffer), 0);
            // }

            fclose(file);
        }
        else if (data.request == 6)
        {
            cli_comm = accept(server_com, (struct sockaddr *)&client_address, &client_address_len);
            if (cli_comm == -1)
            {
                perror("Can't accept connection");
                // close(cli_comm);
                // close(server_com);
                exit(EXIT_FAILURE);
            }

            // printf("Open");
            int c;
            int received_data = recv(cli_comm, &c, sizeof(c), 0);
            char buffer2[10];
            char buffer[1024];
            // char* fmessage="Failed";
            if (c == 1)
            {
                struct stat file_stat;

                if (stat(data.path, &file_stat) == 0)
                {
                    // Extract file size and permissions
                    size_t file_size = file_stat.st_size;
                    mode_t file_permissions = file_stat.st_mode;
                    sprintf(buffer, "%zu", file_size);
                    // printf("%s",buffer);
                    // return 0;
                    //  Provide the file information to the client in a suitable response format.
                    //  printf("File Size: %zu bytes\n", file_size);
                    //  printf("File Permissions: %o\n", file_permissions);
                }
                else
                {
                    snprintf(buffer, sizeof(buffer), UNABLE_INFO_021);
                }
            }
            else if (c == 2)
            {
                struct stat file_stat;

                if (stat(data.path, &file_stat) == 0)
                {
                    // Extract file size and permissions
                    size_t file_size = file_stat.st_size;
                    mode_t file_permissions = file_stat.st_mode;
                    sprintf(buffer, "%o", file_permissions);
                    // Provide the file information to the client in a suitable response format.
                    // printf("File Size: %zu bytes\n", file_size);
                    // printf("File Permissions: %o\n", file_permissions);
                }
                else
                {
                    snprintf(buffer, sizeof(buffer), UNABLE_INFO_021);
                }
            }
            else if (c == 3)
            {
                struct stat file_stat;

                if (stat(data.path, &file_stat) == 0)
                {
                    // Extract file size and permissions
                    size_t file_size = file_stat.st_size;
                    mode_t file_permissions = file_stat.st_mode;
                    sprintf(buffer, "%zu", file_size);
                    sprintf(buffer2, "%o", file_permissions);

                    // Provide the file information to the client in a suitable response format.
                    // printf("File Size: %zu bytes\n", file_size);
                    // printf("File Permissions: %o\n", file_permissions);
                }
                else
                {
                    snprintf(buffer, sizeof(buffer), UNABLE_INFO_021);
                }
            }
            else if (c == 4)
            {
                struct stat file_stat;

                if (stat(data.path, &file_stat) == 0)
                {
                    snprintf(buffer, sizeof(buffer),
                             "File Information:\n"
                             "  Permissions: %o\n"
                             "  Inode: %lu\n"
                             "  Device ID: %lu\n"
                             "  User ID: %u\n"
                             "  Group ID: %u\n"
                             "  Last Access Time: %lu\n"
                             "  Last Status Change Time: %lu\n"
                             "  Last Modification Time: %lu\n"
                             "  Number of Links: %lu\n"
                             "  File Size: %lld bytes",
                             file_stat.st_mode, (unsigned long)file_stat.st_ino,
                             (unsigned long)file_stat.st_dev, (unsigned int)file_stat.st_uid,
                             (unsigned int)file_stat.st_gid, (unsigned long)file_stat.st_atime,
                             (unsigned long)file_stat.st_ctime, (unsigned long)file_stat.st_mtime,
                             (unsigned long)file_stat.st_nlink, (long long)file_stat.st_size);
                }
                else
                {
                    snprintf(buffer, sizeof(buffer), UNABLE_INFO_021);
                }
            }
            else
            {
                snprintf(buffer, sizeof(buffer), INFO_INVALID_020);
            }
            send(cli_comm, buffer, sizeof(buffer), 0);
            if (c == 3)
                send(cli_comm, buffer2, sizeof(buffer2), 0);

            close(cli_comm);

            // printf("Connected to Client!\n");
        }
    }
    close(server_com);
    // close(cli_comm);
    close(nm_comm);
    return 0;
}