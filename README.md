Greetings from Encryption Consulting, this is the Updated Documentation of the Employee Portal..
Verifying Changes, successful or not.

# docs-dummy staging deployment

This repository is a safe staging replica of the planned documentation deployment. It publishes a small static site to the Ubuntu staging VM through the self-hosted GitHub Actions runner.

## Workflow behavior

- A push to `main` runs the build and deployment workflow.
- A `repository_dispatch` event named `documentation_updated` runs the same workflow when the companion documentation repository changes.
- Each deployment is stored under `/var/www/docs-dummy/releases/<release-id>`.
- The `current` symlink is switched atomically to the new release.
- `http://127.0.0.1/health` is checked after the switch.
- If the check fails, the previous `current` symlink is restored.
- The five newest releases are retained.

## Required GitHub configuration

Add these repository secrets to `docs-dummy`:

| Secret | Value |
|---|---|
| `STAGING_HOST` | `10.0.0.150` or the staging DNS name |
| `STAGING_USER` | `kashish` initially; a dedicated deploy user is better later |
| `STAGING_SSH_KEY` | The private key used only by the runner; never commit it |
| `STAGING_KNOWN_HOSTS` | The verified SSH host-key line for the staging VM |

The runner must have the labels `self-hosted`, `linux`, `x64`, and `docs-deploy`. If its label differs, update `runs-on` in `.github/workflows/main.yml`.

## One-time staging VM setup

Run these commands on the VM after Nginx is installed:

```bash
sudo mkdir -p /var/www/docs-dummy/releases
sudo chown -R kashish:kashish /var/www/docs-dummy
sudo tee /etc/nginx/sites-available/docs-dummy >/dev/null <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/docs-dummy/current;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
sudo ln -sfn /etc/nginx/sites-available/docs-dummy /etc/nginx/sites-enabled/docs-dummy
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

The deployment user must be able to write `/var/www/docs-dummy`. The workflow intentionally does not use password prompts.
