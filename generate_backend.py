import os

backend_files = {
    'accounts/models.py': '''from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    ROLE_CHOICES = (
        ('student', 'Student'),
        ('faculty', 'Faculty'),
        ('admin', 'Admin'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    profile_image = models.ImageField(upload_to='profiles/', null=True, blank=True)

class Department(models.Model):
    name = models.CharField(max_length=100)
    code = models.CharField(max_length=10)
    
    def __str__(self):
        return self.name

class StudentProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='student_profile')
    student_id = models.CharField(max_length=20, unique=True)
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True)
    year = models.IntegerField()
    section = models.CharField(max_length=5)
    semester = models.IntegerField()
    phone = models.CharField(max_length=15, null=True, blank=True)

    def __str__(self):
        return f"{self.student_id} - {self.user.get_full_name()}"

class FacultyProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='faculty_profile')
    faculty_id = models.CharField(max_length=20, unique=True)
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True)
    designation = models.CharField(max_length=100)
    office = models.CharField(max_length=100)
    phone = models.CharField(max_length=15, null=True, blank=True)

    def __str__(self):
        return f"{self.faculty_id} - {self.user.get_full_name()}"
''',
    'accounts/urls.py': '''from django.urls import path
from .views import ProfileView

urlpatterns = [
    path('student/profile/', ProfileView.as_view(), name='profile'),
]''',
    'accounts/views.py': '''from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

class ProfileView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        user = request.user
        data = {
            "id": user.id,
            "username": user.username,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "email": user.email,
            "role": user.role,
        }
        if user.role == 'student' and hasattr(user, 'student_profile'):
            profile = user.student_profile
            data.update({
                "student_id": profile.student_id,
                "department": profile.department.name if profile.department else None,
                "year": profile.year,
                "section": profile.section,
                "semester": profile.semester,
            })
        elif user.role == 'faculty' and hasattr(user, 'faculty_profile'):
            profile = user.faculty_profile
            data.update({
                "faculty_id": profile.faculty_id,
                "designation": profile.designation,
                "department": profile.department.name if profile.department else None,
            })
        return Response(data)
''',
    'academics/models.py': '''from django.db import models
from accounts.models import Department, FacultyProfile, StudentProfile

class Subject(models.Model):
    name = models.CharField(max_length=100)
    code = models.CharField(max_length=20)
    department = models.ForeignKey(Department, on_delete=models.CASCADE)
    year = models.IntegerField()
    semester = models.IntegerField()
    faculty = models.ForeignKey(FacultyProfile, on_delete=models.SET_NULL, null=True)

    def __str__(self):
        return self.name

class Timetable(models.Model):
    DAY_CHOICES = (
        ('Monday', 'Monday'),
        ('Tuesday', 'Tuesday'),
        ('Wednesday', 'Wednesday'),
        ('Thursday', 'Thursday'),
        ('Friday', 'Friday'),
    )
    department = models.ForeignKey(Department, on_delete=models.CASCADE)
    year = models.IntegerField()
    section = models.CharField(max_length=5)
    day = models.CharField(max_length=10, choices=DAY_CHOICES)
    start_time = models.TimeField()
    end_time = models.TimeField()
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    room = models.CharField(max_length=20)

class Attendance(models.Model):
    student = models.ForeignKey(StudentProfile, on_delete=models.CASCADE)
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    date = models.DateField()
    status = models.BooleanField(default=True) # True = Present, False = Absent
''',
    'academics/urls.py': '''from django.urls import path

urlpatterns = [
    # Paths will go here
]''',
    'assignments/models.py': '''from django.db import models
from accounts.models import FacultyProfile, StudentProfile, Department
from academics.models import Subject

class Assignment(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    department = models.ForeignKey(Department, on_delete=models.CASCADE)
    year = models.IntegerField()
    section = models.CharField(max_length=5)
    semester = models.IntegerField()
    due_date = models.DateTimeField()
    max_marks = models.IntegerField(default=100)
    attachment = models.FileField(upload_to='assignments/tasks/', null=True, blank=True)
    faculty = models.ForeignKey(FacultyProfile, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

class AssignmentSubmission(models.Model):
    STATUS_CHOICES = (
        ('Submitted', 'Submitted'),
        ('Late', 'Late'),
        ('Graded', 'Graded'),
    )
    assignment = models.ForeignKey(Assignment, on_delete=models.CASCADE, related_name='submissions')
    student = models.ForeignKey(StudentProfile, on_delete=models.CASCADE)
    file = models.FileField(upload_to='assignments/submissions/')
    submitted_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Submitted')
    marks_obtained = models.IntegerField(null=True, blank=True)
    extracted_text = models.TextField(null=True, blank=True)

class SimilarityResult(models.Model):
    submission = models.OneToOneField(AssignmentSubmission, on_delete=models.CASCADE)
    similarity_percentage = models.FloatField()
    originality_percentage = models.FloatField()
    potential_matches = models.JSONField(default=list)
''',
    'assignments/urls.py': '''from django.urls import path

urlpatterns = [
    # Paths will go here
]''',
    'events/models.py': '''from django.db import models
from accounts.models import User, Department

class Event(models.Model):
    CATEGORY_CHOICES = (
        ('Academic', 'Academic'),
        ('Technical', 'Technical'),
        ('Cultural', 'Cultural'),
        ('Sports', 'Sports'),
        ('Workshop', 'Workshop'),
        ('Seminar', 'Seminar'),
        ('Club', 'Club'),
        ('Other', 'Other'),
    )
    title = models.CharField(max_length=200)
    description = models.TextField()
    date = models.DateField()
    time = models.TimeField()
    venue = models.CharField(max_length=200)
    organizer = models.CharField(max_length=200)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    cover_image = models.ImageField(upload_to='event_covers/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

class EventMedia(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
    )
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='media')
    uploaded_by = models.ForeignKey(User, on_delete=models.CASCADE)
    file = models.FileField(upload_to='event_media/')
    media_type = models.CharField(max_length=10) # 'image' or 'video'
    caption = models.CharField(max_length=255, null=True, blank=True)
    upload_date = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
''',
    'events/urls.py': '''from django.urls import path

urlpatterns = [
    # Paths will go here
]''',
    'notifications/models.py': '''from django.db import models
from accounts.models import User

class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
''',
    'notifications/urls.py': '''from django.urls import path

urlpatterns = [
    # Paths will go here
]''',
    'notes/models.py': '''from django.db import models
from accounts.models import Department, FacultyProfile
from academics.models import Subject

class Note(models.Model):
    title = models.CharField(max_length=200)
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    department = models.ForeignKey(Department, on_delete=models.CASCADE)
    year = models.IntegerField()
    semester = models.IntegerField()
    file = models.FileField(upload_to='notes/')
    faculty = models.ForeignKey(FacultyProfile, on_delete=models.CASCADE)
    upload_date = models.DateTimeField(auto_now_add=True)
''',
    'notes/urls.py': '''from django.urls import path

urlpatterns = [
    # Paths will go here
]''',
    'plagiarism/urls.py': '''from django.urls import path

urlpatterns = [
    # Paths will go here
]''',
    'accounts/__init__.py': '',
    'academics/__init__.py': '',
    'assignments/__init__.py': '',
    'events/__init__.py': '',
    'notifications/__init__.py': '',
    'notes/__init__.py': '',
    'plagiarism/__init__.py': '',
    
    'plagiarism/services.py': '''import os
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

def check_similarity(new_text, existing_texts):
    if not new_text or not existing_texts:
        return 0.0, []
        
    texts = [new_text] + existing_texts
    vectorizer = TfidfVectorizer(stop_words='english')
    try:
        tfidf_matrix = vectorizer.fit_transform(texts)
    except ValueError:
        return 0.0, [] # Empty vocabulary
        
    cosine_sim = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:])
    
    similarities = cosine_sim[0]
    max_sim = max(similarities) if len(similarities) > 0 else 0
    
    matches = []
    for idx, sim in enumerate(similarities):
        if sim > 0.1: # 10% threshold
            matches.append({"index": idx, "similarity": round(sim * 100, 2)})
            
    return round(max_sim * 100, 2), matches
'''
}

backend_path = r'c:\Users\PERSONAL\OneDrive\Desktop\mad assignment\backend'

for filepath, content in backend_files.items():
    full_path = os.path.join(backend_path, filepath)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Backend files generated successfully!")
