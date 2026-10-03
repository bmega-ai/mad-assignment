from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import generics, status
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.core.files.base import ContentFile
from django.db.models import Q

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
from .serializers import (
    AssignmentSerializer,
    AssignmentSubmissionSerializer,
    SubmissionVersionSerializer,
    OCRResultSerializer,
    SimilarityResultSerializer,
    SimilarityMatchSerializer,
    TeacherReviewSerializer,
)
from plagiarism.ocr_engine import extract_assignment_text
from plagiarism.services import run_multi_student_similarity
from notifications.models import Notification

def send_notification(user, title, message):
    try:
        Notification.objects.create(user=user, title=title, message=message)
    except Exception as e:
        print(f"Notification error: {e}")

class AssignmentListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = AssignmentSerializer

    def get_queryset(self):
        user = self.request.user
        qs = Assignment.objects.all().select_related('subject', 'department', 'faculty', 'faculty__user')
        if user.role == 'student' and hasattr(user, 'student_profile'):
            sp = user.student_profile
            qs = qs.filter(department=sp.department, year=sp.year, semester=sp.semester)
        elif user.role == 'faculty' and hasattr(user, 'faculty_profile'):
            fp = user.faculty_profile
            fac_qs = qs.filter(Q(faculty=fp) | Q(subject__faculty=fp))
            if fac_qs.exists():
                qs = fac_qs
            elif fp.department:
                qs = qs.filter(department=fp.department)
        return qs.order_by('-due_date')

    def perform_create(self, serializer):
        user = self.request.user
        faculty = getattr(user, 'faculty_profile', None)
        serializer.save(faculty=faculty)

class AssignmentDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = AssignmentSerializer
    queryset = Assignment.objects.all().select_related('subject', 'department', 'faculty', 'faculty__user')

def process_submission_pipeline(submission, version, primary_file, additional_files, raw_text, request_user):
    """
    Core pipeline:
    1. Extract OCR text (handles multi-page images, scans, and PDFs)
    2. Store OCRResult and update SubmissionFile pages
    3. Run Multi-Student Similarity check against other students' submissions for the SAME assignment
    4. Store SimilarityResult & SimilarityMatch records
    5. Apply the 70% threshold rule and send automated notifications
    """
    assignment = submission.assignment
    student = submission.student

    # 1. OCR Extraction
    extracted_text, ocr_conf, ocr_status, page_count = extract_assignment_text(
        primary_file, additional_files=additional_files, direct_text=raw_text
    )

    # Store OCR Result
    OCRResult.objects.create(
        submission=submission,
        version=version,
        ocr_text=extracted_text,
        ocr_status=ocr_status,
        ocr_confidence=ocr_conf,
        page_count=page_count
    )

    # Update Submission & Version text
    submission.extracted_text = extracted_text
    submission.ocr_confidence = ocr_conf
    version.ocr_text = extracted_text
    version.ocr_status = ocr_status
    version.ocr_confidence = ocr_conf

    # 2. Multi-Student Similarity Comparison
    # Collect all OTHER students' submissions for this exact assignment
    other_submissions = AssignmentSubmission.objects.filter(
        assignment=assignment
    ).exclude(student=student).select_related('student', 'student__user')

    candidates = []
    for o_sub in other_submissions:
        txt = o_sub.extracted_text or ""
        if txt.strip():
            candidates.append({
                "id": o_sub.id,
                "student_id": o_sub.student.student_id,
                "student_name": o_sub.student.user.get_full_name() or o_sub.student.user.username,
                "text": txt,
                "submission_obj": o_sub,
            })

    highest_sim, originality, proc_status, decision, matches, top_match = run_multi_student_similarity(
        extracted_text, candidates
    )

    # 3. Save Similarity Result & Matches
    # Delete old matches for this submission
    SimilarityMatch.objects.filter(source_submission=submission).delete()

    for m in matches:
        target_sub = next((c["submission_obj"] for c in candidates if c["id"] == m["submission_id"]), None)
        if target_sub:
            SimilarityMatch.objects.create(
                source_submission=submission,
                matched_submission=target_sub,
                source_student_name=student.user.get_full_name() or student.user.username,
                matched_student_name=m["student_name"],
                similarity_percentage=m["similarity_percentage"],
                matching_text=m["matching_text"]
            )

    top_matched_sub = next((c["submission_obj"] for c in candidates if c["id"] == top_match.get("submission_id")), None) if top_match else None

    sim_result, _ = SimilarityResult.objects.update_or_create(
        submission=submission,
        defaults={
            "version": version,
            "similarity_percentage": highest_sim,
            "originality_percentage": originality,
            "highest_match_student": top_match.get("student_name", ""),
            "highest_match_percentage": top_match.get("similarity_percentage", 0.0),
            "matched_submission": top_matched_sub,
            "processing_status": proc_status,
            "decision": decision,
            "teacher_review_required": (highest_sim > 70.0),
            "potential_matches": matches
        }
    )

    version.similarity_percentage = highest_sim
    version.originality_percentage = originality
    version.decision = decision

    # 4. Apply Status & Threshold Rules
    if ocr_status == "OCR_REVIEW_REQUIRED":
        submission.status = "OCR_REVIEW_REQUIRED"
        version.status = "OCR_REVIEW_REQUIRED"
        send_notification(
            student.user,
            "OCR Notice: Review Required",
            f"Some handwritten text in '{assignment.title}' could not be recognized with high confidence. Your teacher can inspect the original handwritten submission."
        )
    elif highest_sim > 70.0:
        submission.status = "REJECTED"
        version.status = "REJECTED"
        send_notification(
            student.user,
            "🔴 High Similarity Detected (>70%)",
            f"Your submission for '{assignment.title}' has a similarity score of {highest_sim}%. Status: REJECTED — REWRITE REQUIRED. You may Request Teacher Review or Rewrite & Resubmit."
        )
        if assignment.faculty and assignment.faculty.user:
            send_notification(
                assignment.faculty.user,
                "⚠ High Similarity Flagged",
                f"{student.user.get_full_name()}'s submission for '{assignment.title}' flagged with {highest_sim}% similarity."
            )
    else:
        submission.status = "SUBMITTED"
        version.status = "SUBMITTED"
        send_notification(
            student.user,
            "✓ Assignment Analyzed",
            f"Your submission for '{assignment.title}' passed similarity check with {highest_sim}% similarity ({originality}% originality)."
        )

    submission.save()
    version.save()
    return sim_result

