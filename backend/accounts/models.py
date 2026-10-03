from django.db import models
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
    is_online = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.student_id} - {self.user.get_full_name()}"

class FacultyProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='faculty_profile')
    faculty_id = models.CharField(max_length=20, unique=True)
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True)
    designation = models.CharField(max_length=100)
    office = models.CharField(max_length=100)
    phone = models.CharField(max_length=15, null=True, blank=True)
    STATUS_CHOICES = (
        ('PENDING', 'Pending Approval'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='APPROVED')

    def __str__(self):
        return f"{self.faculty_id} - {self.user.get_full_name()}"
