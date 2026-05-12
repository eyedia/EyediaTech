# EyediaTech Website

Personal brand site for `www.eyediatech.com` built as a static multi-page website:
- Home at `/`
- Products at `/products/`
- Blog home at `/blog/`
- First published post at `/blog/beyond-the-megapixels.html`

This repository is intentionally separate from Eyedeea Photos.

## Tech

- Vite
- TypeScript
- Static frontend (no backend required)
- Shared assets and additional HTML pages served from `public/`

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
	-SshKeyPath "<path-to-your-private-key>"
```

This default command preserves existing HTTPS when certificates already exist on the VM.

For first-time certificate issuance:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-hetzner.ps1 \
	-VmHost "<your-vm-ip-or-hostname>" \
	-Domain "<primary-domain>" \
	-DomainAlias "<optional-domain-alias>" \
	-SshKeyPath "<path-to-your-private-key>" \
	-WithSsl \
	-DeployCert \
	-CertbotEmail "<your-email>"
```

To explicitly deploy without SSL:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-hetzner.ps1 \
	-VmHost "<your-vm-ip-or-hostname>" \
	-Domain "<primary-domain>" \
	-DomainAlias "<optional-domain-alias>" \
	-SshKeyPath "<path-to-your-private-key>" \
	-ForceHttp
```

Default app upstream port is `8090` (matching [docker-compose.yml](docker-compose.yml)).
