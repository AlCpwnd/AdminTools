w32tm /config /update /manualpeerlist:<Server FQDN> /syncfromflags:manual /reliable:yes
w32tm /resync /rediscover
w32tm /query /source