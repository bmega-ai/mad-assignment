from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import User, Department, StudentProfile, FacultyProfile

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        token['username'] = user.username
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        user = self.user
        data['user_id'] = user.id
        data['username'] = user.username
        data['role'] = user.role
        data['first_name'] = user.first_name
        data['last_name'] = user.last_name
        data['email'] = user.email

        if user.role == 'student' and hasattr(user, 'student_profile'):
            sp = user.student_profile
            data['student_id'] = sp.student_id
            data['department'] = sp.department.name if sp.department else None
            data['department_code'] = sp.department.code if sp.department else None
            data['year'] = sp.year
            data['section'] = sp.section
            data['semester'] = sp.semester
        elif user.role == 'faculty' and hasattr(user, 'faculty_profile'):
            fp = user.faculty_profile
            data['faculty_id'] = fp.faculty_id
            data['department'] = fp.department.name if fp.department else None
            data['designation'] = fp.designation
            data['office'] = fp.office
        elif user.role == 'admin':
            data['admin_id'] = user.username

        return data

class DepartmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Department
        fields = '__all__'

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 'role', 'profile_image']

class StudentProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    department_name = serializers.CharField(source='department.name', read_only=True)

    class Meta:
        model = StudentProfile
        fields = '__all__'

class FacultyProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    department_name = serializers.CharField(source='department.name', read_only=True)
    name = serializers.SerializerMethodField()
    email = serializers.SerializerMethodField()

    class Meta:
        model = FacultyProfile
        fields = ['id', 'faculty_id', 'designation', 'office', 'phone', 'department_name', 'name', 'email', 'user']

    def get_name(self, obj):
        full_name = obj.user.get_full_name()
        return full_name if full_name.strip() else obj.user.username

    def get_email(self, obj):
        return obj.user.email
