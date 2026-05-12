# Deploy Scripts

This folder contains the Hetzner deployment helpers for the EyediaTech site.

Run the deployment from the repository root on Windows:

```powershell
.\scripts\deploy-hetzner.ps1 -VmHost "178.156.212.148" -Domain "eyediatech.com" -DomainAlias "www.eyediatech.com" -SshKeyPath "C:\Users\debjy\.ssh\do-eyedeea" -WithSsl -DeployCert -CertbotEmail "support@eyediatech.com"
```

If you do not want to request SSL certificates during deployment, omit `-WithSsl`, `-DeployCert`, and `-CertbotEmail`.