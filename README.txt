================================================================================
  MailNexa – AI-Powered Gmail Priority Assistant & Campus Placement Tracker
================================================================================

OVERVIEW:
MailNexa is an executive full-stack mobile application and AI-driven backend engine 
specifically engineered for university students to solve email overload during campus 
placement drives. The platform integrates Google Gmail API (OAuth 2.0) to fetch incoming 
academic emails, executes automated Google Gemini AI text classification, performs 
deterministic attachment scanning (.xlsx / .pdf) for student identifiers, generates clean 
3-4 bullet executive summaries, and presents priority feeds, application stage timelines, 
and deadline countdowns in a stunning Flutter mobile application.

--------------------------------------------------------------------------------
KEY FEATURES & CAPABILITIES
--------------------------------------------------------------------------------
1. AI Priority Classification & Bullet Summaries:
   - Routes incoming emails into Placement, Academic, or Promotions with High, Medium, 
     or Low priority.
   - Generates clean 3-4 formal bullet points (• ) summarizing key requirements, test dates, 
     and action items without emojis or markdown clutter.

2. Deterministic Shortlist Verification (0 False Positives):
   - Downloads and parses attached Excel spreadsheets (.xlsx) and PDFs (.pdf).
   - Strictly verifies if the student's Registration Number or Campus NeoPAT ID appears 
     in text or attachments before flagging an email as Shortlisted.

3. Application Stage Tracker & Timeline Stepper:
   - Tracks company selection stages (Applied ➔ Online Test ➔ Interview ➔ Offer / Rejected).
   - Maintains deduplicated status history logs with timestamps and prep notes.

4. Deadline Countdowns & Reminders:
   - Automatically extracts test deadlines and interview dates from emails.
   - Allows 1-tap custom reminder creation populating the Deadlines tab.

5. Noise Interception & 250-Email Storage Cap:
   - Intercepts course spam (e.g. NPTEL, Kaggle) into low-priority feeds with zero push alerts.
   - Automatically prunes MongoDB to maintain a maximum of 250 active emails per user.

6. Network Resilience & Bi-Directional Fallback:
   - Mobile client automatically retries between ADB localhost (127.0.0.1:5000) and host 
     Wi-Fi IP if connection drops.

--------------------------------------------------------------------------------
TECHNOLOGY STACK
--------------------------------------------------------------------------------
- Mobile Client: Flutter 3.19 (Dart 3.3), Material 3, Riverpod 2.6, Dio HTTP Client, GoRouter
- Backend API: Node.js (v18+), Express.js (REST API), Vercel Serverless Runtime
- Database: MongoDB Atlas Cloud Database, Mongoose ODM with indexing & pre-save hooks
- AI Engine: Google Gemini Flash 1.5 LLM (@google/generative-ai) with deterministic prompts
- Document Parsers: xlsx (Excel Sheet-to-CSV Buffer Stream), pdf-parse (PDF Stream Extractor)
- Security: Google OAuth 2.0 PKCE, 256-bit AES Token Encryption, JWT Refresh Token Rotation, Helmet

--------------------------------------------------------------------------------
API ENDPOINTS REFERENCE
--------------------------------------------------------------------------------
- POST  /api/auth/demo-login        : Development authentication & JWT token generation
- POST  /api/auth/google            : Google OAuth 2.0 authorization code exchange
- GET   /api/emails                 : Fetches filtered email list (isShortlisted, priority, category)
- GET   /api/emails/:id             : Fetches single email with AI auto-summary & attachment analysis
- GET   /api/applications           : Fetches user job applications
- GET   /api/applications/grouped   : Groups applications by status (Applied, Interview, Offer, Rejected)
- PATCH /api/applications/:id/status: Updates application selection stage with deduplicated history
- GET   /api/deadlines              : Fetches upcoming test deadlines and interview reminders
- GET   /api/analytics/dashboard    : Fetches dashboard summary statistics and category counts

--------------------------------------------------------------------------------
REPOSITORY STRUCTURE
--------------------------------------------------------------------------------
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
├── README.txt                     # Plaintext Documentation
└── requirements.txt               # Dependencies & Environment Specifications

--------------------------------------------------------------------------------
QUICK START & HOW TO RUN
--------------------------------------------------------------------------------
1. Run Backend Server:
   cd server
   npm install
   npm start

2. Run Mobile Application:
   cd mobile
   flutter pub get
   flutter run

3. Build Standalone Release APK:
   cd mobile
   flutter build apk --release

--------------------------------------------------------------------------------
PRIVACY & SECURITY NOTE
--------------------------------------------------------------------------------
All sensitive environment variables (.env), Google OAuth keys, and private credentials 
are excluded from source control via .gitignore. Users configure their own Registration 
Number and Campus ID in the app Settings Screen.

License: MIT License.
================================================================================
