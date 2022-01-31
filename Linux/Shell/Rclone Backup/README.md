Esse script tem por finalidade, fazer o backup com o recurso do RClone https://rclone.org/

O script foi escrito em Shell + Python, para que seja centralizado tudo em um único script, para os jobs de backups e envio de emails.

Após o Rclone configurado, para a conexão em sua origem e destino, basta usar o arquivo de configuração template chamado job.conf, alterando os dados em que o script rclone-backup irá ler para executar o backup e envio de emails.
