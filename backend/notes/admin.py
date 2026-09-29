from django.contrib import admin
from .models import Note

@admin.register(Note)
class NoteAdmin(admin.ModelAdmin):
    list_display = ['title', 'subject', 'department', 'year', 'semester', 'faculty', 'upload_date']
    list_filter = ['department', 'year', 'semester', 'subject']
    search_fields = ['title']
