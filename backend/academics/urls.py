from django.urls import path
from .views import (
    SubjectListView,
    TimetableListView,
    AttendanceListView,
    AttendanceStudentsView,
    AttendanceDetailView,
)

urlpatterns = [
    path('subjects/', SubjectListView.as_view(), name='subjects'),
    path('timetable/', TimetableListView.as_view(), name='timetable'),
    path('attendance/', AttendanceListView.as_view(), name='attendance'),
    path('attendance/students/', AttendanceStudentsView.as_view(), name='attendance_students'),
    path('attendance/<int:pk>/', AttendanceDetailView.as_view(), name='attendance_detail'),
]