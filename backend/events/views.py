from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import generics, status
from django.shortcuts import get_object_or_404

from .models import Event, EventMedia
from .serializers import EventSerializer, EventMediaSerializer

class EventListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = EventSerializer

    def get_queryset(self):
        qs = Event.objects.all().order_by('-date')
        category = self.request.query_params.get('category')
        if category and category != 'All':
            qs = qs.filter(category__iexact=category)
        return qs

    def perform_create(self, serializer):
        serializer.save()

class EventDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = EventSerializer
    queryset = Event.objects.all()

class EventMediaListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        media_qs = event.media.filter(status='APPROVED').order_by('-upload_date')
        serializer = EventMediaSerializer(media_qs, many=True, context={'request': request})
        return Response(serializer.data)

    def post(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        file_obj = request.FILES.get('file')
        if not file_obj:
            return Response({"error": "No file uploaded"}, status=status.HTTP_400_BAD_REQUEST)

        media_type = request.data.get('media_type', 'image')
        caption = request.data.get('caption', '')

        # Auto approve if admin or faculty, otherwise PENDING
        status_val = 'APPROVED' if request.user.role in ['faculty', 'admin'] else 'APPROVED'

        media = EventMedia.objects.create(
            event=event,
            uploaded_by=request.user,
            file=file_obj,
            media_type=media_type,
            caption=caption,
            status=status_val
        )
        serializer = EventMediaSerializer(media, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class ApproveMediaView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        if request.user.role not in ['faculty', 'admin']:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)

        media = get_object_or_404(EventMedia, pk=pk)
        new_status = request.data.get('status', 'APPROVED')
        if new_status in ['APPROVED', 'REJECTED', 'PENDING']:
            media.status = new_status
            media.save()
            return Response(EventMediaSerializer(media, context={'request': request}).data)
        return Response({"error": "Invalid status"}, status=status.HTTP_400_BAD_REQUEST)
