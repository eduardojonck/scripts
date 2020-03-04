import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEBase import MIMEBase
from email import encoders
 
fromaddr = "conta_gmail"
toaddr = "conta_destinatario"
 
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
 
server = smtplib.SMTP('smtp.gmail.com', 587)
server.starttls()
server.login(fromaddr, "senha_gmail")
text = msg.as_string()
server.sendmail(fromaddr, toaddr, text)
server.quit()