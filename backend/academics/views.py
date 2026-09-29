from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import generics, status
from django.db.models import Count, Q

from .models import Subject, Timetable, Attendance
from .serializers import SubjectSerializer, TimetableSerializer, AttendanceSerializer

class SubjectListView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = SubjectSerializer

    def get_queryset(self):
        user = self.request.user
        qs = Subject.objects.all().select_related('department', 'faculty', 'faculty__user')
        if user.role == 'student' and hasattr(user, 'student_profile'):
            sp = user.student_profile
            qs = qs.filter(department=sp.department, year=sp.year, semester=sp.semester)
        elif user.role == 'faculty' and hasattr(user, 'faculty_profile'):
            fp = user.faculty_profile
            qs = qs.filter(faculty=fp)
        return qs

class TimetableListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = TimetableSerializer

    def get_queryset(self):
        user = self.request.user
        qs = Timetable.objects.all().select_related('subject', 'department', 'subject__faculty', 'subject__faculty__user')

        day = self.request.query_params.get('day')
        if day:
            qs = qs.filter(day__iexact=day)

        if user.role == 'student' and hasattr(user, 'student_profile'):
            sp = user.student_profile
            qs = qs.filter(department=sp.department, year=sp.year, section=sp.section)
        elif user.role == 'faculty' and hasattr(user, 'faculty_profile'):
            fp = user.faculty_profile
            qs = qs.filter(subject__faculty=fp)
        
        return qs.order_by('day', 'start_time')

class AttendanceListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role == 'student' and hasattr(user, 'student_profile'):
            sp = user.student_profile
            records = Attendance.objects.filter(student=sp).select_related('subject').order_by('-date')
            
            # Subject-wise summary
            subjects = Subject.objects.filter(attendance__student=sp).distinct()
            subject_summaries = []
            for sub in subjects:
                sub_att = Attendance.objects.filter(student=sp, subject=sub)
                total = sub_att.count()
                present = sub_att.filter(status=True).count()
                pct = round((present / total * 100), 1) if total > 0 else 0
                subject_summaries.append({
                    "subject_id": sub.id,
                    "subject_name": sub.name,
                    "subject_code": sub.code,
                    "total_classes": total,
                    "attended_classes": present,
                    "percentage": pct
                })

            total_count = records.count()
            present_count = records.filter(status=True).count()
            overall_pct = round((present_count / total_count * 100), 1) if total_count > 0 else 0

            serializer = AttendanceSerializer(records[:50], many=True)
            return Response({
                "overall_percentage": overall_pct,
                "total_classes": total_count,
                "attended_classes": present_count,
                "missed_classes": total_count - present_count,
                "subject_summary": subject_summaries,
                "recent_records": serializer.data
            })
        elif user.role in ['faculty', 'admin']:
            subject_id = request.query_params.get('subject_id')
            qs = Attendance.objects.all().select_related('student', 'student__user', 'subject')
            if subject_id:
                qs = qs.filter(subject_id=subject_id)
            serializer = AttendanceSerializer(qs[:100], many=True)
            return Response({"records": serializer.data})
            
        return Response({"error": "Profile not found"}, status=status.HTTP_400_BAD_REQUEST)

    def post(self, request):
        user = request.user
        if user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)
        
        student_id = request.data.get('student_id')
        subject_id = request.data.get('subject_id')
        date_val = request.data.get('date')
        status_val = request.data.get('status', True)

        try:
            attendance = Attendance.objects.create(
                student_id=student_id,
                subject_id=subject_id,
                date=date_val,
                status=status_val
            )
            return Response(AttendanceSerializer(attendance).data, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
