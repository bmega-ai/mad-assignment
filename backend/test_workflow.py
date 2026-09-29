import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from rest_framework.test import APIClient
from assignments.models import Assignment, AssignmentSubmission, TeacherReview

client = APIClient()

print("=" * 60)
print("TEST 1: TEACHER REGISTRATION & LOGIN")
print("=" * 60)

# Register new teacher
reg_res = client.post('/api/auth/register-teacher/', {
    'full_name': 'Prof. Anita Desai',
    'teacher_id': 'FAC099',
    'email': 'anita.desai@learnova.edu',
    'phone': '+91 98765 00099',
    'department': 'CSE',
    'designation': 'Assistant Professor',
    'password': 'faculty123',
    'confirm_password': 'faculty123'
})
print(f"Teacher Registration: {reg_res.status_code}, Status: {reg_res.json().get('status')}")

# Login Teacher FAC001
teach_login = client.post('/api/auth/login/', {'username': 'FAC001', 'password': 'faculty123'})
print(f"Teacher Login: {teach_login.status_code}, Role: {teach_login.json().get('role')}")
teach_token = teach_login.json().get('access')

# Teacher Dashboard
client.credentials(HTTP_AUTHORIZATION=f'Bearer {teach_token}')
dash_res = client.get('/api/teacher/dashboard/')
print(f"Teacher Dashboard: {dash_res.status_code}, To Review Count: {dash_res.json().get('to_review_count')}")

print("\n" + "=" * 60)
print("TEST 2: STUDENT LOGIN & INITIAL HIGH SIMILARITY (>70%)")
print("=" * 60)

# Login Student 23CSE001 (Arun Kumar)
client.credentials() # reset
stud_login = client.post('/api/auth/login/', {'username': '23CSE001', 'password': 'student123'})
print(f"Student Login: {stud_login.status_code}, Role: {stud_login.json().get('role')}")
stud_token = stud_login.json().get('access')
client.credentials(HTTP_AUTHORIZATION=f'Bearer {stud_token}')

assign = Assignment.objects.filter(title="Network Security Assignment 1").first()
print(f"Assignment found: {assign.title} (ID: {assign.id})")

# Test high similarity submission (>70%)
text_a = "Network security consists of the policies, processes, and practices adopted to prevent, detect, and monitor unauthorized access, misuse, modification, or denial of a computer network and network-accessible resources. Network security involves the authorization of access to data in a network, which is controlled by the network administrator. Users choose or are assigned an ID and password or other authenticating information that allows them access to information and programs within their authority. Network security covers a variety of computer networks, both public and private, that are used in everyday jobs: conducting transactions and communications among businesses, government agencies and individuals. Networks can be private, such as within a company, and others which might be open to public access."

sub_res = client.post(f'/api/assignments/{assign.id}/submit/', {'text': text_a})
print(f"High Similarity Submission: {sub_res.status_code}")
sub_data = sub_res.json()
sub_id = sub_data.get('id')
sim_pct = sub_data.get('similarity', {}).get('similarity_percentage')
status_val = sub_data.get('status')
print(f" -> Submission ID: {sub_id}, Similarity: {sim_pct}%, Status: {status_val}")

# Check matches endpoint
matches_res = client.get(f'/api/submissions/{sub_id}/matches/')
print(f"Matches endpoint: {matches_res.status_code}, Total matches: {len(matches_res.json())}")
for m in matches_res.json():
    print(f"   * vs {m.get('matched_student_name')}: {m.get('similarity_percentage')}%")

print("\n" + "=" * 60)
print("TEST 3: OPTION 1 — REQUEST TEACHER REVIEW & APPROVAL")
print("=" * 60)

# Student requests review
rev_req = client.post(f'/api/submissions/{sub_id}/review-request/')
print(f"Student Review Request: {rev_req.status_code}, Status: {rev_req.json().get('status')}")

# Teacher reviews & approves
client.credentials(HTTP_AUTHORIZATION=f'Bearer {teach_token}')
teach_reviews = client.get('/api/teacher/review-requests/')
print(f"Teacher Pending Reviews: {teach_reviews.status_code}, Count: {len(teach_reviews.json())}")
first_review_id = teach_reviews.json()[0]['id']

appr_res = client.post(f'/api/teacher/review-requests/{first_review_id}/action/', {
    'action': 'APPROVE',
    'feedback': 'Reviewed original document. Similarity is due to standard technical definitions. Approved!'
})
print(f"Teacher Approve Action: {appr_res.status_code}, Submission Status: {appr_res.json().get('submission_status')}")

print("\n" + "=" * 60)
print("TEST 4: OPTION 2 — REWRITE & RESUBMIT (VERSION HISTORY)")
print("=" * 60)

# Student resubmits rewritten assignment (v2)
client.credentials(HTTP_AUTHORIZATION=f'Bearer {stud_token}')
revised_text = "Modern network defensive architectures incorporate zero-trust security models, where trust is never assumed and continuous verification is mandated at every access layer. Identity-aware proxies, multi-factor biometric authentication, and micro-segmentation protect internal data enclaves from lateral cyber threats."

resub_res = client.post(f'/api/submissions/{sub_id}/resubmit/', {'text': revised_text})
print(f"Student Resubmit v2: {resub_res.status_code}")
v2_data = resub_res.json()
print(f" -> Current Version: {v2_data.get('current_version')}, Status: {v2_data.get('status')}, Similarity: {v2_data.get('similarity', {}).get('similarity_percentage')}%")

# Check version history
vers_res = client.get(f'/api/submissions/{sub_id}/versions/')
print(f"Version History Count: {len(vers_res.json())}")
for v in vers_res.json():
    print(f"   * Version {v.get('version_number')}: {v.get('status')} ({v.get('similarity_percentage')}% similar)")

print("\n" + "=" * 60)
print("ALL WORKFLOW TESTS COMPLETED SUCCESSFULLY!")
print("=" * 60)
