from django.urls import path
from .views import (
    AssignmentListCreateView,
    AssignmentDetailView,
    AssignmentSubmitView,
    SubmissionListView,
    SubmissionDetailView,
    SubmissionStatusView,
    SubmissionOCRView,
    SubmissionSimilarityView,
    SubmissionMatchesView,
    SubmissionVersionsView,
    SubmissionReviewRequestView,
    SubmissionResubmitView,
    SubmissionApproveView,
    SubmissionRejectView,
    SubmissionRewriteRequestView,
    TeacherReviewListView,
    TeacherReviewActionView,
    GradeSubmissionView,
)

urlpatterns = [
    path('assignments/', AssignmentListCreateView.as_view(), name='assignment_list_create'),
    path('assignments/<int:pk>/', AssignmentDetailView.as_view(), name='assignment_detail'),
    path('assignments/<int:pk>/submit/', AssignmentSubmitView.as_view(), name='assignment_submit'),

    path('submissions/', SubmissionListView.as_view(), name='submission_list'),
    path('submissions/<int:pk>/', SubmissionDetailView.as_view(), name='submission_detail'),
    path('submissions/<int:pk>/status/', SubmissionStatusView.as_view(), name='submission_status'),
    path('submissions/<int:pk>/ocr/', SubmissionOCRView.as_view(), name='submission_ocr'),
    path('submissions/<int:pk>/similarity/', SubmissionSimilarityView.as_view(), name='submission_similarity'),
    path('similarity/<int:pk>/', SubmissionSimilarityView.as_view(), name='similarity_alias'),
    path('submissions/<int:pk>/matches/', SubmissionMatchesView.as_view(), name='submission_matches'),
    path('submissions/<int:pk>/versions/', SubmissionVersionsView.as_view(), name='submission_versions'),

    path('submissions/<int:pk>/review-request/', SubmissionReviewRequestView.as_view(), name='submission_review_request'),
    path('submissions/<int:pk>/resubmit/', SubmissionResubmitView.as_view(), name='submission_resubmit'),
    path('submissions/<int:pk>/approve/', SubmissionApproveView.as_view(), name='submission_approve'),
    path('submissions/<int:pk>/reject/', SubmissionRejectView.as_view(), name='submission_reject'),
    path('submissions/<int:pk>/rewrite-request/', SubmissionRewriteRequestView.as_view(), name='submission_rewrite_request'),
    path('submissions/<int:pk>/grade/', GradeSubmissionView.as_view(), name='grade_submission'),

    path('teacher/review-requests/', TeacherReviewListView.as_view(), name='teacher_review_requests'),
    path('teacher/review-requests/<int:pk>/action/', TeacherReviewActionView.as_view(), name='teacher_review_action'),
]