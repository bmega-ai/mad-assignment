from rest_framework import serializers
from .models import Note

class NoteSerializer(serializers.ModelSerializer):
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    subject_code = serializers.CharField(source='subject.code', read_only=True)
    faculty_name = serializers.SerializerMethodField()
    file_url = serializers.SerializerMethodField()
    upload_date_formatted = serializers.SerializerMethodField()

    class Meta:
        model = Note
        fields = [
            'id', 'title', 'subject', 'subject_name', 'subject_code',
            'department', 'year', 'semester', 'file', 'file_url',
            'faculty', 'faculty_name', 'upload_date', 'upload_date_formatted'
        ]

    def get_faculty_name(self, obj):
        if obj.faculty:
            return obj.faculty.user.get_full_name() or obj.faculty.user.username
        return "Faculty"

    def get_file_url(self, obj):
        if obj.file:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.file.url) if request else obj.file.url
        return None

    def get_upload_date_formatted(self, obj):
        return obj.upload_date.strftime("%b %d, %Y") if obj.upload_date else ""
