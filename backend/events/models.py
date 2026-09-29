from django.db import models
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
