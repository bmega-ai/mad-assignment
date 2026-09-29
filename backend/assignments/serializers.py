from rest_framework import serializers
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

class SimilarityMatchSerializer(serializers.ModelSerializer):
    class Meta:
        model = SimilarityMatch
        fields = [
            'id', 'source_student_name', 'matched_student_name',
            'similarity_percentage', 'matching_text', 'created_at'
        ]

class SimilarityResultSerializer(serializers.ModelSerializer):
    matches = serializers.SerializerMethodField()

    class Meta:
        model = SimilarityResult
        fields = [
            'id', 'similarity_percentage', 'originality_percentage',
            'highest_match_student', 'highest_match_percentage',
            'processing_status', 'decision', 'teacher_review_required',
            'teacher_feedback', 'potential_matches', 'matches', 'analysis_date'
        ]

    def get_matches(self, obj):
        matches_qs = obj.submission.matches_as_source.all()
        return SimilarityMatchSerializer(matches_qs, many=True).data

class OCRResultSerializer(serializers.ModelSerializer):
    class Meta:
        model = OCRResult
        fields = ['id', 'ocr_text', 'ocr_status', 'ocr_confidence', 'page_count', 'created_at']

class SubmissionFileSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = SubmissionFile
        fields = ['id', 'page_number', 'file', 'file_url', 'ocr_page_text', 'uploaded_at']

    def get_file_url(self, obj):
        if obj.file:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.file.url) if request else obj.file.url
        return None

class SubmissionVersionSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()
    pages = SubmissionFileSerializer(many=True, read_only=True)

    class Meta:
        model = SubmissionVersion
        fields = [
            'id', 'version_number', 'file', 'file_url', 'created_at',
            'status', 'ocr_text', 'ocr_status', 'ocr_confidence',
            'similarity_percentage', 'originality_percentage', 'decision',
            'teacher_feedback', 'pages'
        ]

    def get_file_url(self, obj):
        if obj.file:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.file.url) if request else obj.file.url
        return None

class TeacherReviewSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source='student.user.get_full_name', read_only=True)
    student_id = serializers.CharField(source='student.student_id', read_only=True)
    assignment_title = serializers.CharField(source='assignment.title', read_only=True)
    reviewed_by_name = serializers.CharField(source='reviewed_by.user.get_full_name', read_only=True)

    class Meta:
        model = TeacherReview
        fields = [
            'id', 'student', 'student_id', 'student_name', 'assignment',
            'assignment_title', 'submission', 'version', 'similarity_score',
            'matched_student', 'request_status', 'teacher_feedback',
            'reviewed_by', 'reviewed_by_name', 'created_at', 'reviewed_at'
        ]

class AssignmentSubmissionSerializer(serializers.ModelSerializer):
    similarity = SimilarityResultSerializer(source='similarity_result', read_only=True)
    student_name = serializers.SerializerMethodField()
    student_id = serializers.CharField(source='student.student_id', read_only=True)
    file_url = serializers.SerializerMethodField()
    versions = SubmissionVersionSerializer(many=True, read_only=True)
    pages = SubmissionFileSerializer(source='submission_files', many=True, read_only=True)
    latest_review = serializers.SerializerMethodField()

    class Meta:
        model = AssignmentSubmission
        fields = [
            'id', 'assignment', 'student', 'student_id', 'student_name',
            'file', 'file_url', 'submitted_at', 'status', 'current_version',
            'marks_obtained', 'extracted_text', 'ocr_confidence',
            'teacher_feedback', 'similarity', 'versions', 'pages', 'latest_review'
        ]
        read_only_fields = ['status', 'marks_obtained', 'extracted_text']

    def get_student_name(self, obj):
        return obj.student.user.get_full_name() or obj.student.user.username

    def get_file_url(self, obj):
        if obj.file:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.file.url) if request else obj.file.url
        return None

    def get_latest_review(self, obj):
        rev = obj.review_requests.order_by('-created_at').first()
        if rev:
            return TeacherReviewSerializer(rev).data
        return None

class AssignmentSerializer(serializers.ModelSerializer):
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    subject_code = serializers.CharField(source='subject.code', read_only=True)
    faculty_name = serializers.SerializerMethodField()
    department_name = serializers.CharField(source='department.name', read_only=True)
    attachment_url = serializers.SerializerMethodField()
    user_submission = serializers.SerializerMethodField()
    due_date_formatted = serializers.SerializerMethodField()
    submissions_count = serializers.SerializerMethodField()

    class Meta:
        model = Assignment
        fields = [
            'id', 'title', 'description', 'instructions', 'subject', 'subject_name', 'subject_code',
            'department', 'department_name', 'year', 'section', 'semester',
            'due_date', 'due_date_formatted', 'max_marks', 'attachment', 'attachment_url',
            'faculty', 'faculty_name', 'created_at', 'user_submission', 'submissions_count'
        ]

    def get_faculty_name(self, obj):
        if obj.faculty:
            return obj.faculty.user.get_full_name() or obj.faculty.user.username
        return "Faculty"

    def get_attachment_url(self, obj):
        if obj.attachment:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.attachment.url) if request else obj.attachment.url
        return None

    def get_due_date_formatted(self, obj):
        return obj.due_date.strftime("%b %d, %Y - %I:%M %p") if obj.due_date else ""

    def get_submissions_count(self, obj):
        return obj.submissions.count()

    def get_user_submission(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated and request.user.role == 'student' and hasattr(request.user, 'student_profile'):
            sub = AssignmentSubmission.objects.filter(
                assignment=obj,
                student=request.user.student_profile
            ).first()
            if sub:
                sim_res = getattr(sub, 'similarity_result', None)
                sim_pct = sim_res.similarity_percentage if sim_res else 0.0
                orig_pct = sim_res.originality_percentage if sim_res else 100.0
                highest_match = sim_res.highest_match_student if sim_res else ""
                decision = sim_res.decision if sim_res else sub.status

                return {
                    "id": sub.id,
                    "status": sub.status,
                    "current_version": sub.current_version,
                    "submitted_at": sub.submitted_at.strftime("%b %d, %Y - %I:%M %p"),
                    "marks_obtained": sub.marks_obtained,
                    "file_url": request.build_absolute_uri(sub.file.url) if sub.file else None,
                    "similarity_percentage": sim_pct,
                    "originality_percentage": orig_pct,
                    "highest_match_student": highest_match,
                    "decision": decision,
                    "teacher_feedback": sub.teacher_feedback,
                    "ocr_confidence": sub.ocr_confidence,
                }
        return None
