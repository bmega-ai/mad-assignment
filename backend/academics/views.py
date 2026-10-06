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
            faculty_subjects = qs.filter(faculty=fp)
            if faculty_subjects.exists():
                qs = faculty_subjects
            elif fp.department:
                dept_subjects = qs.filter(department=fp.department)
                qs = dept_subjects if dept_subjects.exists() else qs
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

from datetime import datetime, date
from accounts.models import StudentProfile

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
            date_val = request.query_params.get('date')
            student_id = request.query_params.get('student_id')

            qs = Attendance.objects.all().select_related('student', 'student__user', 'subject')
            
            # If faculty, limit to their assigned subjects if desired
            if user.role == 'faculty' and hasattr(user, 'faculty_profile'):
                fp = user.faculty_profile
                faculty_subjects = Subject.objects.filter(faculty=fp)
                if faculty_subjects.exists() and not subject_id:
                    qs = qs.filter(subject__in=faculty_subjects)

            if subject_id:
                qs = qs.filter(subject_id=subject_id)
            if date_val:
                qs = qs.filter(date=date_val)
            if student_id:
                qs = qs.filter(student__student_id__icontains=student_id)

            qs = qs.order_by('-date', 'student__student_id')
            total = qs.count()
            present = qs.filter(status=True).count()
            absent = total - present

            serializer = AttendanceSerializer(qs[:200], many=True)
            return Response({
                "records": serializer.data,
                "total_records": total,
                "present_count": present,
                "absent_count": absent
            })
            
        return Response({"error": "Profile not found"}, status=status.HTTP_400_BAD_REQUEST)

    def post(self, request):
        user = request.user
        if user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)
        
        # Check for bulk attendance submission
        records = request.data.get('records')
        subject_id = request.data.get('subject_id')
        date_val = request.data.get('date') or str(date.today())

        if records and isinstance(records, list):
            if not subject_id:
                first_sub = Subject.objects.first()
                if first_sub:
                    subject_id = first_sub.id
                else:
                    return Response({"error": "subject_id is required for recording attendance."}, status=status.HTTP_400_BAD_REQUEST)

            saved_items = []
            for item in records:
                s_id = item.get('student_id')
                status_val = item.get('status', True)
                if s_id is not None:
                    att_obj, _ = Attendance.objects.update_or_create(
                        student_id=s_id,
                        subject_id=subject_id,
                        date=date_val,
                        defaults={'status': bool(status_val)}
                    )
                    saved_items.append(att_obj)

            return Response({
                "message": f"Successfully updated attendance for {len(saved_items)} students.",
                "count": len(saved_items),
                "date": date_val,
                "subject_id": subject_id
            }, status=status.HTTP_200_OK)

        # Single attendance submission
        student_id = request.data.get('student_id')
        status_val = request.data.get('status', True)

        try:
            attendance, created = Attendance.objects.update_or_create(
                student_id=student_id,
                subject_id=subject_id,
                date=date_val,
                defaults={'status': bool(status_val)}
            )
            return Response(
                AttendanceSerializer(attendance).data,
                status=status.HTTP_201_CREATED if created else status.HTTP_200_OK
            )
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class AttendanceStudentsView(APIView):
    """
    Returns list of students for a given subject and date so faculty can mark or update attendance.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)

        subject_id = request.query_params.get('subject_id')
        date_str = request.query_params.get('date') or str(date.today())

        students_qs = StudentProfile.objects.all().select_related('user', 'department')
        
        subject = None
        if subject_id:
            try:
                subject = Subject.objects.select_related('department').get(id=subject_id)
                filtered = students_qs.filter(
                    department=subject.department,
                    year=subject.year,
                    semester=subject.semester
                )
                if filtered.exists():
                    students_qs = filtered
                elif subject.department:
                    dept_students = students_qs.filter(department=subject.department)
                    if dept_students.exists():
                        students_qs = dept_students
            except Subject.DoesNotExist:
                pass

        # Check existing attendance for this subject and date
        existing_attendance = {}
        if subject_id and date_str:
            att_qs = Attendance.objects.filter(subject_id=subject_id, date=date_str)
            for a in att_qs:
                existing_attendance[a.student_id] = {
                    "attendance_id": a.id,
                    "status": a.status
                }

        results = []
        for sp in students_qs.order_by('student_id'):
            att_info = existing_attendance.get(sp.id)
            results.append({
                "id": sp.id,
                "student_id": sp.student_id,
                "name": sp.user.get_full_name() or sp.user.username,
                "department": sp.department.code if sp.department else "CSE",
                "year": sp.year,
                "section": sp.section,
                "semester": sp.semester,
                "is_marked": att_info is not None,
                "attendance_id": att_info["attendance_id"] if att_info else None,
                "status": att_info["status"] if att_info else True, # default to Present
                "is_online": getattr(sp, 'is_online', False),
            })

        return Response({
            "subject_id": subject_id,
            "subject_name": subject.name if subject else "All Classes",
            "subject_code": subject.code if subject else "",
            "date": date_str,
            "already_marked": bool(existing_attendance),
            "students": results,
            "total_students": len(results)
        })


class AttendanceDetailView(APIView):
    """
    Update (toggle status) or delete a single attendance record.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            att = Attendance.objects.select_related('student', 'student__user', 'subject').get(pk=pk)
            return Response(AttendanceSerializer(att).data)
        except Attendance.DoesNotExist:
            return Response({"error": "Attendance record not found"}, status=status.HTTP_404_NOT_FOUND)

    def patch(self, request, pk):
        user = request.user
        if user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)

        try:
            att = Attendance.objects.get(pk=pk)
            if 'status' in request.data:
                att.status = bool(request.data['status'])
            if 'date' in request.data:
                att.date = request.data['date']
            att.save()
            return Response(AttendanceSerializer(att).data, status=status.HTTP_200_OK)
        except Attendance.DoesNotExist:
            return Response({"error": "Attendance record not found"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        user = request.user
        if user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)

        try:
            att = Attendance.objects.get(pk=pk)
            att.delete()
            return Response({"message": "Attendance record deleted successfully."}, status=status.HTTP_200_OK)
        except Attendance.DoesNotExist:
            return Response({"error": "Attendance record not found"}, status=status.HTTP_404_NOT_FOUND)

