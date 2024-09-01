/*Includes*/
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <unistd.h>

/*C++ Style Macros*/
constexpr unsigned int MAX_BUFFER_LENGTH = 128;
constexpr unsigned int CLIENT_MSG_LENGTH = 25;
constexpr unsigned int ACKNOWLEDGE_MSG_LENGTH = 23;

/*Global Variables*/
signed int return_value = 0;
struct sockaddr_in server_address;
struct hostent* server;

int main(int argc,char* argv[])
{
    char* server_ip_address = argv[1];
    unsigned int server_port = std::stoi(argv[2]);
    std::string acknowledge_buffer(MAX_BUFFER_LENGTH,'\0');
    std::string client_msg_buffer(MAX_BUFFER_LENGTH,'\0');
    int client_socket = socket(AF_INET,SOCK_STREAM,0);
    if(client_socket < 0){
        std::cerr<<"Unable to create client socket"<<std::endl;
        return 1;
    }
    server = gethostbyname(server_ip_address);
    if(server == nullptr){
        std::cerr<<"Failed to get the server whose IP address is : "<<server_ip_address<<std::endl;
        return 2;
    }
    bzero((char*)&server_address,sizeof(server_address));
    server_address.sin_family = AF_INET;
    bcopy((char*)(server->h_addr),(char*)&(server_address.sin_addr.s_addr),(size_t)server->h_length);
    server_address.sin_port = htons(server_port);
    return_value = connect(client_socket,(const sockaddr*)&server_address,(socklen_t)sizeof(server_address));
    if(return_value < 0){
        std::cerr<<"Failed to connect to server whose IP address is "<<server_ip_address<<" and on port "<<server_port<<std::endl;
        return 3;
    }
    return_value = read(client_socket,&acknowledge_buffer[0],(size_t)ACKNOWLEDGE_MSG_LENGTH);
    if(return_value < 0){
        std::cerr<<"Failed to receive the server's acknowledgement message"<<std::endl;
        return 4;
    }
    std::cout<<"Message from server {IP address "<<server_ip_address<<" Port "<<server_port<<"}: "<<acknowledge_buffer<<std::endl;
    std::cout<<"Message to send to the server: ";
    getline(std::cin,client_msg_buffer);
    return_value = write(client_socket,client_msg_buffer.c_str(),(size_t)CLIENT_MSG_LENGTH);
    if(return_value < 0){
        std::cerr<<"Unable to send the message to the server"<<std::endl;
        return 5;
    }
    std::cout<<"End of operation"<<std::endl;
    close(client_socket);
    return EXIT_SUCCESS;
}