class AssignmentSubmitView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        if user.role != 'student' or not hasattr(user, 'student_profile'):
            return Response({"error": "Only students can submit assignments."}, status=status.HTTP_403_FORBIDDEN)

        assignment = get_object_or_404(Assignment, pk=pk)
        student = user.student_profile

        primary_file = request.FILES.get('file')
        additional_files = request.FILES.getlist('pages')
        raw_text = request.data.get('text', '')

        if not primary_file and not additional_files and not raw_text:
            return Response({"error": "Please provide a document, handwritten page scans, or text."}, status=status.HTTP_400_BAD_REQUEST)

        # If only additional_files provided
        if not primary_file and additional_files:
            primary_file = additional_files[0]
            additional_files = additional_files[1:]

        # If only text provided
        if not primary_file and raw_text:
            primary_file = ContentFile(raw_text.encode('utf-8'), name=f"{student.student_id}_{assignment.id}_v1.txt")

        # Get or create submission
        submission, created = AssignmentSubmission.objects.get_or_create(
            assignment=assignment,
            student=student,
            defaults={'file': primary_file, 'status': 'PROCESSING', 'current_version': 1}
        )

        version_num = submission.current_version if not created else 1
        if not created:
            # Resubmitting / updating initial submission
            submission.file = primary_file
            submission.status = 'PROCESSING'
            submission.save()

        # Create Version record
        version, _ = SubmissionVersion.objects.get_or_create(
            submission=submission,
            version_number=version_num,
            defaults={'file': primary_file, 'status': 'PROCESSING'}
        )

        # Save individual handwritten pages
        if additional_files:
            for idx, p_file in enumerate([primary_file] + additional_files):
                SubmissionFile.objects.create(
                    submission=submission,
                    version=version,
                    file=p_file,
                    page_number=idx + 1
                )

        # Execute OCR & Similarity Pipeline
        sim_result = process_submission_pipeline(
            submission, version, primary_file, additional_files, raw_text, user
        )

        response_data = AssignmentSubmissionSerializer(submission, context={'request': request}).data
        return Response(response_data, status=status.HTTP_201_CREATED)

class SubmissionDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = AssignmentSubmissionSerializer
    queryset = AssignmentSubmission.objects.all().select_related('assignment', 'student', 'student__user')

class SubmissionStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        submission = get_object_or_404(AssignmentSubmission, pk=pk)
        sim_res = getattr(submission, 'similarity_result', None)
        return Response({
            "id": submission.id,
            "status": submission.status,
            "current_version": submission.current_version,
            "similarity_percentage": sim_res.similarity_percentage if sim_res else 0.0,
            "originality_percentage": sim_res.originality_percentage if sim_res else 100.0,
            "highest_match_student": sim_res.highest_match_student if sim_res else "",
            "decision": sim_res.decision if sim_res else submission.status,
            "ocr_status": getattr(submission.ocr_results.last(), 'ocr_status', 'COMPLETED'),
            "ocr_confidence": submission.ocr_confidence,
            "teacher_feedback": submission.teacher_feedback,
        })

class SubmissionOCRView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        submission = get_object_or_404(AssignmentSubmission, pk=pk)
        ocr = submission.ocr_results.order_by('-created_at').first()
        if ocr:
            return Response(OCRResultSerializer(ocr).data)
        return Response({
            "ocr_text": submission.extracted_text or "",
            "ocr_status": "COMPLETED",
            "ocr_confidence": submission.ocr_confidence,
            "page_count": submission.submission_files.count() or 1
        })

class SubmissionSimilarityView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        submission = get_object_or_404(AssignmentSubmission, pk=pk)
        sim_res = getattr(submission, 'similarity_result', None)
        if sim_res:
            return Response(SimilarityResultSerializer(sim_res).data)
        return Response({"similarity_percentage": 0.0, "originality_percentage": 100.0, "matches": []})

class SubmissionMatchesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        submission = get_object_or_404(AssignmentSubmission, pk=pk)
        matches = submission.matches_as_source.all()
        return Response(SimilarityMatchSerializer(matches, many=True).data)

class SubmissionVersionsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        submission = get_object_or_404(AssignmentSubmission, pk=pk)
        versions = submission.versions.all().order_by('version_number')
        return Response(SubmissionVersionSerializer(versions, many=True, context={'request': request}).data)

class SubmissionReviewRequestView(APIView):
    """
    OPTION 1: Student requests teacher review for high similarity submission
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        submission = get_object_or_404(AssignmentSubmission, pk=pk)

        if user.role != 'student' or submission.student.user != user:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)

        sim_res = getattr(submission, 'similarity_result', None)
        sim_score = sim_res.similarity_percentage if sim_res else 0.0
        matched_st = sim_res.highest_match_student if sim_res else ""

        # Update submission status
        submission.status = "REVIEW_REQUESTED"
        submission.save()

        # Create TeacherReview request
        review_req = TeacherReview.objects.create(
            student=submission.student,
            assignment=submission.assignment,
            submission=submission,
            version=submission.versions.order_by('-version_number').first(),
            similarity_score=sim_score,
            matched_student=matched_st,
            request_status='PENDING'
        )

        # Notify Teacher
        teacher_user = submission.assignment.faculty.user if submission.assignment.faculty else None
        if teacher_user:
            send_notification(
                teacher_user,
                "⚠ Review Request",
                f"Assignment review requested by {user.get_full_name()}. Similarity score: {sim_score}%. Please review original submission."
            )

        # Notify Student
        send_notification(
            user,
            "Review Request Submitted",
            f"Your request to review '{submission.assignment.title}' has been sent to your teacher."
        )

        return Response({
            "message": "Review request submitted to teacher successfully.",
            "review_id": review_req.id,
            "status": "REVIEW_REQUESTED"
        }, status=status.HTTP_201_CREATED)

class SubmissionResubmitView(APIView):
    """
    OPTION 2: Student rewrites and resubmits assignment -> creates a NEW version (v2, v3...)
    without overwriting previous version!
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        submission = get_object_or_404(AssignmentSubmission, pk=pk)

        if user.role != 'student' or submission.student.user != user:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)

        primary_file = request.FILES.get('file')
        additional_files = request.FILES.getlist('pages')
        raw_text = request.data.get('text', '')

        if not primary_file and not additional_files and not raw_text:
            return Response({"error": "Please provide your revised assignment file, handwritten scans, or text."}, status=status.HTTP_400_BAD_REQUEST)

        # Increment version number
        new_version_num = submission.current_version + 1
        submission.current_version = new_version_num
        submission.status = "RESUBMITTED"
        if primary_file:
            submission.file = primary_file
        submission.save()

        # Create new SubmissionVersion record
        new_version = SubmissionVersion.objects.create(
            submission=submission,
            version_number=new_version_num,
            file=primary_file,
            status="RESUBMITTED"
        )

        # Save pages if provided
        if additional_files:
            for idx, p_file in enumerate([primary_file] + additional_files):
                SubmissionFile.objects.create(
                    submission=submission,
                    version=new_version,
                    file=p_file,
                    page_number=idx + 1
                )

        # Process OCR & Multi-Student Similarity for the new version
        sim_result = process_submission_pipeline(
            submission, new_version, primary_file, additional_files, raw_text, user
        )

        # Notify Teacher of resubmission
        teacher_user = submission.assignment.faculty.user if submission.assignment.faculty else None
        if teacher_user:
            send_notification(
                teacher_user,
                "Revised Assignment Resubmitted",
                f"{user.get_full_name()} uploaded Revision (v{new_version_num}) for '{submission.assignment.title}'."
            )

        response_data = AssignmentSubmissionSerializer(submission, context={'request': request}).data
        return Response(response_data, status=status.HTTP_201_CREATED)

