from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework import generics, status
from rest_framework_simplejwt.views import TokenObtainPairView
from datetime import datetime, date

from .models import User, Department, StudentProfile, FacultyProfile
from .serializers import (
    CustomTokenObtainPairSerializer,
    StudentProfileSerializer,
    FacultyProfileSerializer,
    UserSerializer,
)

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        data = {
            "id": user.id,
            "username": user.username,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "full_name": user.get_full_name() or user.username,
            "email": user.email,
            "role": user.role,
            "profile_image": request.build_absolute_uri(user.profile_image.url) if user.profile_image else None,
        }
        if user.role == 'student' and hasattr(user, 'student_profile'):
            profile = user.student_profile
            data.update({
                "student_id": profile.student_id,
                "department": profile.department.name if profile.department else None,
                "department_code": profile.department.code if profile.department else None,
                "year": profile.year,
                "section": profile.section,
                "semester": profile.semester,
                "phone": profile.phone,
            })
        elif user.role == 'faculty' and hasattr(user, 'faculty_profile'):
            profile = user.faculty_profile
            data.update({
                "faculty_id": profile.faculty_id,
                "designation": profile.designation,
                "office": profile.office,
                "department": profile.department.name if profile.department else None,
                "phone": profile.phone,
                "status": profile.status,
            })
        elif user.role == 'admin':
            data.update({
                "admin_id": user.username,
                "department": "Administration",
            })
        return Response(data)

class StudentDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        from academics.models import Timetable, Attendance
        from assignments.models import Assignment, AssignmentSubmission
        from events.models import Event
        from notifications.models import Notification

        day_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        today_name = day_names[datetime.now().weekday()]

        student_info = {}
        today_classes = []
        attendance_stats = {"percentage": 0.0, "total": 0, "present": 0, "absent": 0}
        pending_assignments = 0
        submitted_assignments = 0
        upcoming_events_count = 0
        unread_notifications = 0

        if user.role == 'student' and hasattr(user, 'student_profile'):
            sp = user.student_profile
            student_info = {
                "name": user.get_full_name() or user.username,
                "student_id": sp.student_id,
                "department": sp.department.name if sp.department else "CSE",
                "year": sp.year,
                "section": sp.section,
                "semester": sp.semester,
            }

            tt_qs = Timetable.objects.filter(
                department=sp.department,
                year=sp.year,
                section=sp.section,
                day=today_name
            ).order_by('start_time')

            today_classes = [
                {
                    "id": item.id,
                    "subject": item.subject.name,
                    "subject_code": item.subject.code,
                    "faculty": item.subject.faculty.user.get_full_name() if item.subject.faculty else "Faculty",
                    "room": item.room,
                    "start_time": item.start_time.strftime("%I:%M %p"),
                    "end_time": item.end_time.strftime("%I:%M %p"),
                }
                for item in tt_qs
            ]

            att_qs = Attendance.objects.filter(student=sp)
            total_att = att_qs.count()
            present_att = att_qs.filter(status=True).count()
            absent_att = total_att - present_att
            pct = round((present_att / total_att * 100), 1) if total_att > 0 else 88.5
            attendance_stats = {
                "percentage": pct,
                "total": total_att,
                "present": present_att,
                "absent": absent_att
            }

            all_assigns = Assignment.objects.filter(
                department=sp.department,
                year=sp.year,
                semester=sp.semester
            )
            submitted_ids = AssignmentSubmission.objects.filter(
                student=sp
            ).values_list('assignment_id', flat=True)
            pending_assignments = all_assigns.exclude(id__in=submitted_ids).count()
            submitted_assignments = AssignmentSubmission.objects.filter(student=sp).count()

        upcoming_events_count = Event.objects.filter(date__gte=date.today()).count()
        unread_notifications = Notification.objects.filter(user=user, is_read=False).count()

        return Response({
            "student": student_info,
            "today_day": today_name,
            "today_classes": today_classes,
            "attendance": attendance_stats,
            "pending_assignments_count": pending_assignments,
            "submitted_assignments_count": submitted_assignments,
            "upcoming_events_count": upcoming_events_count,
            "unread_notifications_count": unread_notifications,
        })

class TeacherDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)

        from assignments.models import Assignment, AssignmentSubmission, TeacherReview
        from academics.models import Subject

        fp = getattr(user, 'faculty_profile', None)
        assignments_qs = Assignment.objects.filter(faculty=fp) if fp else Assignment.objects.all()
        submissions_qs = AssignmentSubmission.objects.filter(assignment__in=assignments_qs)

        to_review_count = submissions_qs.filter(
            status__in=['REVIEW_REQUESTED', 'HIGH_SIMILARITY', 'OCR_REVIEW_REQUIRED']
        ).count()

        classes_count = Subject.objects.filter(faculty=fp).count() if fp else 5

        recent_submissions = [
            {
                "id": s.id,
                "student_id": s.student.student_id,
                "student_name": s.student.user.get_full_name() or s.student.user.username,
                "assignment_title": s.assignment.title,
                "status": s.status,
                "version": s.current_version,
                "similarity_percentage": getattr(getattr(s, 'similarity_result', None), 'similarity_percentage', 0.0),
                "submitted_at": s.submitted_at.strftime("%b %d, %I:%M %p"),
            }
            for s in submissions_qs.order_by('-submitted_at')[:8]
        ]

        return Response({
            "teacher": {
                "name": user.get_full_name() or user.username,
                "designation": fp.designation if fp else "Faculty",
                "department": fp.department.name if fp and fp.department else "Computer Science & Engineering",
                "office": fp.office if fp else "Room 304",
            },
            "assignments_count": assignments_qs.count(),
            "submissions_count": submissions_qs.count(),
            "to_review_count": to_review_count,
            "classes_count": max(classes_count, 1),
            "recent_submissions": recent_submissions,
        })

class TeacherRegistrationView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        full_name = request.data.get('full_name', '').strip()
        teacher_id = request.data.get('teacher_id', '').strip()
        email = request.data.get('email', '').strip()
        phone = request.data.get('phone', '').strip()
        dept_code_or_name = request.data.get('department', 'CSE').strip()
        designation = request.data.get('designation', 'Assistant Professor').strip()
        password = request.data.get('password', '')
        confirm_password = request.data.get('confirm_password', '')
        profile_photo = request.FILES.get('profile_photo')

        # Validations
        if not full_name or not teacher_id or not email or not password:
            return Response(
                {"error": "Please provide full name, teacher ID, email, and password."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if password != confirm_password:
            return Response(
                {"error": "Passwords do not match."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(username__iexact=teacher_id).exists():
            return Response(
                {"error": f"Teacher ID '{teacher_id}' is already registered."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(email__iexact=email).exists():
            return Response(
                {"error": f"Email '{email}' is already in use."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Department
        dept = Department.objects.filter(code__iexact=dept_code_or_name).first()
        if not dept:
            dept = Department.objects.filter(name__icontains=dept_code_or_name).first()
        if not dept:
            dept = Department.objects.first()

        # Split full name into first and last
        name_parts = full_name.split(' ', 1)
        first_name = name_parts[0]
        last_name = name_parts[1] if len(name_parts) > 1 else ""

        # Create user
        user = User.objects.create_user(
            username=teacher_id,
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name,
            role='faculty',
            profile_image=profile_photo
        )

        # Create FacultyProfile with PENDING status
        faculty_profile = FacultyProfile.objects.create(
            user=user,
            faculty_id=teacher_id,
            department=dept,
            designation=designation,
            office="Staff Room",
            phone=phone,
            status='PENDING'
        )

        return Response({
            "message": "Teacher registered successfully. Account is pending administrator approval.",
            "teacher_id": teacher_id,
            "full_name": full_name,
            "status": "PENDING"
        }, status=status.HTTP_201_CREATED)

class FacultyListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = FacultyProfileSerializer
    queryset = FacultyProfile.objects.all().select_related('user', 'department')
