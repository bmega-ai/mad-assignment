from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from .services import check_similarity, extract_text_from_file

class PlagiarismCheckView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        file_obj = request.FILES.get('file')
        text = request.data.get('text', '')
        compare_texts = request.data.get('compare_texts', [])

        if file_obj:
            text = extract_text_from_file(file_obj)

        if not text:
            return Response({"error": "No text or file provided for analysis"}, status=status.HTTP_400_BAD_REQUEST)

        sim_pct, matches = check_similarity(text, compare_texts)
        orig_pct = max(0.0, round(100.0 - sim_pct, 2))

        return Response({
            "similarity_percentage": sim_pct,
            "originality_percentage": orig_pct,
            "potential_matches": matches
        })
