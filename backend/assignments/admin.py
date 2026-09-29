from django.contrib import admin
from .models import (
    Assignment,
    AssignmentSubmission,
    SubmissionVersion,
    SubmissionFile,
    OCRResult,
    SimilarityResult,
    SimilarityMatch,
    TeacherReview,
)

@admin.register(Assignment)
class AssignmentAdmin(admin.ModelAdmin):
    list_display = ['title', 'subject', 'department', 'year', 'section', 'due_date', 'max_marks', 'faculty']
    list_filter = ['department', 'year', 'section', 'subject']
    search_fields = ['title', 'description']

@admin.register(AssignmentSubmission)
class AssignmentSubmissionAdmin(admin.ModelAdmin):
    list_display = ['assignment', 'student', 'current_version', 'status', 'marks_obtained', 'ocr_confidence', 'submitted_at']
    list_filter = ['status', 'assignment']
    search_fields = ['student__student_id', 'assignment__title']

@admin.register(SubmissionVersion)
class SubmissionVersionAdmin(admin.ModelAdmin):
    list_display = ['submission', 'version_number', 'status', 'similarity_percentage', 'created_at']

@admin.register(SubmissionFile)
class SubmissionFileAdmin(admin.ModelAdmin):
    list_display = ['submission', 'version', 'page_number', 'uploaded_at']

@admin.register(OCRResult)
class OCRResultAdmin(admin.ModelAdmin):
    list_display = ['submission', 'version', 'ocr_status', 'ocr_confidence', 'page_count', 'created_at']

@admin.register(SimilarityResult)
class SimilarityResultAdmin(admin.ModelAdmin):
    list_display = ['submission', 'similarity_percentage', 'originality_percentage', 'highest_match_student', 'processing_status']

@admin.register(SimilarityMatch)
class SimilarityMatchAdmin(admin.ModelAdmin):
    list_display = ['source_submission', 'source_student_name', 'matched_student_name', 'similarity_percentage']

@admin.register(TeacherReview)
class TeacherReviewAdmin(admin.ModelAdmin):
    list_display = ['student', 'assignment', 'similarity_score', 'matched_student', 'request_status', 'created_at']
    list_filter = ['request_status']
