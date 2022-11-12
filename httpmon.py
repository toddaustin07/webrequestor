#!/usr/bin/env python

import http.server
import socket
import datetime
import time

SERVER_PORT = 6666
HTTP_OK = 200

def http_response(server, code, responsetosend):
    
    try:
        server.send_response(code)
        server.send_header("CONTENT-TYPE", 'text/xml; charset="utf-8"')
        server.send_header("DATE", datetime.datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S GMT"))
        server.send_header("SERVER", 'edgeBridge')
        server.send_header("CONTENT-LENGTH", str(len(responsetosend)))
        server.end_headers()
                
        server.wfile.write(bytes(responsetosend, 'UTF-8'))
    except:
        print (f'\033[91mHTTP Send error sending response: {responsetosend}\033[0m')

class myHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):

    def do_POST(self):
        print ('\n**********************************************************************************')
        print ('\033[93m' + time.strftime("%c") + f'\033[0m  {self.command} command received from: {self.client_address}')
        print ('Endpoint: ', self.path)
        print ('- - - - - - - - - - - - - - - - -')
        print ('Headers:\n', self.headers)
        print ('- - - - - - - - - - - - - - - - -')
        if ('Content-Length' in self.headers) or ('CONTENT-LENGTH' in self.headers):
            self.data_string = self.rfile.read(int(self.headers['Content-Length']))
            print ('Data:\n',self.data_string.decode('utf-8'))
        print ('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -')
        
        http_response(self, 200, "You done good")
        
    def do_PATCH(self):
        print ('\n**********************************************************************************')
        print ('\033[93m' + time.strftime("%c") + f'\033[0m  {self.command} command received from: {self.client_address}')
        print ('Endpoint: ', self.path)
        print ('- - - - - - - - - - - - - - - - -')
        print ('Headers:\n', self.headers)
        print ('- - - - - - - - - - - - - - - - -')
        if ('Content-Length' in self.headers) or ('CONTENT-LENGTH' in self.headers):
            self.data_string = self.rfile.read(int(self.headers['Content-Length']))
            print ('Data:\n',self.data_string.decode('utf-8'))
        print ('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -')
        
        http_response(self, 200, "You done good")
        
        
    def do_GET(self):
        print ('\n**********************************************************************************')
        print ('\033[93m' + time.strftime("%c") + f'\033[0m  {self.command} command received from: {self.client_address}')
        print ('Endpoint: ', self.path)
        print ('- - - - - - - - - - - - - - - - -')
        print ('Headers:\n', self.headers)
        print ('- - - - - - - - - - - - - - - - -')
        if ('Content-Length' in self.headers) or ('CONTENT-LENGTH' in self.headers):
            self.data_string = self.rfile.read(int(self.headers['Content-Length']))
            print ('Data:\n',self.data_string.decode('utf-8'))
        print ('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -')
        
        http_response(self, 200, "You done good")
        

    def do_DELETE(self):
        print ('\n**********************************************************************************')
        print ('\033[93m' + time.strftime("%c") + f'\033[0m  {self.command} command received from: {self.client_address}')
        print ('Endpoint: ', self.path)
        
        handle_requests(self, 'DELETE', self.path, self.client_address)



if __name__ == '__main__':


    HandlerClass = myHTTPRequestHandler
    ServerClass = http.server.HTTPServer

    httpd = ServerClass(('', SERVER_PORT), HandlerClass)

    if httpd:
        # Trick to get our IP address
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        myipAddress =  s.getsockname()[0]
        s.close()

        print (f"\033[94m > Serving HTTP on {myipAddress}:{SERVER_PORT}\033[0m\n")

        try: 
            httpd.serve_forever()    # wait for, and process HTTP requests

        except KeyboardInterrupt:
            print ('\n\033[92mINFO: Action interrupted by user...\033[0m\n')
    else:
        print ('\n\033[91mERROR: cannot initialize Server\033[0m\n')
