# OmniCart

**An AI-Powered Multi-Vendor E-Commerce Platform**

> Dual-course capstone project for **Database Systems** and **Artificial Intelligence**

---

## Group Members
- [Rayyan Aamir](https://github.com/Rayyan-2704)
- [Muhammad Usaid Khan](https://github.com/MuhammadUsaidKhan)
- [Ahmed Shah Rashdi](https://github.com/AhmedCodes03)

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [System Architecture](#system-architecture)
4. [Database Layer](#database-layer)
5. [Backend REST API](#backend-rest-api)
6. [AI & Machine Learning Layer](#ai--machine-learning-layer)
7. [n8n Automation Workflows](#n8n-automation-workflows)
8. [React Frontend](#react-frontend)
9. [Folder Structure](#folder-structure)
10. [Environment Setup](#environment-setup)
11. [Running the Project](#running-the-project)
12. [API Reference](#api-reference)
13. [Deployment](#deployment)

---

## Project Overview

OmniCart is a full-stack, multi-vendor e-commerce platform that serves three distinct user roles — **Customer**, **Vendor (Seller)**, and **Administrator** — each with a dedicated portal. What distinguishes it from a standard e-commerce app is a deeply integrated AI layer:

- A **hybrid recommendation engine** (SVD Collaborative Filtering + TF-IDF Content-Based Filtering) personalizes product suggestions per customer.
- **Llama 3.1 via NVIDIA API** generates natural-language explanations for each recommendation and auto-writes product descriptions for sellers.
- **TextBlob sentiment analysis** scores every customer review and feeds cleaner signals into the recommendation pipeline.
- **n8n** automates all customer communications — order confirmations, cart reminders, weekly deal digests, and low-stock alerts.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | React 19, Vite, Tailwind CSS v4, Framer Motion, Chart.js |
| **Backend** | Python 3.12, Flask, Flask-JWT-Extended, Flask-SQLAlchemy, Flask-Bcrypt, Flask-CORS |
| **Database** | MySQL 8.0, MySQL Workbench |
| **ML / AI** | scikit-surprise (SVD), scikit-learn (TF-IDF + kNN), TextBlob (sentiment) |
| **LLM** | NVIDIA API (Llama 3.1 8B Instruct) |
| **Automation** | n8n Cloud (webhook + CRON workflows) |
| **Auth** | JWT (role-based: customer / vendor / admin) |
| **HTTP Client** | Axios (frontend), Requests (backend → n8n) |
| **Deployment** | Vercel (frontend), Render (Flask + ML), Railway (MySQL), n8n Cloud |

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      React Frontend                         │
│  Customer Portal │ Vendor Portal │ Admin Portal             │
└───────────────────────────┬─────────────────────────────────┘
                            │ Axios (JWT Bearer)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Flask REST API                           │
│  auth │ customer │ orders │ vendor │ admin │ reviews        │
│  recommendations │ queries                                  │
└──────┬──────────────────────────┬────────────────────────────┘
       │                          │
       ▼                          ▼
┌─────────────┐        ┌──────────────────────┐
│  MySQL 8.0  │        │   ML / AI Layer       │
│  11 tables  │        │  SVD · TF-IDF · kNN   │
│  3 views    │        │  TextBlob · Llama 3.1  │
│  5 procs    │        └──────────────────────┘
│  5 triggers │
└─────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│              n8n Cloud (4 Automation Workflows)             │
│  Order Confirm │ Cart Abandon │ Low Stock │ Weekly Digest   │
└─────────────────────────────────────────────────────────────┘
```

---

## Database Layer

### Tables (11)

| Table | Description |
|---|---|
| `admins` | Platform administrator accounts |
| `customers` | Registered shoppers |
| `vendors` | Sellers (require admin approval) |
| `categories` | Self-referential hierarchy (parent → subcategory) |
| `products` | Listings with brand, price, stock, active flag |
| `orders` | Order header (status: pending → confirmed → shipped → delivered → cancelled) |
| `order_items` | Line items (FK → orders + products) |
| `payments` | One-to-one with orders; supports 4 payment methods |
| `reviews` | Rating (1–5) + comment + auto-computed `sentiment_score` |
| `cart` | Persistent shopping cart per customer |
| `recommendations` | ML-generated suggestions with score + LLM explanation |

### Stored Procedures (5)

| Procedure | Role | Description |
|---|---|---|
| `PlaceOrder(customer_id, cart_items_json)` | Customer | Atomic order placement — inserts order + items, deducts stock, clears cart; rolls back on any error |
| `CancelOrder(order_id, customer_id)` | Customer | Restores stock, cancels order, handles payment refund/void |
| `ProcessPayment(customer_id, order_id, method, amount)` | Customer | Validates and records payment, updates order to `confirmed` |
| `UpdateProductInventory(product_id, vendor_id, new_stock, new_price)` | Vendor | Ownership-checked product update |
| `DeactivateUser(admin_id, user_id, user_type, reason)` | Admin | Deactivates customer/vendor, cancels pending orders, logs reason |

### Views (3)

- **`CustomerOrderHistory`** — joins customers → orders → order_items → products
- **`TopRatedProducts`** — aggregated avg rating ≥ 3.5, total reviews, category
- **`VendorSalesSummary`** — per-vendor revenue, units sold, avg product rating

### Triggers (5)

Maintain data integrity on product deactivation, order status changes, and stock-level updates.

### Complex SQL Queries (5)

Exposed via `/api/queries/*` endpoints and in `database/queries.sql` for Workbench demonstration:

1. **Customer Full Order History** — 4-table JOIN with subtotals
2. **Monthly Revenue Report** — `DATE_FORMAT`, `SUM`, `COUNT`, `AVG`, `GROUP BY`
3. **Top Customers by Spend** — `HAVING`, correlated subquery for review count
4. **Vendor Sales Performance** — multi-table `LEFT JOIN`, `COALESCE`
5. **Category Sentiment Analysis** — correlated subquery counting positively-reviewed products per category

---

## Backend REST API

Built with Flask using a blueprint-based architecture. All protected routes require a JWT Bearer token. Roles enforced via `@role_required()` decorator.

### Blueprints & Key Endpoints

#### Auth (`/api/auth`)
| Method | Endpoint | Description |
|---|---|---|
| POST | `/register` | Register customer or vendor |
| POST | `/login` | Login (customer / vendor / admin) |
| GET | `/me` | Get current user from token |
| PUT | `/profile` | Update name, phone, address, store_name |
| PUT | `/change-password` | Change password (requires old password) |

#### Customer (`/api`)
| Method | Endpoint | Description |
|---|---|---|
| GET | `/products` | Browse with keyword search, category, price range, pagination, sorting |
| GET | `/products/<id>` | Product detail + reviews + avg rating |
| GET | `/categories` | All categories |
| POST/GET/DELETE | `/cart` | Add, view, clear cart |
| DELETE | `/cart/<item_id>` | Remove single cart item |

#### Orders (`/api`)
| Method | Endpoint | Description |
|---|---|---|
| POST | `/orders` | Place order (calls `PlaceOrder` SP) |
| GET | `/orders` | Customer order history |
| GET | `/orders/<id>` | Order detail with items + payment |
| POST | `/orders/<id>/cancel` | Cancel order (calls `CancelOrder` SP) |
| POST | `/payments` | Process payment (calls `ProcessPayment` SP) |
| GET | `/payments/<order_id>` | Get payment for order |

#### Vendor (`/api/vendor`)
| Method | Endpoint | Description |
|---|---|---|
| POST | `/products` | Add product |
| GET/PUT/DELETE | `/products/<id>` | View, update (calls `UpdateProductInventory` SP), deactivate |
| GET | `/orders` | Orders containing vendor's products |
| GET | `/stats` | Revenue, units sold, low-stock alerts |

#### Admin (`/api/admin`)
| Method | Endpoint | Description |
|---|---|---|
| GET | `/users` | List customers + vendors |
| POST | `/deactivate` | Deactivate user (calls `DeactivateUser` SP) |
| GET | `/stats` | Platform-wide analytics |
| GET | `/vendors/pending` | Unapproved vendor list |
| POST | `/vendors/<id>/approve` | Approve vendor |
| POST/GET/DELETE | `/categories` | Category management |
| POST | `/trigger/abandoned-carts` | Manually fire cart abandonment workflow |
| POST | `/trigger/low-stock` | Manually fire low-stock workflow |
| POST | `/trigger/weekly-digest` | Manually fire weekly digest workflow |

#### Recommendations (`/api/recommendations`)
| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Get personalized recommendations (stored or ML-generated) |
| GET | `/similar/<product_id>` | TF-IDF content-based similar products |
| GET | `/trending` | Top 10 products by units sold |
| POST | `/explain` | Generate LLM explanation for a recommendation |
| POST | `/analyze-sentiment` | Analyze text sentiment on-demand |

#### Reviews (`/api`)
| Method | Endpoint | Description |
|---|---|---|
| POST | `/reviews` | Submit review (verified purchase check) |
| GET | `/reviews/my` | Customer's own reviews |
| PUT | `/reviews/<id>` | Edit own review |
| DELETE | `/reviews/<id>` | Delete (own: customer; any: admin) |
| GET | `/products/<id>/reviews` | Product reviews + stats + distribution |

---

## AI & Machine Learning Layer

### 1. SVD Collaborative Filtering (`ml/train_svd.py`)

- **Dataset:** Amazon Product Reviews (200K sample, filtered for users/products with ≥ 3 interactions)
- **Library:** `scikit-surprise`
- **Model:** SVD with 50 latent factors, 20 epochs
- **Evaluation:** 3-fold cross-validation; RMSE and MAE reported
- **Output:** `ml/svd_model.pkl` + `ml/product_map.pkl`

### 2. TF-IDF + kNN Content-Based Filtering (`ml/train_tfidf.py`)

- **Input:** Product name (weighted 2×), brand (weighted 2×), category, parent category, description
- **Vectorizer:** `TfidfVectorizer` (max 5000 features, unigrams + bigrams, English stop words)
- **Similarity:** Cosine similarity matrix across all active products
- **Output:** `ml/tfidf_model.pkl` containing vectorizer, matrix, similarity matrix, and index maps

### 3. TextBlob Sentiment Analysis (`ml/train_sentiment.py`)

- **Pipeline:** TextBlob `sentiment.polarity` → normalized to [0.0, 1.0]
- **Validation:** Tested on 5,000 Amazon review samples; accuracy reported
- **Integration:** Auto-runs on every `POST /api/reviews`; score stored in `reviews.sentiment_score`
- **Output:** `ml/sentiment_model.pkl`

### 4. Hybrid Recommender (`backend/app/services/recommendation_service.py`)

```
Step 1: SVD predicts ratings for all unrated products → top candidates
Step 2: TF-IDF kNN finds content-similar candidates (if recently viewed product provided)
Step 3: Sentiment filter removes products with sentiment_score < 0.4
Step 4: Hybrid score = 0.6 × CF_score + 0.4 × CB_score
Step 5: Return top-N ranked products
```

### 5. LLM Integration — Llama 3.1 via NVIDIA API (`backend/app/services/openai_service.py`)

Two functions powered by `meta/llama-3.1-8b-instruct`:

- **`generate_recommendation_reason(customer_name, product_name, category)`** — 1–2 sentence personalized explanation of why a product is recommended
- **`generate_product_description(product_name, category, price, brand)`** — marketing-quality 2-sentence product description for seller listings

---

## n8n Automation Workflows

All workflows live in `n8n/` as importable JSON files. The Flask backend POSTs pre-bundled data to n8n Cloud webhook URLs — n8n never needs to reach back to Flask, which solves the localhost tunnel problem.

### Workflow 1: Order Confirmation (`order-confirmation.json`)
- **Trigger:** Webhook `POST /webhook/order-placed`
- **Fired by:** Flask `POST /api/orders` after successful DB commit
- **Action:** Sends formatted HTML email with order ID, itemized table, and grand total

### Workflow 2: Cart Abandonment Reminder (`cart_abandonment_reminder.json`)
- **Trigger:** Webhook `POST /webhook/trigger-abandoned-carts` (fired by admin or CRON)
- **Data source:** Flask bundles all carts older than 24 hours into the payload
- **Action:** Loops over customers, sends personalized cart reminder email per customer

### Workflow 3: Low Stock Alert (`low_stock_alert.json`)
- **Trigger:** Webhook `POST /webhook/trigger-low-stock` (fired by admin or CRON)
- **Data source:** Flask bundles all products with `stock_qty < threshold`
- **Action:** Loops over products, sends alert email to each vendor's registered address

### Workflow 4: Weekly Deals Digest (`weekly_deals_digest.json`)
- **Trigger:** Webhook `POST /webhook/trigger-weekly-digest` (fired by admin or CRON)
- **Data source:** Flask bundles all active customers with their top-5 recommendations + LLM explanations
- **Action:** Sends personalized HTML digest email per customer with product names, prices, and AI-written explanations

> **n8n Cloud note:** ES6 template literals are not supported inside `{{ }}` expressions — use string concatenation with `+` in HTML email bodies.

---

## React Frontend

Built with React 19 + Vite. All business logic lives in the Flask backend; the frontend is a pure API consumer.

### Portals

| Portal | Route | Key Features |
|---|---|---|
| **Customer** | `/`, `/products`, `/dashboard` | Browse, search, filter products; AI recommendations with LLM explanations on homepage; cart, checkout, order history, reviews |
| **Vendor** | `/vendor` | Product management (add/edit/deactivate), AI-generated product descriptions, order tracking, revenue chart |
| **Admin** | `/admin` | Platform stats, user management, vendor approval, category CRUD, Chart.js analytics, manual n8n workflow triggers |

### Key Components

- **`AuthContext`** — JWT storage, role-based routing, login/register/logout
- **`CartContext`** — Syncs cart with backend on every action
- **`ThemeContext`** — Dark mode (default) / light mode toggle
- **`ProtectedRoute`** — Redirects unauthenticated users; enforces role constraints
- **`BorderGlow`** — Custom interactive glassmorphism card component with mouse-tracking glow effect
- **`AnalyticsChart`** — Chart.js wrapper (line, bar, doughnut) with dark-mode theming
- **`ProductCard`** — Hover actions (quick view, add to cart), stock badges, star ratings

### Axios Configuration (`frontend/src/api/axios.js`)

- Base URL from `VITE_API_URL` env variable
- JWT token injected into every request via interceptor
- 401 responses clear localStorage and redirect to `/login`

---

## Folder Structure

```
omnicart/
├── backend/
│   ├── app/
│   │   ├── models/          # SQLAlchemy models (11 tables)
│   │   ├── routes/          # Flask blueprints (7 files)
│   │   ├── services/        # Business logic (auth, recommendation, LLM)
│   │   ├── middleware/       # role_required decorator
│   │   ├── queries.py       # 5 complex SQL queries
│   │   ├── extensions.py    # db, jwt, bcrypt instances
│   │   └── __init__.py      # App factory, blueprint registration
│   ├── seed.py              # Idempotent seed script
│   └── run.py               # Entry point
├── frontend/
│   ├── src/
│   │   ├── api/             # Axios instance
│   │   ├── components/      # Shared UI components
│   │   ├── context/         # Auth, Cart, Theme contexts
│   │   └── pages/           # customer/, vendor/, admin/ portals
│   ├── .env.example
│   └── vite.config.js
├── ml/
│   ├── train_svd.py         # SVD model training
│   ├── train_tfidf.py       # TF-IDF + cosine similarity
│   ├── train_sentiment.py   # Sentiment pipeline
│   ├── svd_model.pkl        # (gitignored)
│   ├── tfidf_model.pkl      # (gitignored)
│   └── sentiment_model.pkl  # (gitignored)
├── n8n/
│   ├── order-confirmation.json
│   ├── cart_abandonment_reminder.json
│   ├── low_stock_alert.json
│   └── weekly_deals_digest.json
├── database/
│   ├── schema.sql           # Full DDL (tables, views, indexes)
│   ├── procedures.sql       # 5 stored procedures
│   ├── seed.sql             # Static seed for Workbench demo
│   └── queries.sql          # 5 complex queries for DB course
├── .env.example
├── .gitignore
└── README.md
```

---

## Environment Setup

### Prerequisites

- Python 3.12+
- Node.js 20+ (via nvm recommended)
- MySQL 8.0 + MySQL Workbench
- Git

### 1. Clone & Python Environment

```bash
git clone https://github.com/AhmedCodes03/OmniCart.git
cd OmniCart

python -m venv venv
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

pip install flask sqlalchemy flask-jwt-extended pymysql python-dotenv \
            flask-bcrypt flask-cors scikit-surprise pandas numpy \
            scikit-learn textblob nltk openai requests validators
```

### 2. MySQL Database

```sql
-- In MySQL Workbench or CLI:
CREATE DATABASE omnicart_db;
```

Then run in order:
```bash
mysql -u root -p omnicart_db < database/schema.sql
mysql -u root -p omnicart_db < database/procedures.sql
```

### 3. Environment Variables

Copy `.env.example` to `.env` and fill in values:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=YOUR_MYSQL_PASSWORD_HERE
DB_NAME=omnicart_db
JWT_SECRET_KEY=ANY_RANDOM_STRING
NVIDIA_API_KEY=sk-YOUR_KEY_HERE
N8N_ORDER_PLACED_URL=https://YOUR_N8N_INSTANCE/webhook/order-placed
N8N_ABANDONED_CARTS_URL=https://YOUR_N8N_INSTANCE/webhook/trigger-abandoned-carts
N8N_LOW_STOCK_URL=https://YOUR_N8N_INSTANCE/webhook/trigger-low-stock
N8N_WEEKLY_DIGEST_URL=https://YOUR_N8N_INSTANCE/webhook/trigger-weekly-digest
```

> Get your NVIDIA API key at [build.nvidia.com](https://build.nvidia.com).

### 4. Frontend

```bash
cd frontend
npm install
cp .env.example .env
# Set VITE_API_URL=http://localhost:5000/api for local dev
```

---

## Running the Project

### Backend

```bash
# From project root, with venv active:
python -m backend.run
# Flask starts on http://localhost:5000
```

### Seed Database

```bash
python -m backend.seed
# Safe to run multiple times — skips existing records
```

### Train ML Models

```bash
# Download Amazon Reviews dataset to ml/Reviews.csv first
# (Kaggle: amazon-fine-food-reviews or any Amazon reviews CSV with UserId, ProductId, Score)

python ml/train_svd.py        # Trains SVD, saves ml/svd_model.pkl
python ml/train_tfidf.py      # Builds TF-IDF matrix, saves ml/tfidf_model.pkl
python ml/train_sentiment.py  # Backfills sentiment scores, saves ml/sentiment_model.pkl
```

### Frontend

```bash
cd frontend
npm run dev
# React dev server at http://localhost:5173
```

### n8n

Import the 4 JSON files from `n8n/` into your n8n Cloud instance. Update the SMTP credentials and set your webhook URLs in `.env`.

---

## API Reference

All responses are JSON. All protected endpoints require:

```
Authorization: Bearer <jwt_token>
```

### Authentication

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "rayyan.aamir@gmail.com",
  "password": "Customer@1234",
  "role": "customer"
}
```

Response includes `token`, `role`, and `user` object.

### Example: Place Order

```http
POST /api/orders
Authorization: Bearer <token>

{
  "cart_items": [
    { "product_id": 1, "quantity": 2 },
    { "product_id": 5, "quantity": 1 }
  ]
}
```

### Example: Get Recommendations

```http
GET /api/recommendations/
Authorization: Bearer <token>
```

Returns stored recommendations or triggers the hybrid ML pipeline on first call.

---

## Deployment

| Service | Platform | Notes |
|---|---|---|
| React frontend | Vercel | Set `VITE_API_URL` to Render backend URL |
| Flask + ML | Render | `requirements.txt` + `python -m backend.run` start command |
| MySQL | Railway | Copy connection string to Flask `.env` |
| n8n | n8n Cloud | Import workflow JSONs; update SMTP credentials |

> The `vite.config.js` proxy (`/api` → Railway URL) handles local development without CORS issues.

---

## Seeded Test Credentials

| Role | Email | Password |
|---|---|---|
| Admin | `admin@omnicart.com` | `SuperAdmin@1234` |
| Vendor | `techzone@omnicart.com` | `Vendor@1234` |
| Customer | `rayyan.aamir@gmail.com` | `Customer@1234` |

All 10 seeded customers share password `Customer@1234`. All 5 vendors share `Vendor@1234`.

---