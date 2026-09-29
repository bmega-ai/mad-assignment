from django.db import models
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
