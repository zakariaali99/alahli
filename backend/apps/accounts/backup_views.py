import json
from datetime import datetime
from django.http import HttpResponse, JsonResponse
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser

from apps.accounts.permissions import IsManagementOrAbove
from .backup_services import generate_backup_data, restore_backup_data

class BackupExportView(APIView):
    permission_classes = [IsAuthenticated, IsManagementOrAbove]

    def get(self, request, *args, **kwargs):
        backup_data = generate_backup_data()
        json_string = json.dumps(backup_data, indent=2, ensure_ascii=False, default=str)
        filename = f"alahli_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

        response = HttpResponse(json_string, content_type="application/json; charset=utf-8")
        response["Content-Disposition"] = f'attachment; filename="{filename}"'
        return response

class BackupImportView(APIView):
    permission_classes = [IsAuthenticated, IsManagementOrAbove]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request, *args, **kwargs):
        file_obj = request.FILES.get("file")
        mode = request.data.get("mode", "smart_merge")

        if not file_obj:
            return JsonResponse({"detail": "يرجى اختيار ملف النسخة الاحتياطية (JSON)"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            content = file_obj.read().decode("utf-8")
            backup_dict = json.loads(content)
            
            stats = restore_backup_data(backup_dict, mode=mode)
            return JsonResponse({
                "success": True,
                "message": "تمت عملية الدمج/الاستعادة بنجاح",
                "mode": mode,
                "stats": stats
            })
        except Exception as e:
            return JsonResponse({
                "detail": f"حدث خطأ أثناء معالجة ملف النسخة الاحتياطية: {str(e)}"
            }, status=status.HTTP_400_BAD_REQUEST)
