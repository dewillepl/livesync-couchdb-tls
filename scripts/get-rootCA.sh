#!/bin/bash
# rootCA export 

container=$1
docker cp $container:/certs/rootCA_Win.crt ./
docker cp $container:/certs/rootCA_Apple.der ./
docker cp $container:/certs/rootCA_Android.crt ./
/usr/bin/tar czf livesync-rootCA.tar.gz rootCA_Win.crt rootCA_Apple.der rootCA_Android.crt
