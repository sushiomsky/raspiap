#/bin/bash
FTPU="" # ftp login name
FTPP="" # ftp password
FTPS="" # remote ftp server
FTPF="pi/backup/" # remote ftp server directory for $FTPU & $FTPP

tar -cf /tmp/backup.tar /etc /usr /var /root /opt /bin /boot /home /lib /sbin 

ncftpput -m -R -u $FTPU -p $FTPP $FTPS  $FTPF /tmp/backup.tar
rm -f /tmp/backup.tar
#ncftpput -m -R -u $FTPU -p $FTPP $FTPS  $FTPF /root
#ncftpput -m -R -u $FTPU -p $FTPP $FTPS  $FTPF /var
#ncftpput -m -R -u $FTPU -p $FTPP $FTPS  $FTPF /usr
#ncftpput -m -R -u $FTPU -p $FTPP $FTPS  $FTPF /opt

