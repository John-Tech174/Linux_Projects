/*Includes*/
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <unistd.h>

/*C++ Style Macros*/
constexpr unsigned int MAX_BUFFER_SIZE = 128;
constexpr unsigned int ACKNOWLEDGE_MSG_LENGTH = 23;
constexpr unsigned int CLIENT_MSG_LENGTH = 25;
constexpr unsigned int CONNECTIONS_QUEUE_LENGTH = 6;

/*Global Variables Declarations*/
signed int return_value = 0;
signed int option_value = 1; //Non-zero value to enable options
struct sockaddr_in server_address, client_address;
    
int main(int argc,char* argv[])
{
    char* ip_address = argv[1];
    unsigned int port_number = std::stoi(argv[2]);
    socklen_t client_address_length = sizeof(client_address);
    std::string read_buffer(MAX_BUFFER_SIZE,'\0');
    int server_socket = socket(AF_INET,SOCK_STREAM,0);
    if(server_socket < 0){
        std::cerr<<"Couldn't create socket"<<std::endl;
        return 1;
    }
    return_value = setsockopt(server_socket,SOL_SOCKET,SO_REUSEADDR,&option_value,(socklen_t)sizeof(int));
    if(return_value < 0){
        std::cerr<<"Unable to set server socket option"<<std::endl;
        return 2;
    }
    bzero((char*)&server_address,(size_t)sizeof(server_address));
    server_address.sin_family = AF_INET;
    inet_aton(ip_address,&(server_address.sin_addr));
    server_address.sin_port = htons((uint16_t)port_number);
    return_value = bind(server_socket,(const sockaddr*)&server_address,(socklen_t)sizeof(server_address));
    if(return_value < 0){
        std::cerr<<"Unable to bind the server's socket to IP address : "<<ip_address<<" and port : "<<port_number<<std::endl;
        return 3;
    }
    return_value = listen(server_socket,CONNECTIONS_QUEUE_LENGTH);
    if(return_value < 0){
        std::cerr<<"Unable to listen on the server's socket"<<std::endl;
        return 4;
    }
    int new_server_socket = accept(server_socket,(sockaddr*)&client_address,&client_address_length);
    if(new_server_socket < 0){
        std::cerr<<"Failed to accept connection from client"<<std::endl;
        return 5;
    }
    std::cout<<"Established a connection to the client whose IP address is : "<<inet_ntoa(client_address.sin_addr)
             <<" and port : "<<ntohs((uint16_t)client_address.sin_port)<<std::endl;
    return_value = write(new_server_socket,"Connected successfully",(size_t)ACKNOWLEDGE_MSG_LENGTH);
    if(return_value < 0){
        std::cerr<<"Unable to send acknowledgement message to "<<inet_ntoa(client_address.sin_addr)<<std::endl;
        return 6;
    }
    return_value = read(new_server_socket,&read_buffer[0],(size_t)CLIENT_MSG_LENGTH);
    if(return_value < 0){
        std::cerr<<"Unable to read the message sent from : "<<inet_ntoa(client_address.sin_addr)<<std::endl;
        return 7;
    }
    std::cout<<"Received message from client : "<<inet_ntoa(client_address.sin_addr)<<": "<<read_buffer<<std::endl;
    std::cout<<"End of operation"<<std::endl;
    close(new_server_socket);
    close(server_socket);
    return EXIT_SUCCESS;
}