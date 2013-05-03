Providers and types in lib/ from 

https://github.com/puppetlabs/puppetlabs-rabbitmq

You also need to generate your own SSL keys

Put them in :

```
files/ssl/cacert.pem
files/ssl/server_cert.pem
files/ssl/server_key.pem
```

You can generate the CA and the key with helper scripts from

git://github.com/joemiller/joemiller.me-intro-to-sensu.git

```
git clone git://github.com/joemiller/joemiller.me-intro-to-sensu.git
cd joemiller.me-intro-to-sensu/
./ssl_certs.sh clean
./ssl_certs.sh generate
```


