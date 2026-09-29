from django.urls import path
from .views import (
    ProfileView,
    StudentDashboardView,
    TeacherDashboardView,
    TeacherRegistrationView,
    FacultyListView,
    CustomTokenObtainPairView,
)

urlpatterns = [
    path('auth/login/', CustomTokenObtainPairView.as_view(), name='custom_login'),
    path('auth/register-teacher/', TeacherRegistrationView.as_view(), name='register_teacher'),
    path('student/profile/', ProfileView.as_view(), name='student_profile'),
    path('profile/', ProfileView.as_view(), name='user_profile'),
    path('student/dashboard/', StudentDashboardView.as_view(), name='student_dashboard'),
    path('teacher/dashboard/', TeacherDashboardView.as_view(), name='teacher_dashboard'),
    path('faculty/', FacultyListView.as_view(), name='faculty_list'),
]