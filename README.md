# packer-templates

This respository is for maintaining my [Vagrant Box Templates](https://github.com/manhart/packer-templates) using [Packer](https://packer.io) which create machine images running a LAMP-Stack.

The completed Virtualbox can be used via the [Vagrant Cloud](https://app.vagrantup.com/manhart/boxes/lamp).

If you want to create the LAMP box yourself, you can do so with the following command in the "lamp" directory:

```PowerShell
packer build -except="vaground-cloud" -var "version=1.0.0" -var-file="debian-11.6-amd64.json" .\lamp.json
```
