# packer-templates

This respository is for maintaining my [Vagrant Box Templates](https://github.com/manhart/packer-templates) using [Packer](https://packer.io) which create machine images running a LAMP-Stack.

If you want to create the LAMP box yourself, you can do so with the following command in the "lamp" directory:

```PowerShell
packer build -except="vaground-cloud" -var "version=1.0.0" -var-file="debian-11.6-amd64.json" .\lamp.json
```


The pre-built virtual machine (Virtualbox) is available on [Vagrant Cloud](https://app.vagrantup.com/manhart/boxes/lamp). To start the virtual machine you need [VirtualBox](https://www.virtualbox.org/wiki/Downloads) at least v6.1.40 and [Vagrant](https://developer.hashicorp.com/vagrant/downloads) at least v2

Use the pre-built virtual machine by changing to a directory such as dev.local and initialize the box with Vagrant:

```PowerShell
mkdir dev.local
cd dev.local
vagrant init -m manhart/lamp
vagrant up
```

The box uses symbolic links. Under Windows [this](https://superuser.com/questions/124679/how-do-i-create-a-link-in-windows-7-home-premium-as-a-regular-user#125981) has to be activated separately.
