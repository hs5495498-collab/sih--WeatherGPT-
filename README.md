> Smart India Hackathon 2026 submission by Team [Algo-Avengers]
> Final Presentation: **6 September 2026**

## 📌 Problem Statement

**PS ID:** SIH26068
**Title:** WeatherGPT: Conversational AI for Weather Forecasting, Alerts, and Climate Information
**Category:** Software
**Theme:** Space Technology / Disaster Management
**Sponsoring Ministry:** Ministry of Earth Sciences (MoES)

>  Note for ppt : The official portal (sih.gov.in) publishes the full background, detailed description, and expected-solution specification for this PS — only the title, ministry, and theme could be confirmed here. Please pull the exact wording from sih.gov.in and paste the "Background", "Description", and "Expected Solution" sections below before finalizing your PPT/report, since evaluators check for alignment with the official text.

### Background *(fill in from sih.gov.in)*
_[Paste the official background section here — context on why MoES needs a conversational AI weather assistant, gaps in current systems like Mausam/IMD services, etc.]_

### Detailed Description *(fill in from sih.gov.in)*
_[Paste the official detailed description here.]_

### Expected Solution *(fill in from sih.gov.in)*
_[Paste the official expected-solution bullet points here.]_

## 💡 Our Proposed Solution

WeatherGPT is a conversational AI assistant that lets users ask natural-language questions about weather forecasts, alerts, and climate information and get accurate, localized, easy-to-understand answers — grounded in real IMD/MoES data rather than generic responses.

_(Replace/expand this with your team's specific approach — architecture, unique differentiators, target users e.g. farmers/general public/disaster management officials, languages supported, etc.)_

**Core capabilities (typical for this PS — confirm against official spec):**
- Natural language Q&A about current weather, forecasts, and alerts for any Indian location
- Integration with IMD / Mausam data feeds (or public weather APIs during prototyping)
- Multilingual support for regional Indian languages
- Severe weather alert notifications in conversational form
- Historical/climate information lookups
- Simple, accessible interface (chat-based web/mobile)

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| Machine Learning / NLP | [e.g. Python, LangChain/RAG, LLM API or fine-tuned model, spaCy/NLTK] |
| Weather Data Source | [e.g. IMD/Mausam APIs, OpenWeatherMap for prototyping, NWP model outputs] |
| Backend | [e.g. Node.js + Express / Django / FastAPI] |
| Database | [e.g. PostgreSQL / MongoDB — for query logs, alerts, user locations] |
| Frontend | [e.g. React + Tailwind — chat interface] |
| Deployment | [e.g. Vercel / Render / AWS] |

## 📁 Folder Structure

```
weathergpt-sih/
├── ml/              # NLP/LLM pipeline, weather data processing, RAG/retrieval, model experiments
├── backend/         # APIs, chat orchestration, alert service, database models
├── frontend/        # Chat UI, alerts dashboard, components
├── docs/            # Problem statement, architecture diagrams, PPT, reports
└── README.md
```

## 👥 Team

| Name | Role | Branch |
|---|---|---|
| Chaitanya Goel | ML Engineer 1 | `ml/dev-1` |
| Kashish | ML Engineer 2 | `ml/dev-2` |
| Krish Agrwal | Backend Developer 1 | `backend/dev-1` |
| Ayush agrwal | Backend Developer 2 | `backend/dev-2` |
| Harsh kumar singh | Frontend / UI-UX Developer 1 | `frontend/dev-1` |
| Shaurya singh | Frontend / UI-UX Developer 2 | `frontend/dev-2` |

## 🌿 Branching Strategy

- `main` — stable, demo-ready code only. Protected.
- `develop` — integration branch where all feature branches merge first.
- `ml/dev-*`, `backend/dev-*`, `frontend/dev-*` — individual working branches per member.

**Workflow:**
```bash
git checkout develop
git pull origin develop
git checkout -b <your-branch-name>     # first time only
# ... make changes ...
git add .
git commit -m "feat: short description of change"
git push origin <your-branch-name>
```
Then open a Pull Request into `develop`. Do not push directly to `main`.

## 📝 Commit Message Convention

| Prefix | Use for |
|---|---|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation changes |
| `refactor:` | Code change that isn't a fix or feature |
| `chore:` | Setup, config, dependencies |

Example: `feat: add IMD weather API integration`

## ⚙️ Getting Started

### Prerequisites
- [Node.js vXX / Python vXX / etc.]
- API key(s) for weather data source and/or LLM provider (do not commit keys — use `.env`)

### ML
```bash
cd ml
pip install -r requirements.txt --break-system-packages
```

### Backend
```bash
cd backend
npm install
npm run dev
```

### Frontend
```bash
cd frontend
npm install
npm start
```

## 🗓️ Timeline

| Day | Date | Focus |
|---|---|---|
| Day 1 | 30 Aug 2026 | Kickoff, study PS68 spec, task allocation, environment setup |
| Day 2–6 | 31 Aug – 5 Sep 2026 | Core development sprint — NLP pipeline, weather data integration, chat UI, alerts |
| Day 7 | 6 Sep 2026 | **Final Presentation** |
