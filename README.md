# QuoteBuilder – AI‑Native Industrial Quote Engine

> **From spec to production with AI agents, Rails 8, and Hotwire.**

[![CI](https://github.com/bolitaria/quotebuilder/actions/workflows/ci.yml/badge.svg)](https://github.com/bolitaria/quotebuilder/actions/workflows/ci.yml)

**QuoteBuilder** simulates a real‑world tool for industrial safety manufacturers.  
Sales teams configure products (barriers, bollards, rack protectors), get **live pricing**, generate **PDF quotes**, and send them to a **mock ERP** – all without page reloads. An optional **AI suggestion** recommends the best configuration for a given environment.

## 💼 Business logic

1. **Catalog** – Browse safety products with their base prices and options.
2. **Step‑by‑step configurator** – Choose colour, material, length… the total price updates instantly.
3. **Quote generation** – Fill in customer details and generate a branded PDF.
4. **ERP integration** – The quote is posted to a simulated external system (like SAP).
5. **AI recommendation** – Enter a context (“cold storage”, “high‑traffic”) and get a suggested configuration.

> This workflow replaces manual calculations and disconnected spreadsheets, reducing quoting time from hours to seconds.

## 🧱 Features

- **Turbo Frames** – catalog navigation without full‑page reloads.
- **Turbo Streams + Stimulus** – reactive configurator with live price updates.
- **PDF generation** – Prawn creates a professional quote document.
- **Mock ERP service** – demonstrates webhook integration.
- **AI suggestion** – mock LLM service that returns a valid configuration.
- **Full test suite** – model specs, request specs, system tests with headless Chrome.
- **CI/CD pipeline** – GitHub Actions runs tests, linting, security scans, and Docker build.
- **Security** – Brakeman (with false‑positive ignore), Bundler‑audit.

## 📦 Tech stack

| Layer          | Technology |
|----------------|------------|
| Backend        | Rails 8.1, Ruby 3.3 |
| Database       | PostgreSQL 16 |
| Frontend       | Hotwire (Turbo, Stimulus), Tailwind CSS 4 |
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

Docker (full stack)
bash
docker compose up --build
The app will be available at http://localhost:3000 (or a different port if you change the mapping).

🧪 Running tests
bash
bundle exec rspec
System tests require Chrome. To run only model tests:

bash
bundle exec rspec spec/models
🔁 CI pipeline
On every push/PR to main or development, GitHub Actions performs:

Database migration verification (db:migrate)

Asset precompilation (Tailwind)

Full test suite (including JavaScript system specs)

Brakeman security scan

Dependency vulnerability check (Bundler‑audit)

RuboCop style check

Docker image build

All checks must pass before merging.

🤖 AI‑native development workflow
This project follows a spec‑driven, AI‑assisted process that matches the A‑SAFE Digital philosophy:

Write a spec – a precise Markdown file describing the feature, edge cases, and tests.

Agent generates code – Claude or Cursor creates the implementation.

Human review – I inspect every line, fix bugs, add security measures, and ensure correctness.

Commit & CI – the pipeline validates everything automatically.

Every feature is reproducible via the numbered shell scripts in scripts/.

Example: scripts/001_data_model.sh builds the entire data layer and its tests with a single command.

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



## 🔮 Roadmap (optional enhancements)

- **Authentication (Devise)** – Add login and role management so each salesperson has their own dashboard and quote history.
- **Admin dashboard** – Allow product managers to create, edit, and organise products, and view quote analytics.
- **Real ERP integration with webhook signatures** – Connect to a live ERP using HMAC signature verification to guarantee request authenticity.
- **Cloud deployment** – The app is already fully Dockerized; it could be deployed to Fly.io, Render, or any cloud platform with a single command.

