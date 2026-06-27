from django.contrib import admin, messages
from django.http import HttpResponseRedirect
from django.shortcuts import render
from django.urls import path, reverse
from django.utils.html import format_html

from apps.athletes.models import Athlete
from apps.notifications.tasks import send_whatsapp_message

from .models import Announcement, Notification, WhatsAppMessage


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ["title", "athlete", "is_read", "created_at"]
    list_filter = ["is_read"]


@admin.register(Announcement)
class AnnouncementAdmin(admin.ModelAdmin):
    list_display = ["title", "is_active", "created_at"]
    list_filter = ["is_active"]


@admin.register(WhatsAppMessage)
class WhatsAppMessageAdmin(admin.ModelAdmin):
    list_display = ["athlete", "template_name", "status", "recipient_phone", "sent_at", "created_at"]
    list_filter = ["status", "template_name"]
    search_fields = ["athlete__full_name", "athlete__phone", "recipient_phone"]
    readonly_fields = ["athlete", "notification", "template_name", "message_body", "recipient_phone", "status", "whatsapp_message_id", "error_message", "sent_at", "created_at"]
    date_hierarchy = "created_at"

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False


def send_whatsapp_action(modeladmin, request, queryset):
    ids = ",".join(str(a.id) for a in queryset)
    return HttpResponseRedirect(f"{reverse('admin:send-whatsapp')}?athlete_ids={ids}")

send_whatsapp_action.short_description = "Send WhatsApp message to selected athletes"


class AthleteAdminProxy(Athlete):
    class Meta:
        proxy = True
        verbose_name = "Athlete WhatsApp"
        verbose_name_plural = "Athlete WhatsApp"


@admin.register(AthleteAdminProxy)
class AthleteWhatsAppAdmin(admin.ModelAdmin):
    list_display = ["full_name", "phone", "membership_number", "department", "send_actions"]
    list_filter = ["department", "is_active"]
    search_fields = ["full_name", "membership_number", "phone"]
    actions = [send_whatsapp_action]

    def send_actions(self, obj):
        url = f"{reverse('admin:send-whatsapp')}?athlete_ids={obj.id}"
        return format_html('<a class="button" href="{}">Send WhatsApp</a>', url)

    send_actions.short_description = "WhatsApp"
    send_actions.allow_tags = True

    def get_urls(self):
        return [
            path("send-whatsapp/", self.admin_site.admin_view(self.send_whatsapp_view), name="send-whatsapp"),
            path("send-whatsapp/submit/", self.admin_site.admin_view(self.send_whatsapp_submit), name="send-whatsapp-submit"),
        ] + super().get_urls()

    def send_whatsapp_view(self, request):
        athlete_ids = request.GET.get("athlete_ids", "")
        ids = [int(x) for x in athlete_ids.split(",") if x.isdigit()]
        athletes = Athlete.objects.filter(id__in=ids)
        return render(request, "admin/notifications/send_whatsapp.html", {
            "athletes": athletes,
            "athlete_ids": athlete_ids,
            "title": "Send WhatsApp Message",
        })

    def send_whatsapp_submit(self, request):
        if request.method != "POST":
            return HttpResponseRedirect(reverse("admin:send-whatsapp"))

        athlete_ids = request.POST.get("athlete_ids", "")
        template_name = request.POST.get("template_name", "notification_alert")
        title = request.POST.get("title", "")
        body = request.POST.get("body", "")

        ids = [int(x) for x in athlete_ids.split(",") if x.isdigit()]
        count = 0
        for athlete_id in ids:
            send_whatsapp_message.delay(athlete_id, title, body, template_name)
            count += 1

        messages.success(request, f"Queued WhatsApp message for {count} athlete(s)")
        return HttpResponseRedirect(reverse("admin:notifications_whatsappmessage_changelist"))
