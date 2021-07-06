#!/usr/bin/python
# -*- coding: UTF-8 -*-

import pxssh
import sys
import getpass

#Variaveis de entrada
if sys.version_info.major == 2:
    username = raw_input('Insira seu usuário SSH: ') 
    password = getpass.getpass('Insira sua senha SSH: ')
    command = raw_input('Insira o comando a ser executado nos servidores remotos: ')
elif sys.version_info.major == 3:
    username = input('Insira seu usuário SSH:') 
    password = getpass.getpass('Insira sua senha SSH:')
    command = input('Insira o comando a ser executado nos servidores remotos:')
    
#Abre o arquivo que contem a lista de servidores a ser executado os comandos        
with open('/srv/scripts/labs/lista_servidores.txt', 'r') as servidores:
    for servidor in servidores:
        try:
            s = pxssh.pxssh()
            hostname = servidor.rstrip('\r\n')
            s.login (hostname, username, password)
            s.sendline (command)
            s.prompt()
            print(hostname,s.before.split('\r\n'))
            s.logout()
            print
        
        except pxssh.ExceptionPxssh, e:
            print "Falha no login ao servidor:", hostname
            print str(e)
