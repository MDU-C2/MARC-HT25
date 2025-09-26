/*
 MICROSOFT CODE!!!
 url: https://learn.microsoft.com/en-us/windows/win32/winsock/complete-client-code
 */
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x501

#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <string>

// Need to link with Ws2_32.lib, Mswsock.lib, and Advapi32.lib
#pragma comment (lib, "Ws2_32.lib")
#pragma comment (lib, "Mswsock.lib")
#pragma comment (lib, "AdvApi32.lib")


#define DEFAULT_BUFLEN 512
#define DEFAULT_PORT "1025"

int __cdecl main(int argc, char **argv) 
{
    WSADATA wsaData;
    SOCKET ConnectSocket = INVALID_SOCKET;
    struct addrinfo *result = NULL,
                    *ptr = NULL,
                    hints;
    char sendbuf[DEFAULT_BUFLEN];
    char recvbuf[DEFAULT_BUFLEN] = {'\0'};
    int iResult;
    int recvbuflen = DEFAULT_BUFLEN;
    
    // Validate the parameters
    // if (argc != 2) {
    //     printf("usage: %s server-name\n", argv[0]);
    //     return 1;
    // }

    // Initialize Winsock
    iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
    if (iResult != 0) {
        printf("WSAStartup failed with error: %d\n", iResult);
        return 1;
    }

    ZeroMemory( &hints, sizeof(hints) );
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;

    // Resolve the server address and port
    iResult = getaddrinfo(argv[1], DEFAULT_PORT, &hints, &result);
    if ( iResult != 0 ) {
        printf("getaddrinfo failed with error: %d\n", iResult);
        WSACleanup();
        return 1;
    }

    // Attempt to connect to an address until one succeeds
    for(ptr=result; ptr != NULL ;ptr=ptr->ai_next) {

        // Create a SOCKET for connecting to server
        ConnectSocket = socket(ptr->ai_family, ptr->ai_socktype, 
            ptr->ai_protocol);
        if (ConnectSocket == INVALID_SOCKET) {
            printf("socket failed with error: %ld\n", WSAGetLastError());
            WSACleanup();
            return 1;
        }

        // Connect to server.
        iResult = connect( ConnectSocket, ptr->ai_addr, (int)ptr->ai_addrlen);
        if (iResult == SOCKET_ERROR) {
            closesocket(ConnectSocket);
            ConnectSocket = INVALID_SOCKET;
            continue;
        }
        break;
    }

    freeaddrinfo(result);

    if (ConnectSocket == INVALID_SOCKET) {
        printf("Unable to connect to server!\n");
        WSACleanup();
        return 1;
    }


     bool continue_com = true;
    // Receive until the peer closes the connection
    do {


        // get user input to send
        fflush(stdin);
        printf("\nENTER MESSAGE: ");
        fgets(sendbuf,DEFAULT_BUFLEN,stdin);

        // remove \n and \r
        int i=strlen(sendbuf)-1,end_index = i;
        while(i > 0)
        {
            i--;
            if((sendbuf[i]=='\n') || (sendbuf[i]=='\r')) /* strip line feeds and carriage returns */
            {
                sendbuf[i] = '\0';
                end_index = i;
            }    
            else
                break;
            
        }

        // send message
        iResult = send( ConnectSocket,  sendbuf, end_index, 0 );
        if (iResult == SOCKET_ERROR) {
            printf("send failed with error: %d\n", WSAGetLastError());
            closesocket(ConnectSocket);
            WSACleanup();
            return 1;
        }

        printf("Bytes Sent: %ld\n", iResult);

        iResult = recv(ConnectSocket, recvbuf, recvbuflen, 0);
   
        if ( iResult > 0 )
        {
            printf("message received: %s\n", recvbuf);
            recvbuf[iResult]='\0';
            fflush(stdout);
        }
        else if ( iResult == 0 )
            printf("Connection closed\n");
        else
            printf("recv failed with error: %d\n", WSAGetLastError());
  
        continue_com = !(strcmp(recvbuf,"end_ack") == 0);
        printf("\n[debugg] %d\n",continue_com);
    } while( (iResult > 0) && continue_com);

    // cleanup
    closesocket(ConnectSocket);
    WSACleanup();

    return 0;
}