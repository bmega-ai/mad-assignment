from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from .models import Note
from .serializers import NoteSerializer

class NoteListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = NoteSerializer

    def get_queryset(self):
        user = self.request.user
        qs = Note.objects.all().select_related('subject', 'department', 'faculty', 'faculty__user')
        subject_id = self.request.query_params.get('subject_id')
        if subject_id:
            qs = qs.filter(subject_id=subject_id)

        if user.role == 'student' and hasattr(user, 'student_profile'):
            sp = user.student_profile
            qs = qs.filter(department=sp.department, year=sp.year, semester=sp.semester)
        elif user.role == 'faculty' and hasattr(user, 'faculty_profile'):
            qs = qs.filter(faculty=user.faculty_profile)

        return qs.order_by('-upload_date')

    def perform_create(self, serializer):
        user = self.request.user
        faculty = getattr(user, 'faculty_profile', None)
        serializer.save(faculty=faculty)

class NoteDetailView(generics.RetrieveDestroyAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = NoteSerializer
    queryset = Note.objects.all()
