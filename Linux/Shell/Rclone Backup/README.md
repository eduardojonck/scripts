Esse script tem por finalidade, fazer o backup com o recurso do RClone https://rclone.org/

O script foi escrito em Shell + Python, para que seja centralizado tudo em um único script, excutando os jobs de backups e envio de emails.

Após o Rclone configurado, para a conexão em sua origem e destino dos backups, basta usar o arquivo de configuração template chamado job.conf, alterando os dados em que o script rclone-backup irá ler para executar o backup e envio de emails.

Exemplo de comando: rclone-backup -c backup-origem-destino.conf

Cada arquivo de configuração, é um job de backup, sendo esse, podendo ser agendado no cron do seu sistema operacional para ser executado no tempo que você desejar.
