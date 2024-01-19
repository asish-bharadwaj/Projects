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
#include <semaphore.h>
#include <errno.h>

#include "headers.h"

// #include "tries.c"

// Data structure to store information about storage servers
#define MAX_PATHS 100
#define NM_PORT 11111
#define NM_ADDR "127.0.0.1"
#define CLIENT_PORT 54321

#define max_servers 100
int num_registered_servers = 0;
int num_registered_clients = 0;
int serversock = 0;
int server_status[max_servers], redundant_servers_status[3];

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

struct comStruct
{
    int port;
    char ip[16];
};

struct port_ind
{
    int port, index, ss_socket;
};

struct StorageServerInfo registered_servers[max_servers];
struct StorageServerInfo redundant_servers[3];
int redundant_servers_count = 0;

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
    struct TrieNode *children[256];
};

struct Node
{
    int ss_no;
    char path[1024];
    struct Node *next;
};

struct Node *createNode(int data, char *path)
{
    struct Node *newNode = (struct Node *)malloc(sizeof(struct Node));
    newNode->ss_no = data;
    snprintf(newNode->path, sizeof(newNode->path), "%s", path);
    newNode->next = NULL;
    return newNode;
}

mode_t get_permissions(struct stat fileInfo)
{
    mode_t mode = fileInfo.st_mode, usr, grp, oth;
    usr = ((mode & S_IRUSR) ? S_IRUSR : 0) | ((mode & S_IWUSR) ? S_IWUSR : 0) | ((mode & S_IXUSR) ? S_IXUSR : 0);
    grp = ((mode & S_IRGRP) ? S_IRGRP : 0) | ((mode & S_IWGRP) ? S_IWGRP : 0) | ((mode & S_IXGRP) ? S_IXGRP : 0);
    oth = ((mode & S_IROTH) ? S_IROTH : 0) | ((mode & S_IWOTH) ? S_IWOTH : 0) | ((mode & S_IXOTH) ? S_IXOTH : 0);

    return usr + grp + oth;
}

void LRU_Path_delete(struct Node **head, char *path, int ss_no)
{
    struct Node *current = *head;
    struct Node *prev = NULL;

    // Search for the node to delete
    while (current != NULL)
    {
        if (current->ss_no == ss_no && strcmp(current->path, path) == 0)
        {
            break;
        }
        prev = current;
        current = current->next;
    }

    // If the node was not found
    if (current == NULL)
    {
        // printf("Node with value %d not found.\n", value);
        return;
    }

    // If the node is the head
    if (prev == NULL)
    {
        *head = current->next;
    }
    else
    {
        // Update the next pointer of the previous node
        prev->next = current->next;
    }
    // Free the memory of the deleted node
    free(current);
}

// Function to delete the rightmost node from the linked list
void LRU_Delete(struct Node **head)
{
    if (*head == NULL || (*head)->next == NULL)
    {
        return;
    }
    int count = 0;
    struct Node *secondLast = *head;
    while (secondLast->next->next != NULL)
    {
        count++;
        secondLast = secondLast->next;
    }
    if (count == 12)
    {
        free(secondLast->next);
        secondLast->next = NULL;
    }
    return;
}
// Function to insert a new node at the left (head) of the linked list
void LRU_Insert(struct Node **head, int data, char *path)
{
    struct Node *newNode = createNode(data, path);
    newNode->next = *head;
    *head = newNode;
    LRU_Delete(head);
    return;
}

// Function to search for a value in the linked list, move it to the head if found
int LRU_Search(struct Node **head, char *path)
{
    if (*head == NULL)
    {
        return -1;
    }

    struct Node *current = *head;
    struct Node *prev = NULL;

    // Search for the key in the list
    while (current != NULL && strcmp(current->path, path) != 0)
    {
        prev = current;
        current = current->next;
    }

    if (current == NULL)
    {
        return -1;
    }

    // Move the found node to the head
    if (prev != NULL)
    {
        prev->next = current->next;
        current->next = *head;
        *head = current;
    }
    return current->ss_no;
}

typedef struct hash_table_entry
{
    char *key;
    sem_t sem;
    struct hash_table_entry *next;
} hash_table_entry;
typedef hash_table_entry *HTE;

HTE HT[1024];
int hash_function(char *key)
{
    unsigned int hash = 0;
    for (int i = 0; i < strlen(key); i++)
    {
        hash = hash * 31 + key[i];
    }
    return hash % 1024;
}

void hash_table_insert(char *key)
{
    int index = hash_function(key);
    HTE entry = (HTE)malloc(sizeof(hash_table_entry));
    entry->key = (char *)malloc(sizeof(char) * 100);
    strcpy(entry->key, key);
    sem_init(&entry->sem, 0, 1);
    entry->next = HT[index];
    HT[index] = entry;
}

HTE hash_table_lookup(char *key)
{
    int index = hash_function(key);
    hash_table_entry *entry = HT[index];
    while (entry != NULL)
    {
        if (strcmp(entry->key, key) == 0)
        {
            return entry;
        }
        entry = entry->next;
    }
    return NULL;
}

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
    for (int i = 0; i < 256; i++)
    {
        node->children[i] = 0;
    }
    node->isEndOfPath = 0;
    return node;
}

