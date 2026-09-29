from django.urls import path
from .views import PlagiarismCheckView

urlpatterns = [
    path('plagiarism/check/', PlagiarismCheckView.as_view(), name='plagiarism_check'),
]