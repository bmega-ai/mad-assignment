import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from rest_framework.test import APIClient

client = APIClient()

# 1. Login Student
login_res = client.post('/api/auth/login/', {'username': '23CSE001', 'password': 'student123'}, format='json')
print(f"Login status: {login_res.status_code}")
if login_res.status_code == 200:
    data = login_res.json()
    token = data.get('access')
    role = data.get('role')
    print(f"Token obtained! Role: {role}, Student ID: {data.get('student_id')}")
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

    # 2. Profile
    prof_res = client.get('/api/student/profile/')
    print(f"Profile: {prof_res.status_code}, Name: {prof_res.json().get('full_name')}")

    # 3. Dashboard
    dash_res = client.get('/api/student/dashboard/')
    print(f"Dashboard: {dash_res.status_code}, Attendance: {dash_res.json().get('attendance', {}).get('percentage')}%, Today classes: {len(dash_res.json().get('today_classes', []))}")

    # 4. Timetable
    tt_res = client.get('/api/timetable/')
    print(f"Timetable: {tt_res.status_code}, Total slots: {len(tt_res.json())}")

    # 5. Attendance
    att_res = client.get('/api/attendance/')
    print(f"Attendance: {att_res.status_code}, Overall: {att_res.json().get('overall_percentage')}%")

    # 6. Assignments
    as_res = client.get('/api/assignments/')
    print(f"Assignments: {as_res.status_code}, Count: {len(as_res.json())}")

    # 7. Events
    ev_res = client.get('/api/events/')
    print(f"Events: {ev_res.status_code}, Count: {len(ev_res.json())}")

    # 8. Faculty
    fac_res = client.get('/api/faculty/')
    print(f"Faculty: {fac_res.status_code}, Count: {len(fac_res.json())}")

    # 9. Plagiarism / Submission test
    if len(as_res.json()) > 0:
        first_as_id = as_res.json()[0]['id']
        sub_res = client.post(f'/api/assignments/{first_as_id}/submit/', {
            'text': 'Design and build a responsive Flutter application utilizing Provider for state management, clean architecture, and Material 3 design principles.'
        })
        print(f"Submission & Plagiarism Check: {sub_res.status_code}, Similarity: {sub_res.json().get('similarity_report', {}).get('similarity_percentage')}%")
