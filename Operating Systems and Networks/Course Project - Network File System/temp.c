//*******************************************TRIE : STRUCT, CREATE, INSERT, REMOVE, SEARCH

struct TrieNode
{
    int isEndOfPath;
    struct TrieNode *children[256]; 
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
    for (int i = 0; i < 256; i++)
    {
        node->children[i] = 0;
    }
    node->isEndOfPath = 0;
    return node;
}

void insertPath(struct TrieNode *root, const char *path)
{
    //printf("#%s#", path);
    struct TrieNode *node = root;
    for (int i = 0; path[i] != '\0' && path[i] != '\n'; i++)
    {
        int index = (int)path[i];
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
        // printf("%d ",index);
        // printf("%c ",path[i]);
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
    // printf("Removed");
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

//****************************************COPY DIRECTORY

int copyDirectory(const char *source_dir, const char *destination_dir,int ss_no, int ss_no2)
{

    struct stat st;
    char dest_dir2[1024];
    if (stat(destination_dir, &st) != 0)
    {
        strcat(dest_dir2,registered_servers[ss_no2].cwd);
        strcat(dest_dir2,"/");
        strcat(dest_dir2,destination_dir);
       // printf("*** D %s",dest_dir2);
        // If the destination directory does not exist, create it
        mkdir(dest_dir2, 0777);
        int s = findStorageServerForPath(destination_dir, registered_servers, num_registered_servers);
        if (s != -1)
            insertPath(registered_servers[ss_no2].trieRoot, destination_dir);
    }
    
    char source2[1024];
    strcat(source2,registered_servers[ss_no].cwd);
    strcat(source2,"/");
    strcat(source2,source_dir);
    //printf("*** S %s",source2);
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

//******************************************* if input ==3 if data.file_or_dir==1 and 2
if (data.file_or_dir == 1)
            {
                char path2[PATH_MAX];
                snprintf(path2,sizeof(path2),"%s",registered_servers[ss_no].cwd);
                strcat(path2,"/");
                strcat(path2,data.path);
                FILE *source_file = fopen(path2, "r");
                if (source_file == NULL)
                {
                    printf("Failed to open source file: %s\n", data.path);
                    char buffer[] = "FAIL";
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    continue;
                }
                strcat(data.dest, "/");
                strcat(data.dest, file);

                char dest2[PATH_MAX];
                //printf("%s",registered_servers[ss_no2].cwd);

                snprintf(dest2,sizeof(dest2),"%s",registered_servers[ss_no2].cwd);
                strcat(dest2,"/");
                strcat(dest2,data.dest);
                FILE *destination_file = fopen(dest2, "w");
                if (destination_file == NULL)
                {
                    printf("Failed to create or open destination file: %s\n", data.dest);
                    fclose(source_file);
                    char buffer[] = "FAIL";
                    int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                    continue;
                }

                char ch;
                while ((ch = fgetc(source_file)) != EOF)
                    fputc(ch, destination_file);
                fclose(source_file);
                fclose(destination_file);
                char buffer[] = "ACK";
                int sent_data = send(client_socket, buffer, sizeof(buffer), 0);
                insertPath(registered_servers[ss_no2].trieRoot, data.dest);
                //insertPath(registered_servers[ss_no2].trieRoot, path);
                continue;
            }
            if (data.file_or_dir == 2)
            {
                int x = copyDirectory(path, dest, ss_no, ss_no2);
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

//*******************************ACCESSIBLE PATH LOOP
for (int i = 0; i < ss_i.num_paths; i++)
    {
        scanf("%s", s);
        if(s[0]=='.' && s[1]=='/')
        {
            char s2[256];
            int i=2;
            for(;i<strlen(s) && s[i]!='\n' && s[i]!='\0' ; i++)
            s2[i-2]=s[i];
            s2[i-2]='\0';
            snprintf(ss_i.accessible_paths[i], sizeof(ss_i.accessible_paths[i]), "%s", s2);
        }
        else
        snprintf(ss_i.accessible_paths[i], sizeof(ss_i.accessible_paths[i]), "%s", s);
        // insertPath(ss_i.trieRoot,s);
    }
