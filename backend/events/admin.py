from django.contrib import admin
from .models import Event, EventMedia

@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'date', 'time', 'venue', 'organizer']
    list_filter = ['category', 'date']
    search_fields = ['title', 'venue', 'organizer']

@admin.register(EventMedia)
class EventMediaAdmin(admin.ModelAdmin):
    list_display = ['event', 'uploaded_by', 'media_type', 'status', 'upload_date']
    list_filter = ['status', 'media_type']
