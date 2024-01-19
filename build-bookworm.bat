@echo off
packer build -except="vagrant-cloud" -var "version=1.1.0" -var-file="debian-12.4-amd64.json" .\lamp.json
