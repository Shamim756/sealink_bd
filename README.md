# 🐟 SeaLink BD - Seafood Supply Chain Management App

SeaLink BD is a comprehensive mobile application that connects fishermen (suppliers) directly with buyers (restaurants, retailers, and consumers). The app eliminates middlemen, ensures fair prices, and provides real-time visibility of seafood stock and demand across Bangladesh.

## 🚀 Features Implemented

### Core Functionality
*   **Authentication:** JWT-based login, real-time username verification, Email + Phone OTP verification.
*   **Marketplace:** Fish Listing CRUD (Create, Read, Update, Delete), Pagination, Search & Filter (Fish type, Location, Price range).
*   **Real-time Features:** Live commenting (Socket.io), Like/Dislike with live count, In-app Notifications.
*   **Order Flow:** Buyer places order, Supplier updates status (Pending → Confirmed → In Transit → Delivered).
*   **Rating System:** Buyers can rate suppliers after delivery.

### Advanced & Bonus Features
*   **Image Upload:** Cloudinary integration for fish images.
*   **YouTube Embed:** Suppliers can attach YouTube catch videos to listings.
*   **PDF Invoice:** Generate and download order invoices (Crystal Report equivalent).
*   **AI Chatbot (Gemini):** Ask about fish prices, diseases, or upload a photo to identify fish.
*   **AI Demand Forecast (TensorFlow Lite):** ML-based prediction of future fish demand.
*   **Animations:** Smooth UI transitions using `flutter_animate`.
*   **Web Admin Panel:** A Next.js + Tailwind CSS dashboard for platform monitoring.
*   **API Layers:** REST API (main), GraphQL (parallel layer), and SOAP API (legacy integration).
*   **Docker & CI/CD:** Containerized backend and GitHub Actions workflow.

## 🛠️ Tech Stack
*   **Frontend (Mobile):** Flutter (Dart)
*   **Backend:** Node.js (Express), Socket.io
*   **Database:** MariaDB (Dockerized)
*   **Web Admin:** Next.js, Tailwind CSS
*   **Cloud Storage:** Cloudinary
*   **AI/ML:** Google Gemini API, TensorFlow Lite

## 🚦 How to Run the Project

### Prerequisites
*   Flutter SDK installed
*   Node.js & npm installed
*   Docker & Docker Compose installed
*   Android Emulator or Physical Device

### 1. Backend Setup
```bash
cd sealink_backend
npm install
# Ensure .env file has DB credentials
docker compose up -d  # Start MariaDB
./start.sh            # Start Node.js API on port 3000