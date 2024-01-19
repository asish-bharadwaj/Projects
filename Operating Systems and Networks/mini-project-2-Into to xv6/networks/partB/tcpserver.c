#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>

typedef struct chunk{
    // data
        char msg[8];
    // header
        int seqId;
        int totalchunks;
}chunk;
typedef chunk* Chunk;

ssize_t send_using_udp(int client_socket, char* message_to_send, int message_len, struct sockaddr_in* client){
    // Each chunk's data size of 1 Byte [last bit is for null termination '\0']
    int no_of_chunks = message_len/7 + 1;
    char* message = (char*)malloc(sizeof(char)*7*no_of_chunks+1);
    memset(message, '\0', 7*no_of_chunks+1);
    strcpy(message, message_to_send);

    // allocating memory for all the chunks 
    // and dividing data into smaller chunks of fixed size [1 byte]
    Chunk chunksArr[no_of_chunks];
    for(int i = 0; i < no_of_chunks; i++){
        chunksArr[i] = (Chunk)malloc(sizeof(chunk));
        chunksArr[i]->totalchunks = no_of_chunks;
        memset(chunksArr[i]->msg, '\0', 8);
        strncpy(chunksArr[i]->msg, message+i*7, 7);
        chunksArr[i]->seqId = i;
    }
    int stlen = sizeof(struct sockaddr_in);
    struct timeval timeout;
    timeout.tv_sec = 0;
    timeout.tv_usec = 100000;

    // setting the socket to timeout after 0.1 second, if ACK is not received from the receiver
    if (setsockopt(client_socket, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout)) == -1) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }
    char acks[no_of_chunks];
    int ack, acksrecd = 0;
    struct timeval send_times[no_of_chunks], temp;
    memset(acks, '0', no_of_chunks);

    for(int i = 0; i < no_of_chunks; i++){
        ack = -1;
        // send the data
        if(sendto(client_socket, chunksArr[i], sizeof(chunk), 0, (struct sockaddr*)client, sizeof(*client)) == -1){
            return -1;
        }
        printf("\nsent: seqId - %d\tdata - %s\ttotalChunks - %d\n", chunksArr[i]->seqId, chunksArr[i]->msg, chunksArr[i]->totalchunks);
        // store the time of sending data [for re-transmitting after timeout]
        gettimeofday(&temp, NULL);
        send_times[i] = temp;
        // check is any ACK is sent from the receiver
        if(recvfrom(client_socket, &ack, sizeof(int), 0, (struct sockaddr*)client, &stlen) == -1){ 
            if(errno != EAGAIN)
                // if the error was raised due to timeout
                return -1;
        }
        // if at all some ACK is received and if it is indeed a valid ACK [nothing but the seqId], set the ACK bit for that chunk 
        if(ack >= 0 && ack < no_of_chunks){
            printf("\nrecd : ACK for seqId - %d\n", ack);
            acks[ack] = 1;
            acksrecd++;
        }
        // Iterate over all the chunks sent till now
        // If ACK isn't received yet and the data was sent more than 0.1 sec earlier, RE-TRANSMIT that chunk
        // update the time of data sent [send_times[]] to current time
        for(int j = 0; j < i; j++){
            if(acks[j] == '0'){
                if((temp.tv_sec - send_times[j].tv_sec) + (temp.tv_usec - send_times[j].tv_usec)/1000000 > 0.1){
                    printf("\nACK for seqId - %d not recd within 0.1 sec. RE-TRANSMITTING\n", j);
                    printf("\nsent: seqId - %d\tdata - %s\ttotalChunks - %d\n", chunksArr[i]->seqId, chunksArr[i]->msg, chunksArr[i]->totalchunks);
                    if(sendto(client_socket, chunksArr[j], sizeof(chunk), 0, (struct sockaddr*)client, sizeof(*client)) == -1){
                        return -1;
                    }
                    send_times[j] = temp;
                }
            }
        }
    }
    // By now, all the chuncks have been sent from the server exactly once
    // But communication isn't successful yet
    // Loop until ACK is received for all the chunks
    // In each iteration, check if any ACK is received
    // In each loop, iterate over all the processes. If the chunk's ACK is not set and the data was sent more than 0.1 seconds earlier, RE-TRANSMIT that chunk
    while(acksrecd != no_of_chunks){
        ack = -1;
        gettimeofday(&temp, NULL);
        if(recvfrom(client_socket, &ack, sizeof(int), 0, (struct sockaddr*)client, &stlen) == -1){ 
            if(errno != EAGAIN)
                return -1;
        }
        if(ack >= 0 && ack < no_of_chunks){
            printf("\nrecd : ACK for seqId - %d\n", ack);
            acks[ack] = 1;
            acksrecd++;
        }
        for(int j = 0; j < no_of_chunks; j++){
            if(acks[j] == '0'){
                if((temp.tv_sec - send_times[j].tv_sec) + (temp.tv_usec - send_times[j].tv_usec)/1000000 > 0.1){
                    printf("\nACK for seqId - %d not recd within 0.1 sec. RE-TRANSMITTING\n", j);
                    printf("\nsent: seqId - %d\tdata - %s\ttotalChunks - %d\n", chunksArr[j]->seqId, chunksArr[j]->msg, chunksArr[j]->totalchunks);
                    if(sendto(client_socket, chunksArr[j], sizeof(chunk), 0, (struct sockaddr*)client, sizeof(*client)) == -1){
                        return -1;
                    }
                    send_times[j] = temp;
                }
            }
        }
    }

    for(int i = 0; i < no_of_chunks; i++){
        free(chunksArr[i]);
        chunksArr[i] = NULL;
    }
    free(message);
    message = NULL;
    printf("\nFinished with dividing the data and (re)transmitting. All chunks have been sent to the client. ACK recd for all chunks\n");
    return message_len;
}

