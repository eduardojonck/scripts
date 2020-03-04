#Script para envio de emails isando um servidor sem TLS como por exemplo EmailRelay.

#encoding: utf-8
import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEBase import MIMEBase
from email import encoders
 
fromaddr = "conta_email_origem"
toaddr = "conta_email_destino"
 
msg = MIMEMultipart()
 
msg['From'] = fromaddr
msg['To'] = toaddr
msg['Subject'] = "Assunto do E-mail"
 
body = "Mensagem no corpo do email"
 
msg.attach(MIMEText(body, 'plain'))
 
filename = "test.txt"
attachment = open("/tmp/test.txt", "rb")
 
part = MIMEBase('application', 'octet-stream')
part.set_payload((attachment).read())
encoders.encode_base64(part)
part.add_header('Content-Disposition', "attachment; filename= %s" % filename)
 
msg.attach(part)
 
server = smtplib.SMTP('127.0.0.1', 587)
text = msg.as_string()
server.sendmail(fromaddr, toaddr, text)
server.quit()