class TeacherReviewListView(generics.ListAPIView):
    """
    Lists pending review requests for the authenticated teacher
    """
    permission_classes = [IsAuthenticated]
    serializer_class = TeacherReviewSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role == 'faculty' and hasattr(user, 'faculty_profile'):
            fp = user.faculty_profile
            from django.db.models import Q
            qs = TeacherReview.objects.filter(
                Q(assignment__faculty=fp) | Q(assignment__subject__faculty=fp)
            )
            if not qs.exists() and fp.department:
                qs = TeacherReview.objects.filter(assignment__department=fp.department)
            return qs.order_by('-created_at')
        elif user.role == 'admin':
            return TeacherReview.objects.all().order_by('-created_at')
        return TeacherReview.objects.none()

class TeacherReviewActionView(APIView):
    """
    Teacher APPROVE, REJECT, or REQUEST REWRITE for review requests
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        if user.role not in ['faculty', 'admin']:
            return Response({"error": "Only faculty can review assignments."}, status=status.HTTP_403_FORBIDDEN)

        review = get_object_or_404(TeacherReview, pk=pk)
        action = request.data.get('action', '').upper() # APPROVE, REJECT, REWRITE
        feedback = request.data.get('feedback', '').strip()

        submission = review.submission
        student_user = submission.student.user

        if action == 'APPROVE':
            review.request_status = 'APPROVED'
            submission.status = 'APPROVED'
            review.teacher_feedback = feedback or "Approved by faculty upon document review."
            submission.teacher_feedback = review.teacher_feedback
            send_notification(
                student_user,
                "✓ Assignment Approved",
                f"Your assignment '{review.assignment.title}' has been reviewed and approved by your teacher."
            )
        elif action == 'REJECT':
            review.request_status = 'REJECTED'
            submission.status = 'REJECTED'
            review.teacher_feedback = feedback or "Assignment rejected upon faculty review."
            submission.teacher_feedback = review.teacher_feedback
            send_notification(
                student_user,
                "Assignment Rejected",
                f"Your assignment '{review.assignment.title}' was rejected. Feedback: {review.teacher_feedback}"
            )
        elif action in ['REWRITE', 'REWRITE_REQUIRED']:
            review.request_status = 'REWRITE_REQUESTED'
            submission.status = 'REWRITE_REQUIRED'
            review.teacher_feedback = feedback or "Please rewrite the highlighted sections and submit again."
            submission.teacher_feedback = review.teacher_feedback
            send_notification(
                student_user,
                "Rewrite Required",
                f"Your teacher requested a rewrite for '{review.assignment.title}'. Feedback: {review.teacher_feedback}"
            )
        else:
            return Response({"error": "Invalid action. Use APPROVE, REJECT, or REWRITE."}, status=status.HTTP_400_BAD_REQUEST)

        review.reviewed_by = getattr(user, 'faculty_profile', None)
        review.reviewed_at = timezone.now()
        review.save()
        submission.save()

        return Response({
            "message": f"Review action '{action}' completed successfully.",
            "submission_status": submission.status,
            "feedback": review.teacher_feedback
        })

class SubmissionApproveView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request, pk):
        if request.user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)
        submission = get_object_or_404(AssignmentSubmission, pk=pk)
        submission.status = 'APPROVED'
        feedback = request.data.get('feedback', 'Approved by teacher')
        submission.teacher_feedback = feedback
        submission.save()
        send_notification(submission.student.user, "✓ Assignment Approved", f"Your assignment '{submission.assignment.title}' has been approved by your teacher.")
        return Response({"status": "APPROVED", "message": "Assignment approved successfully."})

class SubmissionRejectView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request, pk):
        if request.user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)
        submission = get_object_or_404(AssignmentSubmission, pk=pk)
        submission.status = 'REJECTED'
        feedback = request.data.get('feedback', 'Rejected by teacher')
        submission.teacher_feedback = feedback
        submission.save()
        send_notification(submission.student.user, "Assignment Rejected", f"Your assignment '{submission.assignment.title}' was rejected. Feedback: {feedback}")
        return Response({"status": "REJECTED", "message": "Assignment rejected."})

class SubmissionRewriteRequestView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request, pk):
        if request.user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)
        submission = get_object_or_404(AssignmentSubmission, pk=pk)
        submission.status = 'REWRITE_REQUIRED'
        feedback = request.data.get('feedback', 'Please rewrite the highlighted sections and resubmit.')
        submission.teacher_feedback = feedback
        submission.save()
        send_notification(submission.student.user, "Rewrite Required", f"Your teacher requested a rewrite for '{submission.assignment.title}': {feedback}")
        return Response({"status": "REWRITE_REQUIRED", "message": "Rewrite requested."})

class SubmissionListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = AssignmentSubmissionSerializer

    def get_queryset(self):
        user = self.request.user
        qs = AssignmentSubmission.objects.all().select_related('assignment', 'student', 'student__user')
        assignment_id = self.request.query_params.get('assignment_id')
        if assignment_id:
            qs = qs.filter(assignment_id=assignment_id)

        if user.role == 'student' and hasattr(user, 'student_profile'):
            qs = qs.filter(student=user.student_profile)
        elif user.role == 'faculty' and hasattr(user, 'faculty_profile'):
            fp = user.faculty_profile
            fac_qs = qs.filter(Q(assignment__faculty=fp) | Q(assignment__subject__faculty=fp))
            if fac_qs.exists():
                qs = fac_qs
            elif fp.department:
                qs = qs.filter(assignment__department=fp.department)

        return qs.order_by('-submitted_at')

class GradeSubmissionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        if user.role not in ['faculty', 'admin']:
            return Response({"error": "Only faculty can grade submissions."}, status=status.HTTP_403_FORBIDDEN)

        submission = get_object_or_404(AssignmentSubmission, pk=pk)
        marks = request.data.get('marks')
        feedback = request.data.get('feedback')

        if marks is not None:
            submission.marks_obtained = int(marks)
            submission.status = "Graded"
        if feedback:
            submission.teacher_feedback = feedback
        submission.save()

        max_m = getattr(submission.assignment, 'max_marks', 100)
        send_notification(
            submission.student.user,
            "Assignment Graded",
            f"Your submission for '{submission.assignment.title}' was graded: {marks}/{max_m}."
        )

        return Response(AssignmentSubmissionSerializer(submission, context={'request': request}).data)

class AssignmentRosterView(APIView):
    """
    Returns submitted and not-submitted students for an assignment,
    along with each student's online/offline status, submission details, marks, and similarity.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        user = request.user
        if user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)

        assignment = get_object_or_404(Assignment, pk=pk)

        # 1. Enrolled students for this assignment
        from accounts.models import StudentProfile
        enrolled_students = StudentProfile.objects.filter(
            department=assignment.department,
            year=assignment.year,
            semester=assignment.semester
        ).select_related('user', 'department').order_by('student_id')

        if not enrolled_students.exists():
            enrolled_students = StudentProfile.objects.filter(
                department=assignment.department
            ).select_related('user', 'department').order_by('student_id')

        # 2. Existing submissions for this assignment
        submissions = AssignmentSubmission.objects.filter(
            assignment=assignment
        ).select_related('student', 'student__user', 'similarity_result')

        submissions_map = {sub.student_id: sub for sub in submissions}

        submitted_list = []
        not_submitted_list = []

        for sp in enrolled_students:
            is_online = getattr(sp, 'is_online', False)
            student_name = sp.user.get_full_name() or sp.user.username

            if sp.id in submissions_map:
                sub = submissions_map[sp.id]
                sim_res = getattr(sub, 'similarity_result', None)
                sim_pct = sim_res.similarity_percentage if sim_res else 0.0
                orig_pct = sim_res.originality_percentage if sim_res else 100.0

                submitted_list.append({
                    "submission_id": sub.id,
                    "student_profile_id": sp.id,
                    "student_id": sp.student_id,
                    "student_name": student_name,
                    "department": sp.department.code if sp.department else "CSE",
                    "section": sp.section,
                    "is_online": is_online,
                    "submitted_at": sub.submitted_at.strftime("%b %d, %Y - %I:%M %p") if sub.submitted_at else "",
                    "status": sub.status,
                    "version": sub.current_version,
                    "marks_obtained": sub.marks_obtained,
                    "max_marks": assignment.max_marks,
                    "teacher_feedback": sub.teacher_feedback or "",
                    "file_url": request.build_absolute_uri(sub.file.url) if sub.file else None,
                    "file_name": sub.file.name.split('/')[-1] if sub.file else "Submission",
                    "similarity_percentage": sim_pct,
                    "originality_percentage": orig_pct,
                    "ocr_confidence": sub.ocr_confidence,
                })
            else:
                not_submitted_list.append({
                    "student_profile_id": sp.id,
                    "student_id": sp.student_id,
                    "student_name": student_name,
                    "department": sp.department.code if sp.department else "CSE",
                    "section": sp.section,
                    "year": sp.year,
                    "is_online": is_online,
                    "status": "NOT_SUBMITTED",
                })

        total_enrolled = len(enrolled_students)
        submitted_count = len(submitted_list)
        not_submitted_count = len(not_submitted_list)
        rate = round((submitted_count / total_enrolled * 100), 1) if total_enrolled > 0 else 0.0

        return Response({
            "assignment": {
                "id": assignment.id,
                "title": assignment.title,
                "description": assignment.description,
                "instructions": assignment.instructions,
                "subject_code": assignment.subject.code,
                "subject_name": assignment.subject.name,
                "department": assignment.department.name,
                "due_date": assignment.due_date.strftime("%b %d, %Y - %I:%M %p"),
                "max_marks": assignment.max_marks,
                "attachment_url": request.build_absolute_uri(assignment.attachment.url) if assignment.attachment else None,
            },
            "stats": {
                "total_enrolled": total_enrolled,
                "submitted_count": submitted_count,
                "not_submitted_count": not_submitted_count,
                "submission_rate": rate,
                "online_count": sum(1 for s in enrolled_students if getattr(s, 'is_online', False)),
            },
            "submitted": submitted_list,
            "not_submitted": not_submitted_list,
        })

