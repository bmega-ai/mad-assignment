from rest_framework import serializers
from .models import Subject, Timetable, Attendance
from accounts.serializers import DepartmentSerializer, FacultyProfileSerializer

class SubjectSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)
    faculty_name = serializers.SerializerMethodField()

    class Meta:
        model = Subject
        fields = ['id', 'name', 'code', 'department', 'department_name', 'year', 'semester', 'faculty', 'faculty_name']

    def get_faculty_name(self, obj):
        if obj.faculty:
            return obj.faculty.user.get_full_name() or obj.faculty.user.username
        return "Not Assigned"

class TimetableSerializer(serializers.ModelSerializer):
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    subject_code = serializers.CharField(source='subject.code', read_only=True)
    faculty_name = serializers.SerializerMethodField()
    start_time_formatted = serializers.SerializerMethodField()
    end_time_formatted = serializers.SerializerMethodField()

    class Meta:
        model = Timetable
        fields = [
            'id', 'department', 'year', 'section', 'day',
            'start_time', 'end_time', 'start_time_formatted', 'end_time_formatted',
            'subject', 'subject_name', 'subject_code', 'faculty_name', 'room'
        ]

    def get_faculty_name(self, obj):
        if obj.subject and obj.subject.faculty:
            return obj.subject.faculty.user.get_full_name() or obj.subject.faculty.user.username
        return "Faculty"

    def get_start_time_formatted(self, obj):
        return obj.start_time.strftime("%I:%M %p") if obj.start_time else ""

    def get_end_time_formatted(self, obj):
        return obj.end_time.strftime("%I:%M %p") if obj.end_time else ""

class AttendanceSerializer(serializers.ModelSerializer):
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    subject_code = serializers.CharField(source='subject.code', read_only=True)
    student_id = serializers.CharField(source='student.student_id', read_only=True)
    student_profile_id = serializers.IntegerField(source='student.id', read_only=True)
    student_name = serializers.SerializerMethodField()

    class Meta:
        model = Attendance
        fields = [
            'id', 'student', 'student_profile_id', 'student_id', 'student_name',
            'subject', 'subject_name', 'subject_code', 'date', 'status'
        ]

    def get_student_name(self, obj):
        return obj.student.user.get_full_name() or obj.student.user.username
