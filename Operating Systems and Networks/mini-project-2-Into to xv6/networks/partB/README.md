Report for 
Part B : Implement TCP functionality using UDP sockets


1. How is the data sequencing and retransmission implemented here, different from traditional TCP ?

Ans: The differences are as follows:
	
i. In traditional TCP, the sequence number for a segment is the byte-stream number of the first byte in the segment. Let’s look at an example. 

Suppose that a process in Host A wants to send a stream of data to a process in Host B over a TCP connection. The TCP in Host A will
implicitly number each byte in the data stream. Suppose that the data stream consists of a file consisting of 500,000 bytes, that the MSS  is 1,000 bytes, and that the first byte of the data stream is numbered 0.
As shown in Figure 1, TCP constructs 500 segments out of the data stream. The first segment gets assigned sequence number 0, the second segment gets assigned sequence number 1,000, the third segment gets assigned sequence number 2,000, and so on. Each sequence number is inserted in the sequence number field in the header of the appropriate TCP segment.

[Once a TCP connection is established, the two application processes can send data to each other. Let’s consider the sending of data from the client process to the server process. The client process passes a stream of data through the socket. Once the data passes through the socket, the data is in the hands of TCP running in the client. TCP directs this data to the connection’s send buffer, which is one of the buffers that is set aside during the initial three-way handshake. From time to time, TCP will grab chunks of data from the send buffer and pass the data to the network layer. The maximum amount of data that can be grabbed and placed in
a segment is limited by the maximum segment size (MSS). The MSS is typically set by first determining the length of the largest link-layer frame that can be sent by the local sending host (the so- called maximum transmission unit, MTU), and then setting the MSS to ensure that a TCP segment (when encapsulated in an IP datagram) plus the TCP/IP header length (typically 40 bytes) will fit into a single link-layer frame. Both Ethernet and PPP link-layer protocols have an MTU of 1,500 bytes. Thus a typical value of MSS is 1460 bytes. the MSS limits the maximum size of a segment’s data field. When TCP sends a large file, such as an image as part of a Web page, it typically breaks the file into chunks of size MSS
(except for the last chunk, which will often be less than the MSS). Interactive applications, however, often transmit data chunks that are smaller than the MSS; for example, with remote login applications like Telnet, the data field in the TCP segment is often only one byte. Because the TCP header is typically 20 bytes (12 bytes more than the UDP header), segments sent by Telnet may be only 21 bytes in length.]


Whereas in the implementation done here, the sequence number for ‘i’th data segment is ‘i’. And in a way the chunk size is variable for traditional TCP, as in it is typically set to MTU of the link-layer protocol – 40 bytes. [But for a given protocol, MSS is fixed]. Whereas in the implementation done here, the chunk size is fixed [not related to the link-layer protocol used] and is only 1 byte, much less than that used in traditional TCP.

In traditional TCP, two completely independent values of MSS are permitted for the two directions of data flow in a TCP connection, so there is no need to agree on a common MSS configuration for a bidirectional connection. Whereas in this implementation, in both directions, chunk size is fixed and is the same.

ii. In traditional TCP, the total number of chunks being sent is typically not included in each data segment being sent. Wheres in this implementation, the total number of chunks is communicated in every chunk/data segment.

iii. In traditional TCP, since TCP is full-duplex, so that Host A may be receiving data from Host B while it sends data to Host B (as part of the same TCP connection). Each of the segments that arrive from Host B has a sequence number for the data flowing from B to A. The acknowledgment number that Host A puts in its segment is the sequence number of the next byte Host A is expecting from Host B.  Because TCP only acknowledges bytes up to the first missing byte in the stream, TCP is said to provide “cumulative acknowledgments”.

Whereas in this implementation, only one of the server/client will be sending messages at a time. So, there is no need of such a robust mechanism for acknowledgment. We simply use the sequence number/id of the data sequence received as an acknowledgment for receiving that data segment/chunk. 

iv. In traditional TCP, both sides of a TCP connection randomly choose an initial sequence number. This is done to minimize the possibility that a
segment that is still present in the network from an earlier, already-terminated connection between two hosts is mistaken for a valid segment in a later connection between these same two hosts (which also
happen to be using the same port numbers as the old connection).

Whereas in this implementation, always initial sequence number is 0.

v. In traditional TCP, reliability is achieved by the sender detecting lost data and retransmitting it. TCP uses two primary techniques to identify loss. Retransmission timeout (RTO) and duplicate cumulative acknowledgements (DupAcks).  In DupAcks, If a single segment (say segment number 100) in a stream is lost, then the receiver cannot acknowledge packets above that segment number (100) because it uses cumulative ACKs. Hence the receiver acknowledges packet 99 again on the receipt of another data packet. This duplicate acknowledgement is used as a signal for packet loss. 
In timeout-based detection, When a sender transmits a segment, it initializes a timer with a conservative estimate of the arrival time of the acknowledgement. The segment is retransmitted if the timer expires, with a new timeout threshold of twice the previous value, resulting in “exponential backoff” behavior.

Whereas in this implementation, timeout is used, but the timeout always remains the same [0.1 seconds]









2. How can you extend your implementation to account for flow control ?

Ans: Among all the mechanisms that potentially can be implemented to account for flow control, the most suitable one is:
Sliding-window mechanism/ Feedback loop:
As mentioned in Wikipedia source, in each TCP segment/chunk the receiver specifies either the amount of data it can receive or the amount of additionally received data (in bytes) that it is willing to buffer for the connection, in a seperate feedback packet or along with ACK, so that the server can adjust its transmission rate based on the feedback packet or send only up to that amount of data before it must wait for a complete acknowledgement. The receiver can estimate the amount of data it is willing to receive, using methods such as keeping track of amount of data currently in buffer, estimate its processing speed, etc.

Another trivial way to account for flow control is to start off the communication from the server with the bare minimum data rate, and gradually increase the data rate after every sending each data segment/chunk. Keep track of the number of acknowledgements that were not received within the timeout period. We can pre-determine a value for the thershold for the acknowledgements not received in this process, and maintan the data rate a bit less than that at this thershold level.

