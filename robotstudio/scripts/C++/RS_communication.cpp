#include <iostream>
#include <cstring>
#include <sys/types.h>
#ifdef _WIN32
#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#endif

class RSCommunication {
public:
    RSCommunication(const std::string& ip, int port)
        : server_ip(ip), server_port(port), sockfd(-1) {}

    bool connectToRobot() {
#ifdef _WIN32
        WSADATA wsaData;
        if (WSAStartup(MAKEWORD(2,2), &wsaData) != 0) {
            std::cerr << "WSAStartup failed\n";
            return false;
        }
#endif
        sockfd = socket(AF_INET, SOCK_STREAM, 0);
        if (sockfd < 0) {
            std::cerr << "Socket creation failed\n";
            return false;
        }

        sockaddr_in serv_addr;
        serv_addr.sin_family = AF_INET;
        serv_addr.sin_port = htons(server_port);
        serv_addr.sin_addr.s_addr = inet_addr(server_ip.c_str());

        if (connect(sockfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) < 0) {
            std::cerr << "Connection failed\n";
            closeSocket();
            return false;
        }
        return true;
    }

    bool sendMessage(const std::string& msg) {
        if (sockfd < 0) return false;
        int sent = send(sockfd, msg.c_str(), msg.size(), 0);
        return sent == msg.size();
    }

    std::string receiveMessage(size_t maxlen = 1024) {
        if (sockfd < 0) return "";
        char buffer[1024] = {0};
        int received = recv(sockfd, buffer, maxlen, 0);
        if (received > 0)
            return std::string(buffer, received);
        return "";
    }

    void closeSocket() {
        if (sockfd >= 0) {
#ifdef _WIN32
            closesocket(sockfd);
            WSACleanup();
#else
            close(sockfd);
#endif
            sockfd = -1;
        }
    }

    ~RSCommunication() {
        closeSocket();
    }

private:
    std::string server_ip;
    int server_port;
    int sockfd;
};

// Example usage
int main() {
    RSCommunication rs("192.168.125.1", 5000); // Replace with RobotStudio IP and port
    if (rs.connectToRobot()) {
        rs.sendMessage("Hello RAPID\n");
        std::string reply = rs.receiveMessage();
        std::cout << "RobotStudio replied: " << reply << std::endl;
    }
    return 0;
}