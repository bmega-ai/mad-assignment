from django.contrib import admin
from .models import Subject, Timetable, Attendance

@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'department', 'year', 'semester', 'faculty']
    list_filter = ['department', 'year', 'semester']
    search_fields = ['name', 'code']

@admin.register(Timetable)
class TimetableAdmin(admin.ModelAdmin):
    list_display = ['subject', 'day', 'start_time', 'end_time', 'room', 'department', 'year', 'section']
    list_filter = ['day', 'department', 'year', 'section']

@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ['student', 'subject', 'date', 'status']
    list_filter = ['status', 'date', 'subject']
    search_fields = ['student__student_id', 'student__user__first_name']
