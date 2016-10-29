#!/bin/sh 

# Oct 2016 - This shell script will build the certificate chain for 
# freenode.net so your irssi client can verify the ssl connection. 
# The docs on the freenode site https://freenode.net/kb/answer/chat
# did not exactly work for me so I've posted this script to make the 
# process more convenient. You should have an entry in 
# your ~/.irssi/config that looks something like:
#
#  { 
#    address = "chat.freenode.net";   
#    chatnet = "freenode";    
#    port = "6697";
#    use_ssl = "yes";
#    ssl_verify = "yes";
#    ssl_cafile = "~/.irssi/freenodechain.pem";
#  }
#
# This script will build the freenodechain.pem file for you. It is 
# assumed that you have curl and a somewhat modern version of openssl in 
# your PATH; most MacOS and Linux systems have these as standard packages. 

GANDICERT=https://www.gandi.net/static/CAs/GandiStandardSSLCA2.pem 
USRTRUST=http://crt.usertrust.com/USERTrustRSAAddTrustCA.crt 
ADDTRUST=http://www.tbs-x509.com/AddTrustExternalCARoot.crt
FOUT=freenodechain.pem

function add_cert () {
   C=$1
   TP=$2
   if [ ! -z $TP ]; then
      curl $C | openssl x509 -inform der -outform pem >> $FOUT
   else
      curl $C >> $FOUT
   fi
}
echo -n "" > $FOUT
add_cert $GANDICERT
add_cert $USRTRUST 1
add_cert $ADDTRUST 
