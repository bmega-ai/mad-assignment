from django.urls import path
from .views import SubjectListView, TimetableListView, AttendanceListView

urlpatterns = [
    path('subjects/', SubjectListView.as_view(), name='subjects'),
    path('timetable/', TimetableListView.as_view(), name='timetable'),
    path('attendance/', AttendanceListView.as_view(), name='attendance'),
]