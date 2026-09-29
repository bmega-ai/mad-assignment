# LEARNOVA

> **Learn. Connect. Experience.**
> A modern college campus and student service mobile application.

## Overview
Learnova is a comprehensive mobile application that provides students with academic information, campus services, assignments, attendance, faculty information, announcements, events, event media, and notifications in one unified platform. 

## Features
- **Role-based Access**: Separate interfaces for Students, Faculty, and Admins.
- **Personalized Dashboard**: Content tailored by year, department, and semester.
- **Academics**: View timetable, track attendance, and download notes.
- **Assignments**: Upload, view, and replace assignments. Includes a basic similarity checker.
- **Events & Gallery**: View college events and an approved media gallery.
- **Notifications**: In-app real-time notifications for updates.
- **Faculty Directory**: Easy access to faculty profiles and contact details.

## Screenshots
*(Insert screenshots here)*

## Technology Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Django & Django REST Framework (Python)
- **Database**: MySQL
- **Plagiarism Detection**: Python + scikit-learn (TF-IDF Vectorization & Cosine Similarity)

## System Architecture
The application uses a client-server architecture where the Flutter mobile app communicates via RESTful APIs with the Django backend. The backend handles business logic, MySQL database operations, and similarity analysis using scikit-learn.

## Database Structure
Core models include:
- `User`, `StudentProfile`, `FacultyProfile`, `Department`
- `Subject`, `Timetable`, `Attendance`
- `Assignment`, `AssignmentSubmission`, `SimilarityResult`
- `Event`, `EventMedia`, `Note`, `Notification`

## Installation

### Prerequisites
- Python 3.x
- Flutter SDK
- MySQL Server

### MySQL Setup
1. Create a MySQL database named `learnova_db`.
2. Update `backend/config/settings.py` with your MySQL credentials.

### Django Setup (Backend)
1. Navigate to `backend/`
2. Create virtual environment: `python -m venv venv`
3. Activate virtual environment.
4. Install dependencies: `pip install -r requirements.txt` (or install manually: django, djangorestframework, PyMySQL, djangorestframework-simplejwt, django-cors-headers, scikit-learn)
5. Run migrations: `python manage.py makemigrations` and `python manage.py migrate`
6. Seed demo database: `python seed_data.py`
7. Run the server: `python manage.py runserver`

### Flutter Setup (Frontend)
1. Navigate to `mobile/`
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

## Demo Accounts
- **Student**: `23CSE001` / `student123`
- **Faculty**: `FAC001` / `faculty123`
- **Admin**: `ADMIN001` / `admin123`

## API Base URL Configuration
Update `lib/core/constants/api_constants.dart` depending on your environment:
- Android Emulator: `http://10.0.2.2:8000/api`
- Physical Device: `http://YOUR-PC-IP:8000/api`

## Plagiarism Algorithm
The assignment similarity checker uses:
- **TF-IDF Vectorization**: To convert text into numerical vectors.
- **Cosine Similarity**: To measure the similarity between the submitted document and existing submissions.

## Project Structure
- `backend/`: Django REST API
- `mobile/`: Flutter App
- `media/`: Local storage for assignments, events, and notes.

## Troubleshooting
- **Cannot connect to API**: Ensure the API base URL matches your emulator/device setup.
- **MySQL Errors**: Check your database credentials in `settings.py`.

## Known Limitations
- The plagiarism checker is basic and for educational purposes (not equivalent to Turnitin).
- Image-only PDFs currently cannot be analyzed for similarity.
