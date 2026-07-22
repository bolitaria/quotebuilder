# Guía para crear un proyecto Rails 8 + Hotwire + Testing + Seguridad desde cero en WSL

> Requisito: Windows 10/11 con WSL2 (Ubuntu) y Docker Desktop instalado (o Ruby nativo).

---

## 1. Crear el esqueleto con Docker (opción recomendada, evita instalar Ruby si no lo tienes)

```bash
cd ~
docker run -it --rm -v $(pwd):/app -w /app ruby:3.3 bash -c "
  gem install rails -v '~> 8.0' &&
  rails new quotebuilder --database=postgresql --skip-test --skip-action-mailbox --skip-action-mailer --skip-action-text --skip-active-storage --skip-action-cable --css=tailwind --javascript=importmap --force
"

# Cambia "quotebuilder" por el nombre de tu proyecto.
Si Docker no funciona, instala Ruby nativo (ve al paso 2) y luego:

rails new quotebuilder --database=postgresql --skip-test --skip-action-mailbox --skip-action-mailer --skip-action-text --skip-active-storage --skip-action-cable --css=tailwind --javascript=importmap
# 2. Corregir permisos (Docker crea los archivos como root)

sudo chown -R $USER:$USER ~/quotebuilder
cd ~/quotebuilder
3. Instalar Ruby nativo (necesario para usar bundle, rails, etc.)
Si no tienes Ruby instalado en WSL, sigue estos pasos. Si ya lo tienes (ej. vía rbenv), sáltate esta sección.


# Dependencias
sudo apt update
sudo apt install -y git curl libssl-dev libreadline-dev zlib1g-dev autoconf bison build-essential libyaml-dev libncurses5-dev libffi-dev libgdbm-dev libpq-dev

# Instalar rbenv y ruby-build
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Configurar shell
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
exec $SHELL

# Instalar Ruby 3.3.6
rbenv install 3.3.6
rbenv global 3.3.6

# Instalar Bundler y Rails
gem install bundler
gem install rails -v '~> 8.0'

# 4. Configurar Git y conectar con GitHub
git init
git add .
git commit -m "Initial commit: Rails 8 clean slate"
git branch -M main
git remote add origin https://github.com/tu-usuario/quotebuilder.git   # <-- cambia la URL
git push --force --set-upstream origin main