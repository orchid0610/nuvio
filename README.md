# nuvio

One-command web development environment setup for fresh Linux installs.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/orchid0610/nuvio/main/bootstrap.sh | bash
```

## What it sets up

- PHP (multiple versions via ondrej/php PPA on Ubuntu)
- Nginx
- MySQL
- phpMyAdmin (Ubuntu/Debian only)
- `new-site` CLI tool — instantly scaffold a local `.test` vhost

## Configuration

Edit `config/settings.env` before running:

```env
USERNAME=orchid
ROOT_FOLDER=www

NGINX_INSTALL=true
MYSQL_INSTALL=true
PHPMYADMIN_INSTALL=true
PHP_INSTALL=true

PHP_VERSIONS="8.1 8.2 8.3"
```

## Project structure

```
nuvio/
├── bootstrap.sh              # curl | bash entry point
├── setup.sh                  # main orchestrator
├── config/
│   └── settings.env          # your configuration
├── lib/
│   ├── log.sh                # logging helpers
│   ├── pkg.sh                # package manager abstraction
│   └── config.sh             # config loader & validator
├── modules/
│   ├── core/system.sh        # system update
│   ├── packages/php.sh       # PHP multi-version install
│   ├── services/nginx.sh
│   ├── services/mysql.sh
│   ├── services/phpmyadmin.sh
│   └── scripts/new-site-installer.sh
└── bin/
    └── new-site              # standalone CLI tool
```

## Adding a new module

1. Create `modules/category/tool.sh`
2. Add `run_module category/tool` to `setup.sh`
3. Use `pkg_install`, `pkg_installed`, `run_quiet`, `section`, `status_done` etc. from the libs

## new-site usage

After setup, create a local project vhost:

```bash
sudo new-site my-project
# → http://my-project.test
```

Expects `~/www/my-project/public/` to exist.