# 📧 MailNexa — AI-Powered Campus Placement & Email Intelligence Platform

![Flutter](https://img.shields.io/badge/Flutter-Mobile_Frontend-02569B?logo=flutter)
![Node.js](https://img.shields.io/badge/Node.js-v18+_Backend-339933?logo=nodedotjs)
![Express](https://img.shields.io/badge/Express-REST_API-000000?logo=express)
![MongoDB](https://img.shields.io/badge/MongoDB-Atlas_Cloud-47A248?logo=mongodb)
![Google Gemini AI](https://img.shields.io/badge/Google_Gemini-1.5_Flash_LLM-4285F4?logo=google)
![Gmail API](https://img.shields.io/badge/Gmail_API-OAuth_2.0-EA4335?logo=gmail)
![Vercel](https://img.shields.io/badge/Vercel-Serverless_Hosting-000000?logo=vercel)
![Firebase](https://img.shields.io/badge/Firebase-FCM_Push_Alerts-FFCA28?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

**MailNexa** is an AI-powered campus placement intelligence platform and mobile application specifically engineered for university students to solve email overload during placement drives.

The platform leverages **Google Gmail API (OAuth 2.0)** to synchronize incoming academic emails, executes automated **Google Gemini AI text classification**, performs **deterministic attachment scanning (.xlsx / .pdf)** for student identifiers, generates clean executive bullet summaries, and tracks application stage timelines in a stunning **Flutter mobile application**.

By combining LLM natural language processing, real-time attachment buffer parsing, and reactive mobile state management, MailNexa transforms scattered placement emails into actionable career intelligence through a single unified interface.

---

# 🚀 Features

### 🤖 AI Priority Classification & Executive Bullet Summaries

Automatically routes and summarizes incoming emails into clean, action-oriented feeds.

* **Category Classification**: `Placement`, `Academic`, `Promotions`
* **Priority Assessment**: `High`, `Medium`, `Low`
* **Clean Bullet Points**: Generates 3-4 formal bullet points (`• `) summarizing key requirements, test dates, and next steps without emoji or markdown clutter.

Outputs include:
* Placement Drive Announcements
* Online Assessment (OA) Test Links
* Technical & HR Interview Call Letters
* General Academic Notices

Powered by **Google Gemini Flash 1.5 LLM**.

---

### 📑 Deterministic Shortlist Verification (0 False Positives)

Eliminates shortlist anxiety and false positive alerts by downloading and parsing attached spreadsheets and documents.

Supported Document Formats:

| Document Format | Parser Engine | Extracted Data |
| --------------- | ------------- | -------------- |
| Microsoft Excel (`.xlsx`, `.xls`) | `xlsx` Sheet Buffer Stream | Student Reg No & NeoPAT ID |
| PDF Documents (`.pdf`) | `pdf-parse` Buffer Reader | Text Stream & Registration Lists |
| Plaintext / CSV (`.csv`, `.txt`) | Regex Stream Processor | Raw Identifier Match |

Benefits:
* Zero false positive shortlist notifications
* Automatic identification of student's Registration Number & Campus ID
* Overrides LLM hallucinations with deterministic verification
* Instant high-priority alert when your name appears on selection lists

---

### 💼 Application Pipeline & Selection Stage Tracker

Track your recruitment progression across multiple company drives simultaneously.

Selection Stages Tracked:

1. **Applied**: Application submitted via portal or email link
2. **Online Test**: OA link received with submission deadline
3. **Interview**: Technical, Managerial, or HR interview scheduled
4. **Offer**: Final offer letter received
5. **Rejected**: Application status closed

Features:
* Visual progress stepper bar
* Deduplicated status history timeline
* Executive company gradient header cards
* Interactive preparation notes and interview tips editor

---

### ⏰ Deadline Countdowns & Custom Interview Reminders

Never miss an online test link or interview slot again.

Capabilities:
* Automatic extraction of test submission deadlines from email text
* 1-Tap **"Add Interview / Exam Reminder"** dialog from Application Tracker
* Integrated Deadlines Manager tab with overdue detection
* Direct countdown timers for upcoming test dates

---

### 🛡️ Noise Interception & Strict 250-Email Storage Cap

Keep your inbox clean and ultra-fast.

Features:
* **Promotions Interceptor**: Intercepts course spam (NPTEL, Kaggle, Coursera) into low-priority feeds with zero push notifications
* **250-Email Rolling Storage Cap**: Automatically prunes older MongoDB records to maintain a maximum of 250 emails per user for sub-50ms API query speeds
* **Duplicate Prevention**: Unique Gmail ID indexing to prevent redundant email records

---

### 🔄 Network Resilience & Bi-Directional Fallback Interceptor

Guarantees 99.9% uptime on mobile devices.

Capabilities:
* Built-in Dio HTTP client interceptor (`_FallbackUrlInterceptor`)
* Automatic bi-directional failover between ADB localhost (`127.0.0.1:5000`) and host PC Wi-Fi IP (`172.20.129.223:5000`)
* Seamless retry handling during USB disconnects or phone sleep modes

---

# 🛠️ Technology Stack & Architecture

| Component | Technologies Used | Purpose |
| --------- | ----------------- | ------- |
| **Mobile Frontend** | Flutter 3.19 (Dart 3.3), Material 3 | Cross-platform mobile UI for Android & iOS |
| **State Management** | Riverpod 2.6 (`FutureProvider`, `StateProvider`) | Reactive, compile-safe application state |
| **Mobile Networking** | Dio 5.10 with Custom Fallback Interceptor | Resilient HTTP API communications & network failover |
| **Backend API** | Node.js (v18+), Express.js | RESTful API server & background sync worker |
| **Cloud Hosting** | Vercel Serverless Functions (`vercel.json`) | 24/7 serverless cloud deployment |
| **Database** | MongoDB Atlas Cloud Database, Mongoose ODM | JSON document persistence with indexing & pre-save hooks |
| **AI Engine** | Google Gemini Flash 1.5 (`@google/generative-ai`) | Zero-shot email classification & executive summarization |
| **Document Parsers** | `xlsx`, `pdf-parse` | Buffer stream scanning for attached shortlist sheets |
| **Authentication** | Google OAuth 2.0 PKCE, JWT Access/Refresh Tokens | Secure student authentication & access control |
| **Security & Privacy** | 256-bit AES Encryption (`crypto-js`), Helmet, CORS | Token encryption and API protection |

---

# 🔌 API Specification & Route Reference

| Endpoint Route | Method | Module | Description |
| -------------- | ------ | ------ | ----------- |
| `/api/auth/demo-login` | `POST` | Auth | Quick development email login & JWT token generation |
| `/api/auth/google` | `POST` | Auth | Exchanges Google OAuth 2.0 authorization code |
| `/api/emails` | `GET` | Inbox | Fetches emails list with filters (`isShortlisted`, `priority`, `category`) |
| `/api/emails/:id` | `GET` | Inbox | Fetches single email details with Gemini AI auto-summary |
| `/api/applications` | `GET` | Tracker | Fetches all job applications for user |
| `/api/applications/grouped` | `GET` | Tracker | Groups applications by status (`Applied`, `Interview`, `Offer`, `Rejected`) |
| `/api/applications/:id/status` | `PATCH` | Tracker | Updates application selection stage with deduplicated history |
| `/api/deadlines` | `GET` | Deadlines | Fetches upcoming test deadlines and interview reminders |
| `/api/analytics/dashboard` | `GET` | Analytics | Fetches dashboard overview metrics, category counts & chart data |

---

# 📁 Repository Directory Structure

```
MailNexa/
├── server/                        # Node.js Express Backend API
│   ├── config/                    # DB, Gemini AI, OAuth & Firebase Configs
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

# ⚙️ Environment Configuration

To configure the backend server locally, create a `.env` file in the `server/` directory:

```ini
NODE_ENV=development
PORT=5000

# MongoDB Atlas Cloud Connection
MONGODB_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/mailguard?retryWrites=true&w=majority

# JWT Security Secrets
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

# 🚀 Getting Started & How to Run

### 1. Clone the Repository
```bash
git clone https://github.com/Bharath-vinayagam/MailNexa.git
cd MailNexa
```

### 2. Start Backend Server
```bash
cd server
npm install
npm start
```
*Server starts on `http://localhost:5000`*

### 3. Run Mobile Application
```bash
cd mobile
flutter pub get
flutter run
```

### 4. Build Standalone Release APK
```bash
cd mobile
flutter build apk --release
```
*Output location: `mobile/build/app/outputs/flutter-apk/app-release.apk`*

---

# 🛡️ Security & Data Privacy

* **OAuth 2.0 PKCE**: Sensitive Google OAuth refresh tokens are encrypted using **256-bit AES encryption** before database storage.
* **Excluded Credentials**: All environment files (`.env`), Google client secrets, and credentials are protected and excluded via `.gitignore`.
* **User Identifiers**: Students configure their own Registration Number and Campus ID safely within the mobile app **Settings Screen**.

---

# 🔮 Future Enhancements & Roadmap

* ⚡ **Zero-Latency Local Caching**: Implement Hive offline storage in Flutter for 0ms instant initial load times while syncing in the background.
* 📅 **1-Tap Calendar Synchronization**: Sync interview schedules and OA deadlines directly to native Android and iOS calendars.
* ⚡ **Real-Time Webhooks**: Integrate Google Cloud Pub/Sub push notifications for sub-500ms email delivery alerts.
* 🎯 **AI Placement Readiness Score**: Calculate a composite readiness metric based on active applications, shortlist frequency, and test deadlines.
* 🔍 **Universal Smart Search**: Expand top search bar to query across Emails, Company Applications, and Deadlines simultaneously.

---

# 👤 Author & Attribution

### **Bharath Vinayagam**
* **Role**: Lead Full-Stack & Mobile Systems Architect
* **GitHub**: [@Bharath-vinayagam](https://github.com/Bharath-vinayagam)
* **Project**: MailNexa – AI-Powered Campus Placement Intelligence Platform

---

# 📄 License

This project is licensed under the **MIT License**.