ssize_t recv_using_udp(int client_socket, char* msg_buf, int buf_len, struct sockaddr_in* client){
    int chunks_recd = 0, chunks_to_receive = __INT_MAX__, chunks_ack = 0;
    // Each chunk's data size of 1 Byte [last bit is for null termination '\0']
    int no_of_chunks = buf_len/7 + 1;
    Chunk chunksArr[no_of_chunks];
    chunk temp;
    temp.seqId = -1;
    // allocating memory for all the chunks 
    for(int i = 0; i < no_of_chunks; i++){
        chunksArr[i] = (Chunk)malloc(sizeof(chunk));
        chunksArr[i]->seqId = i;
        memset(chunksArr[i]->msg, '\0', 8);
    }

    int stlen = sizeof(*client), p;
    // In a loop, receive chunks from the server, until all the chunks are received
    do{
        if(recvfrom(client_socket, &temp, sizeof(chunk), 0, (struct sockaddr*)client, &stlen) == -1){
            return -1;
        }
        printf("\nrecd : %d %s %d\n", temp.seqId, temp.msg, temp.totalchunks);
        // If a valid chunk is recd, store the data in chunksArr, increment the chunks_recd counter
        if(temp.seqId < chunks_to_receive && temp.seqId >= 0){
            chunks_ack++;
            int id = temp.seqId;
            // if(chunks_ack % 3 != 0){
                strcpy(chunksArr[temp.seqId]->msg, temp.msg);
                chunksArr[temp.seqId]->totalchunks = temp.totalchunks;
                chunks_recd++;
                chunks_to_receive = temp.totalchunks;
                // send the seqId as ACK to the sender
                printf("\nsent : ACK for chunk - %d\n", id);
                if(sendto(client_socket, &id, sizeof(int), 0, (struct sockaddr*)client, stlen) == -1){
                    return -1;
                }
            // }
            // else{
            //     printf("\nNOT SENDING ACK FOR CHUNK - %d\n", id);
            // }
        }
    }
    while(chunks_recd < chunks_to_receive);

    //Aggregate all the chunks
    for(int i = 0; i < no_of_chunks; i++){
        strncpy(msg_buf+7*i, chunksArr[i]->msg, 7);
    }

    for(int i = 0; i < no_of_chunks; i++){
        free(chunksArr[i]);
        chunksArr[i] = NULL;
    }

    printf("\nFinished with receiving all the chunks and aggregating them\n");
    return buf_len;
}

int main(){
    int port = 7000;
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
    char* message_from_client = (char*)malloc(sizeof(char)*4096);
    char* message_to_client = "Hi dear client. Welcome to UDP Server";
    int stlen = sizeof(client);

    // Receive data from client [Here we do not have listen and accept, which are used in TCP]
    if(recv_using_udp(server_socket, message_from_client, 4096, &client) == -1){
        perror("Error recceiving message from client ");
        exit(EXIT_FAILURE);
    }

    printf("\nMessage received from client:\n\033[0;32m%s\033[0;37m\n", message_from_client);

    // Send a response to the client
    if(send_using_udp(server_socket, message_to_client, strlen(message_to_client), &client) == -1){
        perror("Error sending message to server");
        exit(EXIT_FAILURE);
    }

    if(close(server_socket) == -1){
        perror("Error in closing the server socket:");
        exit(EXIT_FAILURE);
    }
    printf("\nClosed socket\n");

    free(message_from_client);
    message_from_client = NULL;
}