class AssignmentRemindView(APIView):
    """
    Sends in-app notification reminder to a specific student or all pending students.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        if user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)

        assignment = get_object_or_404(Assignment, pk=pk)
        student_profile_id = request.data.get('student_profile_id')

        from accounts.models import StudentProfile
        from notifications.models import Notification

        if student_profile_id:
            try:
                sp = StudentProfile.objects.get(id=student_profile_id)
                Notification.objects.create(
                    user=sp.user,
                    title="Assignment Reminder",
                    message=f"Reminder: Please submit '{assignment.title}' for {assignment.subject.code}. Due date: {assignment.due_date.strftime('%b %d, %Y')}."
                )
                return Response({"message": f"Reminder sent to {sp.user.get_full_name()}."})
            except StudentProfile.DoesNotExist:
                return Response({"error": "Student not found"}, status=status.HTTP_404_NOT_FOUND)
        else:
            submitted_sids = assignment.submissions.values_list('student_id', flat=True)
            pending = StudentProfile.objects.filter(
                department=assignment.department,
                year=assignment.year,
                semester=assignment.semester
            ).exclude(id__in=submitted_sids)

            count = 0
            for sp in pending:
                Notification.objects.create(
                    user=sp.user,
                    title="Assignment Deadline Reminder",
                    message=f"Urgent: You have not submitted '{assignment.title}'. Due date: {assignment.due_date.strftime('%b %d, %Y')}."
                )
                count += 1

            return Response({"message": f"Reminders sent to {count} students.", "count": count})

