# EyediaTech Website

Personal brand site for `www.eyediatech.com` with three sections:
- Home
- Products
- Blog (3 starter posts)

This repository is intentionally separate from Eyedeea Photos.

## Tech

- Vite
- TypeScript
- Static frontend (no backend required)

## Local development

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
```

Output is generated in `dist/`.

## Contact

- support@eyediatech.com

## Deployment

See [docs/GCP_STATIC_DEPLOY.md](docs/GCP_STATIC_DEPLOY.md).

## VM Deploy (SSH/SCP Pattern)

Scripts are available in [scripts/deploy-hetzner.ps1](scripts/deploy-hetzner.ps1) and [scripts/vm-deploy-hetzner.sh](scripts/vm-deploy-hetzner.sh).

Run from Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-hetzner.ps1 \
	-VmHost "<your-vm-ip-or-hostname>" \
	-Domain "<primary-domain>" \
	-DomainAlias "<optional-domain-alias>" \
	-SshKeyPath "<path-to-your-private-key>" \
	-WithSsl \
	-CertbotEmail "<your-email>"
```

Default app upstream port is `8090` (matching [docker-compose.yml](docker-compose.yml)).
