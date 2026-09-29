from django.db import models
from accounts.models import FacultyProfile, StudentProfile, Department
from academics.models import Subject

class Assignment(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    instructions = models.TextField(blank=True, default='')
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    department = models.ForeignKey(Department, on_delete=models.CASCADE)
    year = models.IntegerField()
    section = models.CharField(max_length=5)
    semester = models.IntegerField()
    due_date = models.DateTimeField()
    max_marks = models.IntegerField(default=100)
    attachment = models.FileField(upload_to='assignments/tasks/', null=True, blank=True)
    faculty = models.ForeignKey(FacultyProfile, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title} ({self.subject.code})"

class AssignmentSubmission(models.Model):
    STATUS_CHOICES = (
        ('DRAFT', 'Draft'),
        ('SUBMITTED', 'Submitted'),
        ('PROCESSING', 'Processing'),
        ('OCR_COMPLETED', 'OCR Completed'),
        ('CHECKING_SIMILARITY', 'Checking Similarity'),
        ('LOW_SIMILARITY', 'Low Similarity'),
        ('HIGH_SIMILARITY', 'High Similarity'),
        ('REVIEW_REQUESTED', 'Review Requested'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
        ('REWRITE_REQUIRED', 'Rewrite Required'),
        ('RESUBMITTED', 'Resubmitted'),
        ('Late', 'Late'),
        ('Graded', 'Graded'),
    )
    assignment = models.ForeignKey(Assignment, on_delete=models.CASCADE, related_name='submissions')
    student = models.ForeignKey(StudentProfile, on_delete=models.CASCADE, related_name='submissions')
    file = models.FileField(upload_to='assignments/submissions/', null=True, blank=True)
    submitted_at = models.DateTimeField(auto_now=True)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='SUBMITTED')
    current_version = models.IntegerField(default=1)
    marks_obtained = models.IntegerField(null=True, blank=True)
    extracted_text = models.TextField(null=True, blank=True)
    ocr_confidence = models.FloatField(default=0.0)
    teacher_feedback = models.TextField(null=True, blank=True)

    class Meta:
        unique_together = ('assignment', 'student')

    def __str__(self):
        return f"{self.student.student_id} - {self.assignment.title} (v{self.current_version})"

class SubmissionVersion(models.Model):
    submission = models.ForeignKey(AssignmentSubmission, on_delete=models.CASCADE, related_name='versions')
    version_number = models.IntegerField(default=1)
    file = models.FileField(upload_to='assignments/submissions/versions/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=30, default='SUBMITTED')
    ocr_text = models.TextField(blank=True, default='')
    ocr_status = models.CharField(max_length=30, default='COMPLETED')
    ocr_confidence = models.FloatField(default=0.0)
    similarity_percentage = models.FloatField(default=0.0)
    originality_percentage = models.FloatField(default=100.0)
    decision = models.CharField(max_length=50, blank=True, default='')
    teacher_feedback = models.TextField(blank=True, default='')

    class Meta:
        ordering = ['version_number']

    def __str__(self):
        return f"{self.submission} v{self.version_number}"

class SubmissionFile(models.Model):
    submission = models.ForeignKey(AssignmentSubmission, on_delete=models.CASCADE, related_name='submission_files')
    version = models.ForeignKey(SubmissionVersion, on_delete=models.CASCADE, related_name='pages', null=True, blank=True)
    file = models.FileField(upload_to='assignments/submissions/pages/')
    page_number = models.IntegerField(default=1)
    ocr_page_text = models.TextField(blank=True, default='')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['page_number']

class OCRResult(models.Model):
    submission = models.ForeignKey(AssignmentSubmission, on_delete=models.CASCADE, related_name='ocr_results')
    version = models.ForeignKey(SubmissionVersion, on_delete=models.CASCADE, related_name='ocr_results', null=True, blank=True)
    ocr_text = models.TextField()
    ocr_status = models.CharField(max_length=30, default='COMPLETED')
    ocr_confidence = models.FloatField(default=0.0)
    page_count = models.IntegerField(default=1)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"OCR for {self.submission} ({self.ocr_status} - {self.ocr_confidence}%)"

class SimilarityResult(models.Model):
    submission = models.OneToOneField(AssignmentSubmission, on_delete=models.CASCADE, related_name='similarity_result')
    version = models.ForeignKey(SubmissionVersion, on_delete=models.CASCADE, null=True, blank=True, related_name='similarity_results')
    similarity_percentage = models.FloatField(default=0.0)
    originality_percentage = models.FloatField(default=100.0)
    highest_match_student = models.CharField(max_length=200, blank=True, default='')
    highest_match_percentage = models.FloatField(default=0.0)
    matched_submission = models.ForeignKey(AssignmentSubmission, on_delete=models.SET_NULL, null=True, blank=True, related_name='matched_by')
    analysis_date = models.DateTimeField(auto_now=True)
    processing_status = models.CharField(max_length=50, default='LOW_SIMILARITY')
    decision = models.CharField(max_length=50, default='ACCEPTED')
    teacher_review_required = models.BooleanField(default=False)
    teacher_feedback = models.TextField(null=True, blank=True)
    potential_matches = models.JSONField(default=list)

    def __str__(self):
        return f"{self.submission}: {self.similarity_percentage}% ({self.processing_status})"

class SimilarityMatch(models.Model):
    source_submission = models.ForeignKey(AssignmentSubmission, on_delete=models.CASCADE, related_name='matches_as_source')
    matched_submission = models.ForeignKey(AssignmentSubmission, on_delete=models.CASCADE, related_name='matches_as_target')
    source_student_name = models.CharField(max_length=200)
    matched_student_name = models.CharField(max_length=200)
    similarity_percentage = models.FloatField()
    matching_text = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-similarity_percentage']

    def __str__(self):
        return f"{self.source_student_name} vs {self.matched_student_name}: {self.similarity_percentage}%"

class TeacherReview(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending Review'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
        ('REWRITE_REQUESTED', 'Rewrite Requested'),
    )
    student = models.ForeignKey(StudentProfile, on_delete=models.CASCADE, related_name='review_requests')
    assignment = models.ForeignKey(Assignment, on_delete=models.CASCADE, related_name='review_requests')
    submission = models.ForeignKey(AssignmentSubmission, on_delete=models.CASCADE, related_name='review_requests')
    version = models.ForeignKey(SubmissionVersion, on_delete=models.CASCADE, null=True, blank=True, related_name='review_requests')
    similarity_score = models.FloatField()
    matched_student = models.CharField(max_length=200, blank=True, default='')
    request_status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='PENDING')
    teacher_feedback = models.TextField(null=True, blank=True)
    reviewed_by = models.ForeignKey(FacultyProfile, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Review for {self.student.student_id} on {self.assignment.title} ({self.request_status})"
