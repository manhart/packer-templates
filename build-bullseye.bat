@echo off
packer build -except="vagrant-cloud" -var "version=1.0.5" -var-file="debian-11.7-amd64.json" .\lamp.json
