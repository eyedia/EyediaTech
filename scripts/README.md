# Deploy Scripts

This folder contains the Hetzner deployment helpers for the EyediaTech site.

First-time SSL setup (requests certificate):

```powershell
.\scripts\deploy-hetzner.ps1 -VmHost "178.156.212.148" -Domain "eyediatech.com" -DomainAlias "www.eyediatech.com" -SshKeyPath "C:\Users\debjy\.ssh\do-eyedeea" -WithSsl -DeployCert -CertbotEmail "support@eyediatech.com" -EnvFile "F:\Synology\Home\Technical\EyedeeaPhotos\pilot\env_eyediatech_web.txt"
```

Routine deploy (keeps existing SSL/certificate automatically by reusing the active Nginx SSL config):

```powershell
.\scripts\deploy-hetzner.ps1 -VmHost "178.156.212.148" -Domain "eyediatech.com" -DomainAlias "www.eyediatech.com" -SshKeyPath "C:\Users\debjy\.ssh\do-eyedeea" -EnvFile "F:\Synology\Home\Technical\EyedeeaPhotos\pilot\env_eyediatech_web.txt"
```
