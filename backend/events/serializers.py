from rest_framework import serializers
from .models import Event, EventMedia

class EventMediaSerializer(serializers.ModelSerializer):
    uploaded_by_name = serializers.SerializerMethodField()
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = EventMedia
        fields = [
            'id', 'event', 'uploaded_by', 'uploaded_by_name',
            'file', 'file_url', 'media_type', 'caption', 'upload_date', 'status'
        ]
        read_only_fields = ['uploaded_by', 'status']

    def get_uploaded_by_name(self, obj):
        return obj.uploaded_by.get_full_name() or obj.uploaded_by.username

    def get_file_url(self, obj):
        if obj.file:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.file.url) if request else obj.file.url
        return None

class EventSerializer(serializers.ModelSerializer):
    cover_image_url = serializers.SerializerMethodField()
    date_formatted = serializers.SerializerMethodField()
    time_formatted = serializers.SerializerMethodField()
    approved_media = serializers.SerializerMethodField()

    class Meta:
        model = Event
        fields = [
            'id', 'title', 'description', 'date', 'date_formatted',
            'time', 'time_formatted', 'venue', 'organizer', 'category',
            'cover_image', 'cover_image_url', 'created_at', 'approved_media'
        ]

    def get_cover_image_url(self, obj):
        if obj.cover_image:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.cover_image.url) if request else obj.cover_image.url
        return None

    def get_date_formatted(self, obj):
        return obj.date.strftime("%b %d, %Y") if obj.date else ""

    def get_time_formatted(self, obj):
        return obj.time.strftime("%I:%M %p") if obj.time else ""

    def get_approved_media(self, obj):
        request = self.context.get('request')
        media_qs = obj.media.filter(status='APPROVED')[:6]
        return EventMediaSerializer(media_qs, many=True, context={'request': request}).data
