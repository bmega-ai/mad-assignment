from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Department, StudentProfile, FacultyProfile

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (
        ('Role Info', {'fields': ('role', 'profile_image')}),
    )
    list_display = ['username', 'email', 'first_name', 'last_name', 'role', 'is_staff']
    list_filter = ['role', 'is_staff', 'is_superuser']

@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ['name', 'code']

@admin.register(StudentProfile)
class StudentProfileAdmin(admin.ModelAdmin):
    list_display = ['student_id', 'user', 'department', 'year', 'section', 'semester']
    search_fields = ['student_id', 'user__username', 'user__first_name', 'user__last_name']
    list_filter = ['department', 'year', 'section', 'semester']

@admin.register(FacultyProfile)
class FacultyProfileAdmin(admin.ModelAdmin):
    list_display = ['faculty_id', 'user', 'department', 'designation', 'office']
    search_fields = ['faculty_id', 'user__username', 'user__first_name', 'user__last_name']
    list_filter = ['department', 'designation']
