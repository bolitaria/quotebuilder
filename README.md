# QuoteBuilder – AI‑Native Industrial Quote Engine

> **From spec to production with AI agents, Rails 8, and Hotwire.**

[![CI](https://github.com/bolitaria/quotebuilder/actions/workflows/ci.yml/badge.svg)](https://github.com/bolitaria/quotebuilder/actions/workflows/ci.yml)

**QuoteBuilder** simulates a real‑world tool for industrial safety equipment manufacturers.  
Sales teams configure products (barriers, bollards, rack protectors), get **live pricing**, generate **PDF quotes**, and send them to a **mock ERP** – all without page reloads.  
An optional **AI suggestion** recommends the best configuration for a given environment.

## 💼 Business logic

1. **Catalog** – Browse safety products with their base prices and options.
2. **Step‑by‑step configurator** – Choose colour, material, length… the total price updates instantly.
3. **Quote generation** – Fill in customer details and generate a professional PDF.
4. **ERP integration** – The quote is posted to a simulated external system (like SAP).
5. **AI recommendation** – Enter a context (“cold storage”, “high‑traffic”) and get a suggested configuration.

> This workflow replaces manual calculations and disconnected spreadsheets, reducing quoting time from hours to seconds.

## 🧱 Features

- **Turbo Frames** – catalog navigation without full‑page reloads.
- **Reactive configurator with Hotwire** – Turbo Streams + Stimulus update the summary and price at each step.
- **PDF generation** – Prawn creates a professional quote document.
- **Mock ERP service** – demonstrates webhook integration.
- **AI suggestion** – mock LLM service that returns a valid configuration.
- **Full test suite** – model specs, request specs, system tests with headless Chrome.
- **Professional CI/CD** – GitHub Actions runs tests, linting, security scans, and Docker build.
- **Security** – Brakeman, Bundler‑audit, path traversal prevention.

## 📦 Tech stack

| Layer          | Technology |
|----------------|------------|
| Backend        | Rails 8.1, Ruby 3.3 |
| Database       | PostgreSQL 16 |
| Frontend       | Hotwire (Turbo + Stimulus), Tailwind CSS 4 (loaded via CDN) |
| PDF engine     | Prawn |
| Background jobs| Solid Queue (inline for dev/test) |
| Testing        | RSpec, FactoryBot, Capybara, Shoulda Matchers, Selenium |
| Security       | Brakeman, Bundler‑audit |
| Linting        | RuboCop (Rails Omakase) |
| CI/CD          | GitHub Actions |
| Containers     | Docker, Docker Compose |

## 🚀 Quick start

### Prerequisites
- Ruby 3.3+ (rbenv recommended)
- PostgreSQL 16 (or Docker)
- Chrome/Chromium (for system tests)

### Local setup (with local PostgreSQL)

```bash
git clone https://github.com/bolitaria/quotebuilder.git
cd quotebuilder
bundle install
cp .env.example .env   # edit DATABASE_URL if needed
rails db:create db:migrate db:seed
rails server -p 3002
Visit http://localhost:3002.
Note: The application loads Tailwind CSS and Hotwire (Turbo + Stimulus) from CDNs, so no asset compilation is needed for the UI.

Docker (full stack)
bash
docker compose up --build
The app will be available at http://localhost:3000 (or the port you configure in docker-compose.yml).

🧪 Running tests
bash
bundle exec rspec
Important note about JavaScript system tests:
Tests that require JavaScript (type: :system, js: true) are automatically excluded locally because they need a fully‑precompiled asset environment and a properly‑configured headless Chrome.
They are run only in CI (GitHub Actions) where the environment is guaranteed.
If you need to run them locally:

bash
CI=true bundle exec rspec
The full suite contains 39 examples. Locally you will see 36 (model specs + the rack‑test catalog system spec). CI runs all 39.

🔁 CI pipeline
On every push/PR to main or development, GitHub Actions:

Runs database migrations (db:migrate) without seeds.

Precompiles assets (for CSS/JS in test environment).

Executes the full test suite (including JS system specs).

Scans for vulnerabilities (Brakeman + Bundler‑audit).

Enforces code style (RuboCop Rails Omakase).

Builds the Docker image.

All checks must pass before merging.

🤖 AI‑native development workflow
This project follows a spec‑driven, AI‑assisted process that matches A‑SAFE Digital’s philosophy:

Write a spec – a detailed Markdown file describing the feature, edge cases, and tests.

Agent generates code – Claude or Cursor implements the spec.

Human review – I inspect every line, add security hardening, adjust architecture, and verify tests pass.

Commit & CI – the pipeline validates everything automatically.

Every feature is reproducible via the numbered shell scripts in scripts/.

Example: scripts/001_data_model.sh builds the complete data layer and its tests with a single command.

📁 Project structure (simplified)
text
├── app
│   ├── controllers
│   │   ├── ai_suggestions_controller.rb
│   │   ├── configurations_controller.rb
│   │   ├── products_controller.rb
│   │   └── quotes_controller.rb
│   ├── jobs/quote_generator_job.rb
│   ├── models/(product, quote, option_group, option_value, quote_item)
│   └── services
│       ├── ai_suggester_service.rb
│       └── erp_service.rb
├── spec
│   ├── factories/
│   ├── models/
│   └── system/
│       ├── ai_suggestion_spec.rb
│       ├── product_catalog_spec.rb
│       ├── product_configurator_spec.rb
│       └── quote_generation_spec.rb
├── scripts/            # Specs and setup scripts
├── docker-compose.yml
├── Dockerfile
└── .github/workflows/ci.yml
🔮 Roadmap (optional enhancements)
Authentication (Devise) – Add login and role management so each salesperson has their own dashboard.

Admin dashboard – Allow product managers to create, edit, and organise products, and view quote analytics.

Real ERP integration with webhook signatures – Connect to a live ERP using HMAC signature verification to guarantee request authenticity.

Cloud deployment – The app is already fully Dockerized; it can be deployed to Fly.io, Render, or any cloud platform with a single command.

📖 Runbook
First‑time setup
Clone the repository.

Install dependencies: bundle install

Configure the database:

If using local PostgreSQL, ensure the service is running and adjust config/database.yml.

If using Docker, run docker compose up -d db.

Create and seed the database: rails db:create db:migrate db:seed

Start the server: rails server -p 3002

Daily startup
bash
docker start quotebuilder-postgres  # or start your local PostgreSQL service
rails server -p 3002
Running tests
Without JS: bundle exec rspec

With JS (local): CI=true bundle exec rspec

Updating dependencies
bash
bundle update
rails db:migrate
Troubleshooting
Styles not showing

The application loads Tailwind from CDN, so make sure your layout includes <script src="https://cdn.tailwindcss.com"></script>.

If you modified the layout, check that the CDN script is present.

Hard‑refresh the browser (Ctrl+Shift+R).

Buttons don’t respond (no interactivity)

Open the browser developer tools (F12) → Console. If you see Turbo is not defined, Hotwire scripts are missing.

Ensure the layout has the unpkg scripts for Turbo and Stimulus.

Restart the server and hard‑refresh.

