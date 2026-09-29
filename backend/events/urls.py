from django.urls import path
from .views import EventListCreateView, EventDetailView, EventMediaListCreateView, ApproveMediaView

urlpatterns = [
    path('events/', EventListCreateView.as_view(), name='event_list_create'),
    path('events/<int:pk>/', EventDetailView.as_view(), name='event_detail'),
    path('events/<int:pk>/media/', EventMediaListCreateView.as_view(), name='event_media'),
    path('media/<int:pk>/approve/', ApproveMediaView.as_view(), name='approve_media'),
]