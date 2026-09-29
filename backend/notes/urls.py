from django.urls import path
from .views import NoteListCreateView, NoteDetailView

urlpatterns = [
    path('notes/', NoteListCreateView.as_view(), name='note_list_create'),
    path('notes/<int:pk>/', NoteDetailView.as_view(), name='note_detail'),
]