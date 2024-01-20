# packer-templates

This respository is for maintaining my [Vagrant Box Templates](https://github.com/manhart/packer-templates) using [Packer](https://packer.io) which create machine images running a LAMP-Stack.

If you want to create the LAMP box yourself, you can do so with the following command in the "lamp" directory:

```PowerShell
packer build -except="vaground-cloud" -var "version=1.0.0" -var-file="debian-12.4-amd64.json" .\lamp.json
```


The pre-built virtual machine (Virtualbox) is available on [Vagrant Cloud](https://app.vagrantup.com/manhart/boxes/lamp). To start the virtual machine you need [VirtualBox](https://www.virtualbox.org/wiki/Downloads) at least v7.0 and [Vagrant](https://developer.hashicorp.com/vagrant/downloads) at least v2. I recommend the latest version v2.4.1.

Use the pre-built virtual machine by changing to a directory such as dev.local and initialize the box with Vagrant:

```PowerShell
mkdir dev.local
cd dev.local
vagrant init -m manhart/lamp
vagrant up
```

The box uses symbolic links. Under Windows [this](https://superuser.com/questions/124679/how-do-i-create-a-link-in-windows-7-home-premium-as-a-regular-user#125981) has to be activated separately.

## Vagrantfile Options

The following optional variables are available in the Vagrantfile to customize the box:

```Ruby
VM_NAME = 'dev.local';
VM_IP = '192.168.56.11';
VM_SSH_PORT = '22022';
```
If you want to use more or different virtual hosts, you can add them to the Vagrantfile. The associated self-signed SSL/TLS certificates are also created for each VHost, e.g.:

```Ruby  
VM_CLEAR_HOSTS = true;
HOSTNAME = VM_NAME.split('.')[0];
VM_VHOSTS = [
    {
      "server_name": "#{HOSTNAME}.local",
      "server_alias": ["*.#{HOSTNAME}.local"],
      "document_root": "/virtualweb/#{HOSTNAME}.local",
      "enable_http": true,
      "enable_https": true,
      "env_vars": {
        "_RelativeRoot": "..",
        "_Stage": "develop",
        "_SQL_Host": "vagrant@localhost",
        "_DefaultSessionDuration": "14400"
      }
    },
    {
      "server_name": "app.local",
      "document_root": "/virtualweb/app.local",
      "enable_http": true,
      "enable_https": true,
      "env_vars": {
        "_RelativeRoot": "..",
        "_Stage": "develop",
        "_SQL_Host": "127.0.0.1",
        "_DefaultSessionDuration": "14400"
      }
    }
];
```

By default, the box is configured with the following user data:

Username: vagrant
Password: vagrant


## Installed Software

* Debian 12.4
* Apache 2.4.57
* PHP 8.3, 8.2, 8.1, 7.4 with Xdebug 3, sqlsrv, pdo_sqlsrv and a lot more
* MariaDB 10.11
* Composer 2.6.6
* Node.js 20.11
* MailCatcher 0.8.0
* phpMyAdmin 5.2.1
* mysqltuner 2.2.12