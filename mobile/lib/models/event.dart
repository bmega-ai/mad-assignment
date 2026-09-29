class EventMediaItem {
  final int id;
  final String? fileUrl;
  final String mediaType;
  final String? caption;
  final String uploadedByName;

  EventMediaItem({
    required this.id,
    this.fileUrl,
    required this.mediaType,
    this.caption,
    required this.uploadedByName,
  });

  factory EventMediaItem.fromJson(Map<String, dynamic> json) {
    return EventMediaItem(
      id: json['id'] ?? 0,
      fileUrl: json['file_url'],
      mediaType: json['media_type'] ?? 'image',
      caption: json['caption'],
      uploadedByName: json['uploaded_by_name'] ?? 'User',
    );
  }
}

class EventItem {
  final int id;
  final String title;
  final String description;
  final String dateFormatted;
  final String timeFormatted;
  final String venue;
  final String organizer;
  final String category;
  final String? coverImageUrl;
  final List<EventMediaItem> approvedMedia;

  EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.dateFormatted,
    required this.timeFormatted,
    required this.venue,
    required this.organizer,
    required this.category,
    this.coverImageUrl,
    required this.approvedMedia,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateFormatted: json['date_formatted'] ?? json['date'] ?? '',
      timeFormatted: json['time_formatted'] ?? json['time'] ?? '',
      venue: json['venue'] ?? '',
      organizer: json['organizer'] ?? '',
      category: json['category'] ?? 'General',
      coverImageUrl: json['cover_image_url'],
      approvedMedia: (json['approved_media'] as List? ?? [])
          .map((e) => EventMediaItem.fromJson(e))
          .toList(),
    );
  }
}