void insertPath(struct TrieNode *root, const char *path)
{
    struct TrieNode *node = root;
    for (int i = 0; path[i] != '\0' && path[i] != '\n'; i++)
    {
        int index = (int)path[i];
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
    for (int i = 0; i < 256; i++)
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
        int index = (int)(path[i]);
        if (node->children[index] == 0)
        {
            return; // Path not found
        }

        node = node->children[index];
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
}

int searchPath(struct TrieNode *root, const char *path)
{
    // printf("hi *%s*",path);
    struct TrieNode *node = (struct TrieNode *)malloc(sizeof(struct TrieNode));
    node = root;
    for (int i = 0; path[i] != '\0' && path[i] != '\n'; i++)
    {
        int index = (int)(path[i]);
        // printf("%d ",index);
        // printf("%c ",path[i]);
        if (node->children[index] == 0)
        {
            return 0; // Path not found
        }

        node = node->children[index];
    }
    //    printf("%d ",node->isEndOfPath);
    return node->isEndOfPath;
}

int findStorageServerForPath(const char *path, struct StorageServerInfo *registered_servers, int num_servers)
{
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

int copyDirectory(const char *source_dir, const char *destination_dir, int ss_no, int ss_no2)
{

    struct stat st;
    char dest_dir2[1024];
    strcat(dest_dir2, registered_servers[ss_no2].cwd);
    strcat(dest_dir2, "/");
    // strcat(dest_dir2, source_dir);
    // strcat(dest_dir2, "/");
    strcat(dest_dir2, destination_dir);
    if (stat(dest_dir2, &st) != 0)
    {
        // If the destination directory does not exist, create it
        mkdir(dest_dir2, 0777);
        int s = findStorageServerForPath(destination_dir, registered_servers, num_registered_servers);
        if (s != -1)
            insertPath(registered_servers[ss_no2].trieRoot, destination_dir);
    }

    char source2[1024];
    strcat(source2, registered_servers[ss_no].cwd);
    strcat(source2, "/");
    strcat(source2, source_dir);

    DIR *dir = opendir(source2);
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

            char source_path2[PATH_MAX];
            char destination_path2[PATH_MAX];

            snprintf(source_path2, sizeof(source_path2), "%s/%s", source2, entry->d_name);
            snprintf(destination_path2, sizeof(destination_path2), "%s/%s", dest_dir2, entry->d_name);

            // printf("#%s %s %s %s\n", source_path, destination_path, source_path2, destination_path2);
            int s = findStorageServerForPath(source_path, registered_servers, num_registered_servers);
            if (s != -1)
            {
                // printf("%s %s ",source_path2,destination_path2);
                FILE *source_file = fopen(source_path2, "rb");
                FILE *destination_file = fopen(destination_path2, "wb");

                if (source_file == NULL || destination_file == NULL)
                {
                    printf("Failed to copy file: %s\n", entry->d_name);
                    fclose(source_file);
                    fclose(destination_file);
                    return 0;
                    continue;
                }

                char ch;
                while ((ch = fgetc(source_file)) != EOF)
                    fputc(ch, destination_file);

                fclose(source_file);
                fclose(destination_file);
                insertPath(registered_servers[ss_no2].trieRoot, destination_path);
            }
        }
        else if (entry->d_type == DT_DIR && strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0)
        {
            // If the entry is a subdirectory, recursively copy it
            char sub_source_dir[PATH_MAX];
            char sub_destination_dir[PATH_MAX];

            snprintf(sub_source_dir, sizeof(sub_source_dir), "%s/%s", source_dir, entry->d_name);
            snprintf(sub_destination_dir, sizeof(sub_destination_dir), "%s/%s", destination_dir, entry->d_name);

            int x = copyDirectory(sub_source_dir, sub_destination_dir, ss_no, ss_no2);
        }
    }

    closedir(dir);
    return 1;
}

int cpy_dir2(char *path2, char *path, struct stat fileInfo, int k)
{
    char dest[1024];
    DIR *dir = opendir(path2);
    struct dirent *entry;
    if (dir == NULL)
    {
        perror("Error in opening directory for copying, when registered_servers == 3");
        exit(1);
    }
    memset(dest, 1024, '\0');
    //strcpy(dest, redundant_servers[k].cwd);
   // strcat(dest, "/");
    strcat(dest, path);

    // if (mkdir(dest, 0777) == -1)
    // {
    //     perror(REDUNDANT_DIR_023);
    // }
    // if (chmod(dest, get_permissions(fileInfo)) == -1)
    // {
    //     perror(REDUNDANT_PERMISSION_024);
    // }
    while ((entry = readdir(dir)) != NULL)
    {
        if (entry->d_type == DT_REG)
        {
            char source[1024];
            strcpy(source, path2);
            strcat(source, "/");
            strcat(source, entry->d_name);
            FILE *source_file = fopen(source, "r");
            // file
            memset(dest, 1024, '\0');
          //  strcpy(dest, redundant_servers[k].cwd);
          //  strcat(dest, "/");
            strcat(dest, entry->d_name);

            FILE *destination_file = fopen(dest, "w");
            if (destination_file == NULL)
            {
                perror("*Error opening file for writing in copying, when registered_servers == 3");
            }
            char ch;
            while ((ch = fgetc(source_file)) != EOF)
                fputc(ch, destination_file);
            fclose(source_file);
            fclose(destination_file);

          //  insertPath(redundant_servers[k].trieRoot, dest);
        }
        else if (entry->d_type == DT_DIR && strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0)
        {
            char subdir[1024];
            strcpy(subdir, path2);
            strcat(subdir, "/");
            strcat(subdir, entry->d_name);

            char dest_subdir[1024];
            strcpy(dest_subdir, path);
            strcat(dest_subdir, "/");
            strcat(dest_subdir, entry->d_name);

            struct stat f;
            stat(subdir, &f);
            //cpy_dir2(subdir, dest_subdir, f, k);
         //   insertPath(redundant_servers[k].trieRoot, dest_subdir);
        }
    }
}

void *server_func(void *arg)
{
    struct port_ind received_ss_info = (*(struct port_ind *)arg);

    struct timeval timeout;
    timeout.tv_sec = 5;
    timeout.tv_usec = 0;

    int timeout_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (timeout_socket == -1)
    {
        perror("Error creating timeout_socket");
        exit(EXIT_FAILURE);
    }

    struct sockaddr_in nfs;
    nfs.sin_family = AF_INET;
    nfs.sin_port = htons(received_ss_info.port);
    // printf("%d\n", received_ss_info.port);
    nfs.sin_addr.s_addr = inet_addr("127.0.0.1");
    int nfsSize = sizeof(nfs);

    if (bind(timeout_socket, (struct sockaddr *)&nfs, sizeof(nfs)) == -1)
    {
        perror("Can't bind timeout_socket to nfs");
        close(timeout_socket);
        exit(EXIT_FAILURE);
    }

    if (listen(timeout_socket, 3) == -1)
    {
        perror("Error listening");
        close(timeout_socket);
        exit(EXIT_FAILURE);
    }

    send(received_ss_info.ss_socket, "ACK", 3, 0);

    char msg[1024];
    // printf("ready to accept\n");
    int ss_socket = accept(timeout_socket, (struct sockaddr *)&nfs, &nfsSize);
    if (ss_socket == -1)
    {
        perror("Cannot accept ss_socket to timeout_socket");
        close(timeout_socket);
        exit(EXIT_FAILURE);
    }
    if (setsockopt(timeout_socket, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout)) == -1)
    {
        perror("error in setting time-limit to socket");
        exit(EXIT_FAILURE);
    }

    while (1)
    {
        memset(msg, 1024, '\0');
        if (recv(ss_socket, &msg, sizeof(msg), 0) == -1)
        {
            if (errno != EAGAIN)
            {
                perror("Error in recv msg to timeout_socket");
                close(timeout_socket);
                exit(EXIT_FAILURE);
            }
            else
            {
                // ss disconnected
                server_status[received_ss_info.index] = 0;
            }
        }
        else
        {
            server_status[received_ss_info.index] = 1;
            if (strcmp("ALIVE", msg) != 0)
            {
                server_status[received_ss_info.index] = 0;
                printf("Error in msg recd. Expected - 'ALIVE'. Received - %s\n", msg);
            }
        }
    }
}

