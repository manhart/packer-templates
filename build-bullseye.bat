@echo off
packer build -except="vagrant-cloud" -var "version=1.0.7" -var-file="debian-11.8-amd64.json" .\lamp.json