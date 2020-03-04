#!/bin/bash
### Script de integração do OpenMediaVault ao Active Directory Microsoft ou SAMBA 4 ####
#Autor: Eduardo Jonck
#Email: eduardo@eduardojonck.com
#Data: 24/02/2020
#Versão: 1.0

#Arquivo de log
log_file="/var/log/join_omv_ad.log"

whiptail --title 'Bem Vindo!' 		  \
         --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
         --msgbox '\n                    Versao: 1.0\n               Autor: Eduardo Jonck\n          Email: eduardo@eduardojonck.com\n\nSeja bem vindo ao script de integracao do OpenMediaVault ao Active Diretory.\n\nNo decorrer da integracao, serao feitas algumas perguntas.\n\nExtremamente importante responde-las corretamente.
		\n\n\n' \
		20 60

if (whiptail --title "Atencao!!!!" \
             --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY - EDUARDO JONCK'	       \
             --yes-button "Sim" --no-button "Nao" --yesno "As configuracoes abaixo devem estar ok antes de proceguir: \n\n * Endereco IP estatico ja definido; \n * Nome do servidor; \n * Configuracoes do SMB como padrao de fabrica. \n\n Tais configuracoes estao ok?" \
			   20 60) then


#Testar sem o servidor tem acesso a internet para instalar os pacotes de dependencias
clear
echo -e "\033[01;32m##########################################################################\033[01;37m"
echo -e "\033[01;32m## Testando comunicacao do OpenMediaVault com a Internet, aguarde....  ###\033[01;37m"
echo -e "\033[01;32m##########################################################################\033[01;37m"
ping -q -c3 google.com &>/dev/null

if [ $? -eq 0 ] ; then

        whiptail --title "Teste de Comunicacao com a Internet" \
				 --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY - EDUARDO JONCK'	       \
                 --msgbox "O servidor OpenMediaVault tem acesso a internet, pressione OK para prosseguir." \
				 --fb 10 50

else
		
        whiptail --title "Teste de Comunicacao com a Internet" \
				 --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY - EDUARDO JONCK'	       \
                 --msgbox "O servidor OpenMediaVault esta sem acesso a internet. Revise as configuracoes de rede e execute novamente esse script." \
				 --fb 20 50
  exit
fi



(
c=5
while [ $c -ne 1 ]
    do
        echo $c
        echo "###"
        echo "$c %"
        echo "###"
        ((c+=95))
        sleep 1

if [ -f /etc/krb5.conf ];
        then
                echo
        else
        DEBIAN_FRONTEND=noninteractive apt-get -yq install ntpdate krb5-user krb5-config winbind samba samba-common smbclient cifs-utils libpam-krb5 libpam-winbind libnss-winbind > $log_file 2>/dev/null
        fi

break
done
) |
whiptail --title "Instalacao das dependencias" \
         --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
         --gauge "Aguarde a instalacao das dependencias ...." 10 60 0



hostname_ad=$(whiptail --title "Informacao do nome do Servidor Active Directory" \
                       --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	\
                       --inputbox "Digite o nome do servidor do active Directory.\n\nEx: servidor-ad" \
					   --fb 15 60 3>&1 1>&2 2>&3)
while [ ${#hostname_ad} = 0 ]; do
[ $? -ne 0 ] & exit
       done

ip_srv_ad=$(whiptail --title "Informar IP do Servidor AD" \
                     --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY' \
                     --inputbox "Digite o endereco IP do servidor Active Directory\n\nEx:192.168.1.250" \
 					 --fb 15 60 3>&1 1>&2 2>&3)
while [ ${#ip_srv_ad} = 0 ]; do
[ $? -ne 0 ] & exit
       done

dominio_ad=$(whiptail --title "Configuracao do Dominio para a Integracao" \
                      --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
                      --inputbox "Digite o dominio configurado atualmente no Active Directory.\n\nEx: dominio.local" \
 					  --fb 15 60 3>&1 1>&2 2>&3)
while [ ${#dominio_ad} = 0 ]; do
[ $? -ne 0 ] & exit
       done
	   
	   
#Inicia teste de comunicacao entre os servers (PING no IP)
clear
echo -e "\033[01;32m###################################################################\033[01;37m"
echo -e "\033[01;32m## Testando o PING no IP do servidor AD informado, aguarde....  ###\033[01;37m"
echo -e "\033[01;32m###################################################################\033[01;37m"
ping -q -c3 $ip_srv_ad &>/dev/null

if [ $? -eq 0 ] ; then

        whiptail --title "Teste de Comunicacao (PING)" \
				 --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
                 --msgbox "O PING no endereco IP do servidor AD foi bem sucessido, pressione OK para prosseguir." \
 				 --fb 10 50
else

        whiptail --title "Teste de Comunicacao (PING)" \
		         --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
                 --msgbox "O PING no endereco IP do servidor AD nao foi possivel. Revise as configuracoes de rede e execute novamente esse script." \
				 --fb 20 50
  exit
fi

#Coleta dados do servidor OMV
ip_srv_omv=$(whiptail --title "Informacao do IP do OpenMediaVault" \
                      --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
                      --inputbox "Qual endereco IP do OpenMediaVault que voce deseja se comunicar com o AD?:" \
   					  --fb 10 60 3>&1 1>&2 2>&3)
while [ ${#ip_srv_omv} = 0 ]; do
[ $? -ne 0 ] & exit
       done

#Alterar nome do arquivo /etc/hostname sem o dominio
change_hostname_samba=$(cat /etc/hostname |cut -d '.' -f 1)
echo $change_hostname_samba > /etc/hostname

#Coleta novo hostname
hostname_samba=$(cat /etc/hostname)
netbios_dc=$(echo $dominio_ad |cut -d '.' -f 1)


#Apontamento de nomes diretamente no arquivo hosts
echo $ip_srv_omv   ${hostname_samba,,}   ${hostname_samba,,}.${dominio_ad,,} > /etc/hosts
echo $ip_srv_ad   ${hostname_ad,,}   ${hostname_ad,,}.${dominio_ad,,} >> /etc/hosts

#Ajusta os dominios no resolv.conf
if [ ! -f /etc/resolv.conf.bkp ]; then
cp /etc/resolv.conf /etc/resolv.conf.bkp
fi

echo search $dominio_ad > /etc/resolv.conf
echo nameserver $ip_srv_ad >> /etc/resolv.conf
echo nameserver 208.67.222.222 >> /etc/resolv.conf
echo nameserver 8.8.8.8 >> /etc/resolv.conf

#Ajusta arquivos Kerberos
if [ ! -f /etc/krb5.conf.bkp ]; then
cp /etc/krb5.conf /etc/krb5.conf.bkp
fi

echo "[logging]
default = FILE:/var/log/krb5libs.log
kdc = FILE:/var/log/krb5kdc.log
admin_server = FILE:/var/log/kadmind.log


[libdefaults]
ticket_lifetime = 24000
default_realm = ${dominio_ad^^}
dns_lookup_realm = false
dns_lookup_kdc = true
forwardable = true

[realms]
${dominio_ad^^} = {
kdc = $ip_srv_ad
admin_server = $ip_srv_ad
default_domain = ${dominio_ad,,}
}

[domain_realm]
.${dominio_ad,,} = ${dominio_ad^^}
${dominio_ad,,} = ${dominio_ad^^}" > /etc/krb5.conf


#Configura o NSSWITCH - /etc/nsswitch.conf
if [ ! -f /etc/nsswitch.conf.bkp ]; then
cp /etc/nsswitch.conf /etc/nsswitch.conf.bkp
fi

echo "passwd:         compat winbind
group:          compat winbind
shadow:         compat
gshadow:        files

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis" > /etc/nsswitch.conf

#Para os servicos e syncroniza a hora entre o OMV com o AD
(
c=5
while [ $c -ne 15 ]
    do
        echo $c
        echo "###"
        echo "$c %"
        echo "###"
        ((c+=45))
        sleep 1


echo $c
        echo "###"
        echo "$c %"
        echo "###"
        ((c+=90))
        sleep 1
        ntpdate -u a.ntp.br >> $log_file

break
done
) |
whiptail --title "Sincronizar data e hora entre os servidores" \
         --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
         --gauge "Sincronizando data e hora entre os servidores. Aguarde...." 10 60 0

#Faz backup do arquivo config.xml original
if  [ ! -f /etc/openmediavault/config.xml.bkp ]; then
cp /etc/openmediavault/config.xml /etc/openmediavault/config.xml.bkp
else
cat /etc/openmediavault/config.xml.bkp > /etc/openmediavault/config.xml
fi

#### Gera o arquivo smb customizado para integracao
echo "<extraoptions> security = ads
realm = ${dominio_ad^^}
client signing = yes
client use spnego = yes
kerberos method = secrets and keytab
obey pam restrictions = yes
protocol = SMB3
netbios name = ${hostname_samba^^}
password server = *
encrypt passwords = yes
winbind uid = 10000-20000
winbind gid = 10000-20000
winbind enum users = yes
winbind enum groups = yes
winbind use default domain = yes
winbind refresh tickets = yes
idmap config ${netbios_dc^^} : backend  = rid
idmap config ${netbios_dc^^} : range = 1000-9999
Idmap config *:backend = tdb 
idmap config *:range = 85000-86000 
template shell = /bin/sh
lanman auth = no
ntlm auth = yes
client lanman auth = no
client plaintext auth = No
client NTLMv2 auth = Yes </extraoptions>" > /tmp/smb.tmpl

#Variavel para coleta da linha da tag <extraoptions> do samba para a escrita posterior pelo sed
line_filter=$(cat /etc/openmediavault/config.xml |grep -n homesbrowseable |cut -d: -f1)
line_edit=$(($line_filter+1))
sed -i "$line_edit d" /etc/openmediavault/config.xml &>/dev/null

#Inverte as linhas do arquivo smb customizado para o while escrever corretamente
tac /tmp/smb.tmpl > /tmp/smb.extra

#Escreve as linhas do SMB customizado dentro do arquivo config.xml na tag <extraoptions> do samba
while read linha
do
sed  -i "/homesbrowseable/a ${linha}" /etc/openmediavault/config.xml &>/dev/null
done < /tmp/smb.extra
rm -rf /tmp/smb.extra
rm -rf /tmp/smb.tmpl

#Ativa o serviço samba se estiver desativado
#Captura a linha <smb> para troca da linha posterior
line_smb=$(cat /etc/openmediavault/config.xml |grep -n "<smb>" |cut -d: -f1)
line_edit_smb=$(($line_smb+1))
sed -i "$line_edit_smb s/.*/<enable>1<\/enable>/" /etc/openmediavault/config.xml &>/dev/null

#Substitui o atual WorkGroup pelo do AD
#Captura a linha e troca os dados da linha
line_workgroup=$(cat /etc/openmediavault/config.xml |grep -n "<workgroup>" |cut -d: -f1)
sed -i "$line_workgroup s/.*/<workgroup>${netbios_dc^^}<\/workgroup>/" /etc/openmediavault/config.xml &>/dev/null

#Comandos para replicar as configuracoes para o SAMBA
omv-salt deploy run samba &>/dev/null

#Inicia teste de comunicacao entre os servers (PING no DNS)
clear
echo -e "\033[01;32m#####################################################################\033[01;37m"
echo -e "\033[01;32m## Testando o PING no nome do servidor AD informado, aguarde.... ####\033[01;37m"
echo -e "\033[01;32m#####################################################################\033[01;37m"
ping -q -c3 ${hostname_ad,,}.${dominio_ad,,} &>/dev/null

if [ $? -eq 0 ] ; then

        whiptail --title "Teste de Comunicacao de (DNS)" \
		         --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
                 --msgbox "O PING no nome do servidor AD foi bem sucessido, pressione OK para prosseguir." \
 				 --fb 10 50
else

        whiptail --title "Teste de Comunicacao de (DNS)" \
		         --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
                 --msgbox "O PING no nome do servidor AD nao foi possivel. Revise as configuracoes de rede e execute novamente o script." \
				 --fb 20 50
     exit
fi

#Informa a Senha do usario com direitos de administrador
admin_user=$(whiptail --title "Usuario do Active Directory" \
                      --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
                      --inputbox "Informe o usuario com direitos de Administrador do Active Directory:" \
 					  --fb 10 60 3>&1 1>&2 2>&3)
while [ ${#admin_user} = 0 ]; do
[ $? -ne 0 ] & exit
       done

#Informa a Senha do usuário com direitos de administrador
admin_pass=$(whiptail --title "Senha do usuario do Active Directory" \
                      --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
                      --passwordbox "Digite a senha do usuario:" \
					  --fb 10 60 3>&1 1>&2 2>&3)
while [ ${#admin_pass} = 0 ]; do
[ $? -ne 0 ] & exit
       done
	   
(
c=5
while [ $c -ne 20 ]
    do
        echo $c
        echo "###"
        echo "$c %"
        echo "###"
        ((c+=30))
        sleep 1
        net ads join -U$admin_user%$admin_pass --request-timeout 10 &>/dev/null

echo $c
        echo "###"
        echo "$c %"
        echo "###"
        ((c+=60))
        sleep 1
		systemctl restart smbd && systemctl restart nmbd &>/dev/null
		
echo $c
        echo "###"
        echo "$c %"
        echo "###"
        ((c+=80))
        sleep 1
		/etc/init.d/winbind restart &>/dev/null
	
break
done
) |
whiptail --title "Integracao dos Servidores" \
         --backtitle "SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY"	       \
         --gauge "Aguarde os servidores serem integrados e sincronizados ...." 10 60 0 


#Inicia teste da Integracao
clear
echo -e "\033[01;32m############################################################\033[01;37m"
echo -e "\033[01;32m### Testando a integracao dos servidores, aguarde......  ###\033[01;37m"
echo -e "\033[01;32m############################################################\033[01;37m"
sleep 5
testjoin=$(net ads testjoin | cut -f3 -d " ")

if  [ $testjoin = OK ] ; then
        whiptail --title "Teste de Integracao" \
				 --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY - EDUARDO JONCK'	       \
                 --msgbox "Integracao dos servidores realizada com sucesso.\n\nPressione OK para sar." \
				 --fb 20 50
		clear
		systemctl restart openmediavault-engined
else

        whiptail --title "Teste de Integracao" \
			     --backtitle 'SCRIPT DE INTEGRACAO DO OPENMEDIAVAULT AO ACTIVE DIRECTORY'	       \
		         --msgbox "A integracao dos servidores falhou. Favor executar o script novamente e revise suas respostas." \
				 --fb 20 50
  exit
fi

#Fecha o if inicial da tela de boas vindas.
	else
 exit
fi