void *client_func(void *arg)
{
    int client_socket = (*(int *)arg);

    int input = 0;
    char command[1024];
    char opt[2];
    char path[1024];
    char dest[1024];
    int pathind, cmdind, destind, i, option;
    struct DataSent data;
    struct Node *LRU = NULL;
    while (1)
    {
        char req[1024];
        command[0] = '\0';
        path[0] = '\0';
        dest[0] = '0';

        pathind = 0, cmdind = 0, destind = 0, i = 0;
        int rec_data = recv(client_socket, req, sizeof(req), 0);
        req[rec_data] = '\0';
        // printf("*%s*",req);
        if (strcmp(req, "No") == 0)
        {
            close(client_socket);
            return 0;
        }
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
            if (req[i] == '.' && req[i + 1] == '/')
                i += 2;
            for (; req[i] != ' ' && req[i] != '\0' && req[i] != '\n'; i++)
            {
                path[pathind++] = req[i];
            }
            path[pathind] = '\0';

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
                // printf("hi");
                printf("Client Request Fail: %s IP: %s port: %d\n", INVALID_CMD_001, NM_ADDR, NM_PORT);
                char buffer[] = INVALID_CMD_001;
                int sent_data = send(client_socket, buffer, strlen(buffer) + 1, 0);
                if (sent_data == -1)
                {
                    perror("send");
                    // Handle the error, e.g., close the socket and exit
                    close(client_socket);
                    exit(EXIT_FAILURE);
                }
                continue;
            }
            if (option != 1 && option != 2)
            {
                printf("%s Fail: %s IP: %s port: %d\n", command, INVALID_OPTION_019, NM_ADDR, NM_PORT);
                char buffer[] = INVALID_OPTION_019;
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }

            struct stat fileStat;
            if (stat(path, &fileStat) == 0)
            {
                if (S_ISREG(fileStat.st_mode))
                {
                    if (option == 2)
                    {
                        printf("%s Fail: %s IP: %s port: %d\n", command, FILE_AS_DIR_006, NM_ADDR, NM_PORT);
                        char buffer[] = FILE_AS_DIR_006;
                        int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                        continue;
                    }
                }
                else if (S_ISDIR(fileStat.st_mode))
                {
                    if (option == 1)
                    {
                        printf("%s Fail: %s IP: %s port: %d\n", command, DIR_AS_FILE_005, NM_ADDR, NM_PORT);
                        char buffer[] = DIR_AS_FILE_005;
                        int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                        continue;
                    }
                }
                else
                {
                    printf("%s Fail: %s IP: %s port: %d\n", command, INVALID_PATH_007, NM_ADDR, NM_PORT);
                    char buffer[] = INVALID_PATH_007;
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    continue;
                }
            }
        }
        else
        {
            // printf("hi2");
            printf("Client Request Fail: %s IP: %s port: %d\n", INVALID_CMD_001, NM_ADDR, NM_PORT);
            char buffer[] = INVALID_CMD_001;
            int sent_data = send(client_socket, buffer, strlen(buffer) + 1, 0);
            continue;
        }

        printf("Client Request: %s Path: %s IP: %s Port: %d\n", command, path, NM_ADDR, NM_PORT);
        // printf("Done cli");

        //  printf("%d", input);
        //  return 0;
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
            int ss_no, ss_no2;
            if (input == 1)
            {
                ss_no = LRU_Search(&LRU, dir);
                if (ss_no == -1)
                {
                    ss_no = findStorageServerForPath(dir, registered_servers, num_registered_servers);
                    if (ss_no != -1)
                        LRU_Insert(&LRU, ss_no, dir);
                }
                ss_no2 = findStorageServerForPath(path, registered_servers, num_registered_servers);
            }
            if (input == 2)
            {
                ss_no = LRU_Search(&LRU, path);
                if (ss_no == -1)
                {
                    ss_no = findStorageServerForPath(path, registered_servers, num_registered_servers);
                    if (ss_no != -1)
                        LRU_Insert(&LRU, ss_no, path);
                }
            }
            if (ss_no == -1)
            {
                printf("CREATE Fail: %s IP: %s Port: %d\n", PATH_NOT_FOUND_002, NM_ADDR, NM_PORT);
                char buffer[] = PATH_NOT_FOUND_002;
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }
            if (ss_no2 != -1 && input == 1)
            {
                if (option == 1)
                {
                    printf("CREATE Fail: %s IP: %s Port: %d\n", FILE_EXISTS_012, NM_ADDR, NM_PORT);
                    char buffer[] = FILE_EXISTS_012;
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                }
                else if (option == 2)
                {
                    printf("CREATE Fail: %s IP: %s Port: %d\n", DIR_EXISTS_013, NM_ADDR, NM_PORT);
                    char buffer[] = DIR_EXISTS_013;
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                }
                continue;
            }

            // int ss_no2 = searchPath(registered_servers[0].trieRoot, dir);
            // printf("#%d ", ss_no);
            if (server_status[ss_no] == 0)
            {
                if (input == 1)
                    printf("CREATE Fail: %s IP: %s PORT: %d\n", SS_DOWN_025, NM_ADDR, NM_PORT);
                if (input == 2)
                    printf("DELETE Fail: %s IP: %s PORT: %d\n", SS_DOWN_025, NM_ADDR, NM_PORT);
                char buffer[] = SS_DOWN_025;
                send(client_socket, &buffer, sizeof(buffer), 0);
                continue;
            }
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
                // exit(1);
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
                // exit(1);
            }

            int sent_data = send(ss_sock, &data, sizeof(data), 0);
            if (sent_data == -1)
            {
                perror("Can't send data");
                close(serversock);
                close(ss_sock);
                // exit(EXIT_FAILURE);
            }
            if (input == 1)
            {
                // printf("hi");
                insertPath(registered_servers[ss_no].trieRoot, path);
                if (hash_table_lookup(path) == NULL)
                {
                    hash_table_insert(path);
                }
                // return 0;
            }
            if (input == 2)
            {
                removePath(registered_servers[ss_no].trieRoot, path);
                LRU_Path_delete(&LRU, path, ss_no);
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
            char buffer[256];
            int received_data = recv(ss_sock, buffer, sizeof(buffer), 0);
            if (received_data == -1)
            {
                perror("Can't send data");
                close(serversock);
                close(ss_sock);
                exit(EXIT_FAILURE);
            }

            close(ss_sock);
            // printf("$%s ",buffer);
            // return 0;
            if (strcmp(buffer, "ACK") == 0)
            {
                printf("ACK from Storage Server %d Ip: %s port: %d\n", ss_no + 1, registered_servers[ss_no].ip_address, registered_servers[ss_no].nm_port);
                if (input == 1)
                    printf("\033[0;32mCREATE SUCCESS IP: %s Port: %d\n\033[0m", NM_ADDR, NM_PORT);
                if (input == 2)
                    printf("\033[0;32mDELETE SUCCESS IP: %s Port: %d\033[0m\n", NM_ADDR, NM_PORT);
                sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }

            else
            {
                printf("%s from Storage Server %d IP: %s PORT: %d\n", buffer, ss_no + 1, registered_servers[ss_no].ip_address, registered_servers[ss_no].nm_port);
                if (input == 1)
                    printf("CREATE FAIL\n"); // ERROR FROM SS
                if (input == 2)
                    printf("DELETE FAIL\n"); // ERROR FROM SS
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
            struct stat fileStat;
            if (stat(dest, &fileStat) == 0)
            {
                // Check if it's a regular file
                if (S_ISREG(fileStat.st_mode))
                {
                    printf("COPY Fail: %s IP: %s port: %d\n", COPY_FILE_DIR_008, NM_ADDR, NM_PORT);
                    char buffer[] = COPY_FILE_DIR_008;
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    continue;
                }
                // Check if it's a directory
                else if (S_ISDIR(fileStat.st_mode))
                {
                }
                else
                {
                    printf("COPY Fail: %s IP: %s port: %d\n", COPY_FILE_DIR_008, NM_ADDR, NM_PORT);
                    char buffer[] = COPY_FILE_DIR_008;
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    continue;
                }
            }
            // printf("%s %s\n %s %s", dir, file,dir2,file2);
            // return 0;

            // int ss_no = find_ss_for_path(dir, registered_servers, num_registered_servers);

            int ss_no;
            ss_no = LRU_Search(&LRU, path);
            if (ss_no == -1)
            {
                ss_no = findStorageServerForPath(path, registered_servers, num_registered_servers);
                if (ss_no != -1)
                    LRU_Insert(&LRU, ss_no, path);
            }
            if (ss_no == -1)
            {
                printf("COPY Fail: %s IP: %s Port: %d\n", PATH_NOT_FOUND_002, NM_ADDR, NM_PORT);
                char buffer[] = PATH_NOT_FOUND_002;
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }
            int ss_no2;
            ss_no2 = LRU_Search(&LRU, dest);
            if (ss_no2 == -1)
            {
                ss_no2 = findStorageServerForPath(dest, registered_servers, num_registered_servers);
                if (ss_no2 != -1)
                    LRU_Insert(&LRU, ss_no2, dest);
            }
            if (ss_no2 == -1)
            {
                printf("COPY Fail: %s IP: %s Port: %d\n", PATH_NOT_FOUND_002, NM_ADDR, NM_PORT);
                char buffer[] = PATH_NOT_FOUND_002;
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }
            // int ss_no2 = searchPath(registered_servers[0].trieRoot, dir);
            // printf("#%d %d ", ss_no, ss_no2);
            // return 0;
            if (server_status[ss_no] == 0 || server_status[ss_no2] == 0)
            {
                if (input == 1)
                    printf("CREATE Fail: %s IP: %s PORT: %d\n", SS_DOWN_025, NM_ADDR, NM_PORT);
                if (input == 2)
                    printf("DELETE Fail: %s IP: %s PORT: %d\n", SS_DOWN_025, NM_ADDR, NM_PORT);
                char buffer[] = SS_DOWN_025;
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }
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
                // exit(1);
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
                // exit(1);
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
                char path2[PATH_MAX];
                snprintf(path2, sizeof(path2), "%s", registered_servers[ss_no].cwd);
                strcat(path2, "/");
                strcat(path2, data.path);
                FILE *source_file = fopen(path2, "r");
                if (source_file == NULL)
                {
                    printf("COPY Fail: %s IP: %s Port: %d\n", FAILED_TO_OPEN_FILE_003, NM_ADDR, NM_PORT);
                    char buffer[] = FAILED_TO_OPEN_FILE_003;
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    continue;
                }
                strcat(data.dest, "/");
                strcat(data.dest, file);

                char dest2[PATH_MAX];
                printf("%d ", ss_no2);
                printf("%s", registered_servers[ss_no2].cwd);

                snprintf(dest2, sizeof(dest2), "%s", registered_servers[ss_no2].cwd);
                strcat(dest2, "/");
                strcat(dest2, data.dest);
                FILE *destination_file = fopen(dest2, "w");
                if (destination_file == NULL)
                {
                    printf("%s", dest2);
                    printf("COPY Fail: %s IP: %s Port: %d\n", FAILED_TO_OPEN_FILE_003, NM_ADDR, NM_PORT);
                    char buffer[] = FAILED_TO_OPEN_FILE_003;
                    fclose(source_file);
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    continue;
                }

                char ch;
                while ((ch = fgetc(source_file)) != EOF)
                    fputc(ch, destination_file);
                fclose(source_file);
                fclose(destination_file);
                char buffer[] = "ACK";
                printf("\033[0;32mCOPY SUCCESS IP: %s PORT: %d\033[0m\n", NM_ADDR, NM_PORT);
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                insertPath(registered_servers[ss_no2].trieRoot, data.dest);
                // insertPath(registered_servers[ss_no2].trieRoot, path);
                continue;
            }
            if (data.file_or_dir == 2)
            {
                int x = copyDirectory(path, dest, ss_no, ss_no2);
                if (x == 0)
                {
                    printf("%s IP: %s PORT: %d\n", COPY_FAIL_004, NM_ADDR, NM_PORT);
                    char buffer[] = COPY_FAIL_004;
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                }
                else
                {
                    printf("\033[0;32mCOPY SUCCESS IP: %s PORT: %d\n\033[0m", NM_ADDR, NM_PORT);
                    char buffer[] = "ACK";
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                }
            }

            close(ss_sock);

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
            // printf("hi");
            struct stat fileStat;
            if (stat(path, &fileStat) == 0)
            {
                // Check if it's a regular file
                if (S_ISREG(fileStat.st_mode))
                {
                }
                // Check if it's a directory
                else if (S_ISDIR(fileStat.st_mode))
                {
                    if (input == 4)
                    {
                        printf("READ Fail: %s IP: %s port: %d\n", READ_DIR_009, NM_ADDR, NM_PORT);
                        char buffer[] = READ_DIR_009;
                        int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    }
                    if (input == 5)
                    {
                        printf("WRITE Fail: %s IP: %s port: %d\n", WRITE_DIR_010, NM_ADDR, NM_PORT);
                        char buffer[] = WRITE_DIR_010;
                        int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    }
                    if (input == 6)
                    {
                        printf("INFORMATION Fail: %s IP: %s port: %d\n", INFO_DIR_011, NM_ADDR, NM_PORT);
                        char buffer[] = INFO_DIR_011;
                        int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    }
                    continue;
                }
                else
                {
                    if (input == 4)
                    {
                        printf("READ Fail: %s IP: %s port: %d\n", READ_DIR_009, NM_ADDR, NM_PORT);
                        char buffer[] = READ_DIR_009;
                        int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    }
                    if (input == 5)
                    {
                        printf("WRITE Fail: %s IP: %s port: %d\n", WRITE_DIR_010, NM_ADDR, NM_PORT);
                        char buffer[] = WRITE_DIR_010;
                        int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    }
                    if (input == 6)
                    {
                        printf("INFORMATION Fail: %s IP: %s port: %d\n", INFO_DIR_011, NM_ADDR, NM_PORT);
                        char buffer[] = INFO_DIR_011;
                        int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    }
                    continue;
                }
            }

            int ss_no;
            ss_no = LRU_Search(&LRU, path);
            if (ss_no == -1)
            {
                ss_no = findStorageServerForPath(path, registered_servers, num_registered_servers);
                if (ss_no != -1)
                    LRU_Insert(&LRU, ss_no, path);
            }
            //  printf("%d ",ss_no);
            //  return 0;
            if (ss_no == -1)
            {
                if (input == 4)
                    printf("READ Fail: %s IP: %s PORT: %d\n", PATH_NOT_FOUND_002, NM_ADDR, NM_PORT);
                if (input == 5)
                    printf("WRITE Fail: %s IP: %s PORT: %d\n", PATH_NOT_FOUND_002, NM_ADDR, NM_PORT);
                if (input == 6)
                    printf("INFORMATION Fail: %s IP: %s PORT: %d\n", PATH_NOT_FOUND_002, NM_ADDR, NM_PORT);
                char buffer[256] = PATH_NOT_FOUND_002;
                // printf("??");
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                continue;
            }
            else
            {
                if (server_status[ss_no] == 0 && input != 4)
                {
                    if (input == 4)
                        printf("READ Fail: %s IP: %s PORT: %d\n", SS_DOWN_025, NM_ADDR, NM_PORT);
                    if (input == 5)
                        printf("WRITE Fail: %s IP: %s PORT: %d\n", SS_DOWN_025, NM_ADDR, NM_PORT);
                    if (input == 6)
                        printf("INFORMATION Fail: %s IP: %s PORT: %d\n", SS_DOWN_025, NM_ADDR, NM_PORT);
                    char buffer[] = SS_DOWN_025;
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    continue;
                }
                char buffer[] = "FOUND";
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                if (input == 5)
                {
                    printf("Waiting for file access...\n");
                    sem_wait(&hash_table_lookup(path)->sem);
                }
                struct comStruct com;
                int ss_sock;
                struct sockaddr_in server_addr;
                int server_com;
                struct sockaddr_in com_address;
                if (server_status[ss_no] == 1)
                {
                    com.port = registered_servers[ss_no].client_port;
                    snprintf(com.ip, 17, "%s", registered_servers[ss_no].ip_address);
                    // printf("%s %d", com.ip, com.port);

                    data.file_or_dir = option;
                    data.request = input;
                    data.ss_no = ss_no;
                    snprintf(data.path, 1024, "%s", path);

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
                }
                else
                {
                    int flag = 1;
                    for (int i = 0; i < 3; i++)
                    {
                        // if (redundant_servers_status[i] == 1)
                        // {
                        //     com.port = redundant_servers[i].client_port;
                        //     snprintf(com.ip, 17, "%s", redundant_servers[i].ip_address);
                        //     data.file_or_dir = option;
                        //     data.request = input;
                        //     snprintf(data.path, 1024, "%s", path);

                        //     ss_sock = socket(AF_INET, SOCK_STREAM, 0);
                        //     if (ss_sock == -1)
                        //     {
                        //         perror("Socket creation failed");
                        //         exit(1);
                        //     }
                        //     server_addr.sin_family = AF_INET;
                        //     server_addr.sin_port = htons(redundant_servers[i].nm_port);
                        //     server_addr.sin_addr.s_addr = inet_addr(redundant_servers[i].ip_address);
                        //     flag = 0;
                        //     break;
                        // }
                    }
                    if (flag)
                    {
                        // error situation
                        if (input == 4)
                            printf("READ Fail: %s IP: %s PORT: %d\n", EVERYTHING_DOWN_022, NM_ADDR, NM_PORT);
                        if (input == 5)
                            printf("WRITE Fail: %s IP: %s PORT: %d\n", EVERYTHING_DOWN_022, NM_ADDR, NM_PORT);
                        if (input == 6)
                            printf("INFORMATION Fail: %s IP: %s PORT: %d\n", EVERYTHING_DOWN_022, NM_ADDR, NM_PORT);
                        char buffer[] = EVERYTHING_DOWN_022;
                        int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                        continue;
                    }
                }

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
                if (input == 5)
                {
                    rec_data = recv(client_socket, req, sizeof(req), 0);
                    sem_post(&hash_table_lookup(path)->sem);
                    if (strcmp(req, "ACK") == 0)
                    {
                        printf("\033[0;32mWRITE SUCCESS IP: %s PORT: %d\033[0m\n", NM_ADDR, NM_PORT);
                        // done writing to the file

                        // for (int k = 0; k < 3; k++)
                        // {
                        //     char source_file[1024];
                        //     strcpy(source_file, registered_servers[ss_no].cwd);
                        //     strcat(source_file, "/");
                        //     strcat(source_file, path);
                        //     FILE *source = fopen(source_file, "r");

                        //     char destination_file[1024];
                        //     strcpy(destination_file, redundant_servers[k].cwd);
                        //     strcat(destination_file, "/");
                        //     strcat(destination_file, path);
                        //     FILE *destination = fopen(destination_file, "w");

                        //     char ch;
                        //     while ((ch = fgetc(source)) != EOF)
                        //         fputc(ch, destination);
                        //     fclose(source);
                        //     fclose(destination);
                        // }
                    }
                    else
                    {
                        printf("WRITE FAIL %s IP: %s PORT: %d\n", req, NM_ADDR, NM_PORT);
                    }
                }
                else
                {
                    memset(req, 0, sizeof(req));
                    rec_data = recv(client_socket, req, sizeof(req), 0);
                    req[rec_data] = '\0';
                    if (strcmp(req, "ACK") == 0)
                    {
                        if (input == 4)
                            printf("\033[0;32mREAD SUCCESS IP: %s PORT: %d\033[0m\n", NM_ADDR, NM_PORT);
                        if (input == 6)
                            printf("\033[0;32mINFORMATION SUCCESS IP: %s PORT: %d\033[0m\n", NM_ADDR, NM_PORT);
                        // done writing to the file
                    }
                    else
                    {
                        // printf("**%s",req);
                        // ERROR FROM SS
                        if (input == 4)
                            printf("READ FAIL %s IP: %s PORT: %d\n", req, NM_ADDR, NM_PORT);
                        if (input == 6)
                            printf("INFORMATION FAIL %s IP: %s PORT: %d\n", req, NM_ADDR, NM_PORT);
                    }
                }
                close(ss_sock);
                // return 0;
            }
        }

        // close(client_socket);
    }
    close(client_socket);
    return 0;
}

