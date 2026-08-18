# 📧 MailNexa – AI-Powered Campus Placement Assistant

[![Flutter](https://img.shields.io/badge/Flutter-3.19-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-v18+-339933?logo=nodedotjs)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?logo=mongodb)](https://mongodb.com)
[![Google Gemini AI](https://img.shields.io/badge/Google_Gemini_AI-1.5_Flash-4285F4?logo=google)](https://aistudio.google.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**MailNexa** is an executive full-stack mobile application and AI-driven backend engine specifically engineered for university students to solve email overload during campus placement drives.

The platform integrates **Google Gmail API (OAuth 2.0)** to fetch incoming academic emails, executes automated **Google Gemini AI text classification**, performs **deterministic attachment scanning (.xlsx / .pdf)** for student identifiers, generates clean 3-4 bullet executive summaries, and presents priority feeds, application stage timelines, and deadline countdowns in a stunning **Flutter mobile application**.

---

## 🔥 Key Features & Capabilities

### 1. 🤖 AI Priority Classification & Bullet Summaries
* **Smart Categorization**: Routes incoming emails into `Placement`, `Academic`, or `Promotions` with `High`, `Medium`, or `Low` priority ratings.
* **Clean Bullet Points**: Generates 3-4 formal, action-oriented bullet points (`• `) summarizing key requirements, test dates, and action items without emojis or markdown clutter.

### 2. 📑 Deterministic Shortlist Verification (0 False Positives)
* **Hybrid Verification Engine**: Eliminates false shortlist alerts by downloading and parsing attached Excel spreadsheets (`.xlsx`) and PDFs (`.pdf`).
* **Identifier Matching**: Strictly verifies if the student's Registration Number or Campus ID appears in text or attachments before flagging an email as `Shortlisted`.

### 3. 💼 Application Stage Tracker & Timeline Stepper
* **Visual Pipeline**: Tracks company application selection stages (`Applied` ➔ `Online Test` ➔ `Interview` ➔ `Offer` / `Rejected`).
* **Deduplicated History**: Maintains clean timeline logs with timestamps and prep notes.

### 4. ⏰ Deadline Countdowns & Reminders
* **Action-Item Extraction**: Automatically identifies test submission deadlines and interview schedules from email text.
* **1-Tap Reminders**: Populates the Deadlines manager with custom alerts.

### 5. 🛡️ Noise Interception & Strict 250-Email Storage Cap
* **Promotions Interceptor**: Intercepts course spam (e.g. NPTEL, Kaggle) into low-priority feeds with zero push alerts.
* **Rolling Storage Cap**: Automatically prunes MongoDB data to maintain a maximum of 250 active emails per user for sub-50ms API response times.

### 6. 🔄 Network Resilience & Bi-Directional Fallback
* **Dio Fallback Interceptor**: Mobile app automatically switches between ADB localhost port forwarding (`127.0.0.1:5000`) and host Wi-Fi IP if network connection drops.

---

## 🛠️ Technology Stack

| Layer | Technologies & Tools |
|---|---|
| **Mobile Client** | Flutter 3.19 (Dart 3.3), Material 3 Design, Riverpod 2.6, Dio HTTP Client, GoRouter |
| **Backend API** | Node.js (v18+), Express.js (REST API), Vercel Serverless Runtime |
| **Database** | MongoDB Atlas Cloud Database, Mongoose ODM with indexing & pre-save hooks |
| **AI & NLP Engine** | Google Gemini Flash 1.5 LLM (`@google/generative-ai`) with deterministic prompts |
| **Document Parsers** | `xlsx` (Excel Sheet-to-CSV Buffer Stream), `pdf-parse` (PDF Stream Extractor) |
| **Authentication & Security** | Google OAuth 2.0 PKCE, 256-bit AES Token Encryption, JWT Refresh Token Rotation, Helmet |

---

## 🔌 API Endpoint Reference

| Endpoint Route | Method | Functionality Description |
|---|---|---|
| `/api/auth/demo-login` | `POST` | Development email authentication & JWT token generation |
| `/api/auth/google` | `POST` | Google OAuth 2.0 authorization code exchange |
| `/api/emails` | `GET` | Fetches filtered email list (`isShortlisted`, `priority`, `category`) |
| `/api/emails/:id` | `GET` | Fetches single email with AI auto-summary & attachment analysis |
| `/api/applications` | `GET` | Fetches user job applications |
| `/api/applications/grouped` | `GET` | Groups applications by status (`Applied`, `Interview`, `Offer`, `Rejected`) |
| `/api/applications/:id/status` | `PATCH` | Updates application selection stage with deduplicated history |
| `/api/deadlines` | `GET` | Fetches upcoming test deadlines and interview reminders |
| `/api/analytics/dashboard` | `GET` | Fetches dashboard summary statistics and category counts |

---

## 📂 Repository Directory Structure

```
MailNexa/
├── server/                        # Node.js Express Backend API
│   ├── config/                    # Database, Gemini AI, OAuth & Firebase Configs
│   ├── controllers/               # Express Route Handlers (Auth, Emails, Applications, Analytics)
│   ├── middleware/                # JWT Auth, Rate Limiters, Error Handlers, CORS
│   ├── models/                    # MongoDB Mongoose Schemas (Email, User, Application, Deadline)
│   ├── routes/                    # API Route Definitions (/api/auth, /api/emails, etc.)
│   ├── services/                  # Gemini AI, Attachment Parser, Sync & Notification Services
│   ├── package.json               # Backend Dependencies
│   ├── vercel.json                # Vercel Cloud Serverless Deployment Config
│   └── server.js                  # Express Server Entry Point
├── mobile/                        # Flutter Cross-Platform Mobile Application
│   ├── android/                   # Native Android Configuration & Manifest
│   ├── lib/
│   │   ├── core/                  # Design Tokens, Dio ApiClient with Fallback Interceptors, Router
│   │   └── features/
│   │       ├── applications/      # Application Stage Tracker & Stepper Timeline
│   │       ├── auth/              # Splash, Onboarding & Authentication Screens
│   │       ├── dashboard/         # Executive Analytics Metrics & High Priority Feed
│   │       ├── deadlines/         # Countdown & Reminder Manager
│   │       ├── inbox/             # Smart Inbox, Filters & Detail Summary View
│   │       └── settings/          # Campus Profile & Custom AI Prompt Manager
│   └── pubspec.yaml               # Flutter Package Dependencies
├── README.md                      # Project GitHub Markdown Documentation
└── requirements.txt               # Dependencies & Environment Specifications
```

---

## ⚙️ Environment Setup (`server/.env`)

Create a `.env` file inside the `server/` directory:

```ini
NODE_ENV=development
PORT=5000

# MongoDB Cloud Connection
MONGODB_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/mailguard?retryWrites=true&w=majority

# JWT & Security Secrets
JWT_SECRET=your_super_secret_jwt_key_minimum_64_characters
JWT_EXPIRES_IN=15m
JWT_REFRESH_SECRET=your_super_secret_refresh_key_min_64_chars
JWT_REFRESH_EXPIRES_IN=7d
ENCRYPTION_KEY=your_32_character_encryption_key

# Google OAuth 2.0 & Gemini AI
GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_REDIRECT_URI=postmessage
GEMINI_API_KEY=your_gemini_api_key_from_aistudio
GEMINI_MODEL=gemini-3.5-flash-lite
```

---

## 🚀 Quick Start & Deployment

### 1. Run Backend Server
```bash
cd server
npm install
npm start
```

### 2. Run Mobile Application
```bash
cd mobile
flutter pub get
flutter run
```

### 3. Build Standalone Release APK
```bash
cd mobile
flutter build apk --release
```

---

## 🛡️ Privacy & Security
All confidential environment variables (`.env`), Google OAuth keys, and private credentials are strictly excluded from source control via `.gitignore`. Users configure their own Registration Number and Campus ID in the app **Settings Screen**.

---

## 📄 License
This project is licensed under the MIT License.