// Mutex for ensuring thread safety while updating the server list
pthread_mutex_t server_list_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t redundant_servers_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t output_mutex = PTHREAD_MUTEX_INITIALIZER;

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

int main()
{
    // ...
    struct DataSent data;
    int client;
    struct sockaddr_in server_address, client_address;
    socklen_t client_address_len = sizeof(client_address);
    char buffer[1024];
    pthread_t new_client[10000], new_storage_servers[10000];
    for (int i = 0; i < max_servers; i++)
    {
        server_status[i] = 0;
    }
    for (int i = 0; i < 3; i++)
        redundant_servers_status[i] = 0;
    // Create a TCP socket
    serversock = socket(AF_INET, SOCK_STREAM, 0);
    if (serversock == -1)
    {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(11111); // set port
    server_address.sin_addr.s_addr = inet_addr("127.0.0.1");

    // Bind the socket to a specific address and port
    if (bind(serversock, (struct sockaddr *)&server_address, sizeof(server_address)) == -1)
    {
        perror("Can't bind socket");
        close(serversock);
        exit(EXIT_FAILURE);
    }

    // Listen for incoming connections
    if (listen(serversock, 100) == -1) // maximum length to which the queue of pending connections for sockfd may grow.
    {
        perror("Error listening");
        close(serversock);
        exit(EXIT_FAILURE);
    }

    while (1)
    {
        char initial_request[1024];
        // printf("HI ");
        int ss_socket = accept(serversock, (struct sockaddr *)&client_address, &client_address_len);
        if (ss_socket == -1)
        {
            perror("Can't accept connection");
            close(serversock);
            exit(EXIT_FAILURE);
        }

        // printf("ACCEPTED");

        // pthread_mutex_lock(&output_mutex);
        // printf("Connected to Storage Server\n");
        // pthread_mutex_unlock(&output_mutex);

        if (recv(ss_socket, &initial_request, sizeof(initial_request), 0) != -1)
        {
            if (strcmp("ss", initial_request) == 0)
            {
                // storage server
                pthread_mutex_lock(&output_mutex);
                printf("Connected to storage server\n");
                pthread_mutex_unlock(&output_mutex);
                struct StorageServerInfo received_ss_info;

                if (recv(ss_socket, &received_ss_info, sizeof(received_ss_info), 0) != -1)
                {
                    // printf("%d *%s* %s %s\n", received_ss_info.num_paths, received_ss_info.ip_address, received_ss_info.accessible_paths[0], received_ss_info.accessible_paths[1]);
                    //  Add the received SS information to the list of registered servers
                    if (num_registered_servers < max_servers)
                    {
                        pthread_mutex_lock(&server_list_mutex);
                        received_ss_info.socket = ss_socket;
                        received_ss_info.trieRoot = createTrieNode();
                        for (int i = 0; i < received_ss_info.num_paths; i++)
                        {
                            insertPath(received_ss_info.trieRoot, received_ss_info.accessible_paths[i]);
                            if (hash_table_lookup(received_ss_info.accessible_paths[i]) == NULL)
                            {
                                hash_table_insert(received_ss_info.accessible_paths[i]);
                            }
                        }
                        registered_servers[num_registered_servers] = received_ss_info;
                        server_status[num_registered_servers] = 1;
                        // printf("%d ", received_ss_info.trieRoot->isEndOfPath);
                        num_registered_servers++;
                        struct port_ind temp;
                        temp.index = num_registered_servers - 1;
                        temp.port = received_ss_info.client_port + 1;
                        temp.ss_socket = ss_socket;
                        if (pthread_create(&new_storage_servers[num_registered_servers - 1], NULL, server_func, &temp) != 0)
                        {
                            perror("Failed to create server timeout handling thread");
                            close(serversock);
                            exit(EXIT_FAILURE);
                        }
                        pthread_mutex_unlock(&server_list_mutex);
                        printf("Storage Server %d Initialized\n", num_registered_servers);
                        if (num_registered_servers == 3 && redundant_servers_count==3)
                        {
                            for (int i = 0; i < 3; i++)
                            {
                                char path[1024];
                                for (int j = 0; j < registered_servers[i].num_paths; j++)
                                {
                                    memset(path, 1024, '\0');
                                    strcpy(path, registered_servers[i].accessible_paths[j]);
                                    char path2[PATH_MAX];
                                    snprintf(path2, sizeof(path2), "%s", registered_servers[i].cwd);
                                    strcat(path2, "/");
                                    strcat(path2, path);
                                    struct stat fileInfo;
                                }
                            }
                        }
                        //             if (stat(path2, &fileInfo) == 0)
                        //             {
                        //                 if (S_ISREG(fileInfo.st_mode))
                        //                 {
                        //                     // file
                        //                     FILE *source_file;
                        //                     char dest[1024];
                        //                     for (int k = 0; k < 3; k++)
                        //                     {
                        //                         source_file = fopen(path2, "r");
                        //                         memset(dest, 1024, '\0');
                        //                         if (source_file == NULL)
                        //                         {
                        //                             perror("Error opening file for reading in copying, when registered_servers == 3");
                        //                         }
                        //                         //strcpy(dest, redundant_servers[k].cwd);
                        //                         //strcat(dest, "/");
                        //                         strcat(dest, path);
                        //                         FILE *destination_file = fopen(dest, "w");
                        //                         if (destination_file == NULL)
                        //                         {
                        //                             perror("Error opening file for writing in copying, when registered_servers == 3");
                        //                         }
                        //                         char ch;
                        //                         while ((ch = fgetc(source_file)) != EOF)
                        //                             fputc(ch, destination_file);
                        //                         fclose(source_file);
                        //                         fclose(destination_file);

                        //                      //   insertPath(redundant_servers[k].trieRoot, dest);
                        //                     }
                        //                 }
                        //                 else if (S_ISDIR(fileInfo.st_mode))
                        //                 {
                        //                     // directory
                        //                     char dest[1024];

                        //                     for (int k = 0; k < 3; k++)
                        //                     {
                        //                         DIR *dir = opendir(path2);
                        //                         struct dirent *entry;
                        //                         if (dir == NULL)
                        //                         {
                        //                             perror("Error in opening directory for copying, when registered_servers == 3");
                        //                             exit(1);
                        //                         }
                        //                         memset(dest, 1024, '\0');
                        //                        // strcpy(dest, redundant_servers[k].cwd);
                        //                       //  strcat(dest, "/");
                        //                         strcat(dest, path);

                        //                         // if (mkdir(dest, 0777) == -1)
                        //                         // {
                        //                         //     perror(REDUNDANT_DIR_023);
                        //                         // }
                        //                         // if (chmod(dest, get_permissions(fileInfo)) == -1)
                        //                         // {
                        //                         //     perror(REDUNDANT_PERMISSION_024);
                        //                         // }
                        //                         while ((entry = readdir(dir)) != NULL)
                        //                         {
                        //                             if (entry->d_type == DT_REG)
                        //                             {
                        //                                 char source[1024];
                        //                                 strcpy(source, path2);
                        //                                 strcat(source, "/");
                        //                                 strcat(source, entry->d_name);
                        //                                 FILE *source_file = fopen(source, "r");
                        //                                 // file
                        //                                 memset(dest, 1024, '\0');
                        //                                 //strcpy(dest, redundant_servers[k].cwd);
                        //                                 //strcat(dest, "/");
                        //                                 strcat(dest, entry->d_name);

                        //                                 FILE *destination_file = fopen(dest, "w");
                        //                                 if (destination_file == NULL)
                        //                                 {
                        //                                     perror("Error opening file for writing in copying, when registered_servers == 3");
                        //                                 }
                        //                                 char ch;
                        //                                 while ((ch = fgetc(source_file)) != EOF)
                        //                                     fputc(ch, destination_file);
                        //                                 fclose(source_file);
                        //                                 fclose(destination_file);

                        //                                // insertPath(redundant_servers[k].trieRoot, dest);
                        //                             }
                        //                             else if (entry->d_type == DT_DIR && strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0)
                        //                             {
                        //                                 char subdir[1024];
                        //                                 strcpy(subdir, path2);
                        //                                 strcat(subdir, "/");
                        //                                 strcat(subdir, entry->d_name);

                        //                                 char dest_subdir[1024];
                        //                                 strcpy(dest_subdir, path);
                        //                                 strcat(dest_subdir, "/");
                        //                                 strcat(dest_subdir, entry->d_name);

                        //                                 struct stat f;
                        //                                 stat(subdir, &f);
                        //                                 //cpy_dir2(subdir, dest_subdir, f, k);
                        //                               //  insertPath(redundant_servers[k].trieRoot, dest_subdir);
                        //                             }
                        //                         }
                        //                     }
                        //                 }
                        //                 else
                        //                 {
                        //                     // not a file, not a directory
                        //                 }
                        //             }
                        //         }
                        //         // create thread
                        //         redundant_servers_status[i] = 1;
                        //     }
                        // }
                        // else if (num_registered_servers > 3 && redundant_servers_count==3)
                        // {
                            // int i = num_registered_servers - 1;
                            // char path[1024];
                            // for (int j = 0; j < registered_servers[i].num_paths; j++)
                            // {
                            //     memset(path, 1024, '\0');
                            //     strcpy(path, registered_servers[i].accessible_paths[j]);
                            //     char path2[PATH_MAX];
                            //     snprintf(path2, sizeof(path2), "%s", registered_servers[i].cwd);
                            //     strcat(path2, "/");
                            //     strcat(path2, path);
                            //     struct stat fileInfo;
                            //     if (stat(path2, &fileInfo) == 0)
                            //     {
                            //         if (S_ISREG(fileInfo.st_mode))
                            //         {
                            //             // file
                            //             FILE *source_file;
                            //             if (source_file == NULL)
                            //             {
                            //                 perror("Error opening file for reading in copying, when registered_servers == 3");
                            //             }
                            //             char dest[1024];
                            //             for (int k = 0; k < 3; k++)
                            //             {
                            //                 source_file = fopen(path2, "r");
                            //                 memset(dest, 1024, '\0');
                            //                // strcpy(dest, redundant_servers[k].cwd);
                            //                 //strcat(dest, "/");
                            //                 strcat(dest, path);
                            //                 FILE *destination_file = fopen(dest, "w");
                            //                 if (destination_file == NULL)
                            //                 {
                            //                     perror("Error opening file for writing in copying, when registered_servers == 3");
                            //                 }
                            //                 char ch;
                            //                 while ((ch = fgetc(source_file)) != EOF)
                            //                     fputc(ch, destination_file);
                            //                 fclose(source_file);
                            //                 fclose(destination_file);

                            //                // insertPath(redundant_servers[k].trieRoot, dest);
                            //             }
                            //         }
                            //         else if (S_ISDIR(fileInfo.st_mode))
                            //         {
                            //             // directory
                            //             char dest[1024];

                            //             for (int k = 0; k < 3; k++)
                            //             {
                            //                 DIR *dir = opendir(path2);
                            //                 struct dirent *entry;
                            //                 if (dir == NULL)
                            //                 {
                            //                     perror("Error in opening directory for copying, when registered_servers == 3");
                            //                     exit(1);
                            //                 }
                            //                 memset(dest, 1024, '\0');
                            //                 //strcpy(dest, redundant_servers[k].cwd);
                            //               //  strcat(dest, "/");
                            //                 strcat(dest, path);

                            //                 // if (mkdir(dest, 0777) == -1)
                            //                 // {
                            //                 //     perror(REDUNDANT_DIR_023);
                            //                 // }
                            //                 // if (chmod(dest, get_permissions(fileInfo)) == -1)
                            //                 // {
                            //                 //     perror(REDUNDANT_PERMISSION_024);
                            //                 // }
                            //                 while ((entry = readdir(dir)) != NULL)
                            //                 {
                            //                     if (entry->d_type == DT_REG)
                            //                     {
                            //                         char source[1024];
                            //                         strcpy(source, path2);
                            //                         strcat(source, "/");
                            //                         strcat(source, entry->d_name);
                            //                         FILE *source_file = fopen(source, "r");
                            //                         // file
                            //                         memset(dest, 1024, '\0');
                            //                        // strcpy(dest, redundant_servers[k].cwd);
                            //                       //  strcat(dest, "/");
                            //                         strcat(dest, entry->d_name);

                            //                         FILE *destination_file = fopen(dest, "w");
                            //                         if (destination_file == NULL)
                            //                         {
                            //                             perror("Error opening file for writing in copying, when registered_servers == 3");
                            //                         }
                            //                         char ch;
                            //                         while ((ch = fgetc(source_file)) != EOF)
                            //                             fputc(ch, destination_file);
                            //                         fclose(source_file);
                            //                         fclose(destination_file);

                            //                        // insertPath(redundant_servers[k].trieRoot, dest);
                            //                     }
                            //                     else if (entry->d_type == DT_DIR && strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0)
                            //                     {
                            //                         char subdir[1024];
                            //                         strcpy(subdir, path2);
                            //                         strcat(subdir, "/");
                            //                         strcat(subdir, entry->d_name);

                            //                         char dest_subdir[1024];
                            //                         strcpy(dest_subdir, path);
                            //                         strcat(dest_subdir, "/");
                            //                         strcat(dest_subdir, entry->d_name);

                            //                         struct stat f;
                            //                         stat(subdir, &f);
                            //                        // cpy_dir2(subdir, dest_subdir, f, k);
                            //                        // insertPath(redundant_servers[k].trieRoot, dest_subdir);
                            //                     }
                            //                 }
                            //             }
                            //         }
                            //         else
                            //         {
                            //             // not a file, not a directory
                            //         }
                            //     }
                            // }
                        //}
                    }
                    else
                    {
                        break;
                        // Handle the case when the maximum number of SSs is reached
                        // You may want to implement error handling or log this event
                    }
                }
            }
            else if (strcmp("client", initial_request) == 0)
            {
                // client
                pthread_mutex_lock(&output_mutex);
                printf("Connected to Client %d\n", num_registered_clients + 1);
                pthread_mutex_unlock(&output_mutex);
                num_registered_clients++;
                if (pthread_create(&new_client[num_registered_clients - 1], NULL, client_func, &ss_socket) != 0)
                {
                    perror("Failed to create the client requests handling thread");
                    close(serversock);
                    exit(EXIT_FAILURE);
                }
            }
            else if (strcmp("rss", initial_request) == 0)
            {
                if (redundant_servers_count < 3)
                {
                    pthread_mutex_lock(&output_mutex);
                    printf("Connected to Redundant Storage Server %d\n", redundant_servers_count + 1);
                    pthread_mutex_unlock(&output_mutex);

                    struct StorageServerInfo received_ss_info;

                    if (recv(ss_socket, &received_ss_info, sizeof(received_ss_info), 0) != -1)
                    {
                        pthread_mutex_lock(&redundant_servers_mutex);
                        received_ss_info.socket = ss_socket;
                        received_ss_info.trieRoot = createTrieNode();
                        redundant_servers[redundant_servers_count] = received_ss_info;
                        redundant_servers_count++;
                        pthread_mutex_unlock(&redundant_servers_mutex);
                        printf("Redundant Storage Server %d Initialized\n", redundant_servers_count);
                    }
                }
                else
                {
                    // already 3 redundant storage servers have been initialized...
                }
            }
            else
            {
                // neither ss nor client.... ideally this case is not at all possible..
            }
        }
    }
    for (int i = 0; i < num_registered_clients; i++)
    {

        pthread_join(new_client[i], NULL);
    }
    
    // close(client_socket);
    return 0;

    // ...
}