"use client";

import React, { useState, useRef } from "react";
import {
  Keyboard,
  QrCode,
  Search,
  CheckCircle2,
  XCircle,
  Tag,
  Info,
  AlertCircle,
} from "lucide-react";

// ─── Mock member database ──────────────────────────────────────────────────────
const mockMembers: Record<
  string,
  {
    name: string;
    id: string;
    package: string;
    expiry: string;
    status: "valid" | "expired" | "expiring";
    avatar: string;
    note: string;
  }
> = {
  "100459": {
    name: "أحمد خالد سعيد",
    id: "100459",
    package: "باقة الأبطال (سنوي)",
    expiry: "15 نوفمبر 2024",
    status: "valid",
    avatar:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuCzSUkz3hkCyvlUMilIn6olnQd2wqlFhFzBAssrp7oT604kAKxdEL1-vcwYFDeecy5t6l1QizSEEMDLBnAlepTd5wNjcgF3KqMn4xI38bbg_3KT6xhy5kQphwur6bNcCZBNt6U6w5CVIc_TWqQq_LnNxFAwf-j-uITsiEGenYPEfbqJLfZUWlNKSIBlLVZia7pZX0lGlqkcyXWMvV34qIYy-2JK-u4cFx9a3PgNSVv7dMYe6vI3B7T4Y-1CMj-zyftQRkSdgAqPf_M",
    note: "لا توجد مستحقات مالية متأخرة.",
  },
  "200312": {
    name: "عمر عبدالله المطيري",
    id: "200312",
    package: "باقة الشهر",
    expiry: "01 ديسمبر 2023",
    status: "expired",
    avatar:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuCzSUkz3hkCyvlUMilIn6olnQd2wqlFhFzBAssrp7oT604kAKxdEL1-vcwYFDeecy5t6l1QizSEEMDLBnAlepTd5wNjcgF3KqMn4xI38bbg_3KT6xhy5kQphwur6bNcCZBNt6U6w5CVIc_TWqQq_LnNxFAwf-j-uITsiEGenYPEfbqJLfZUWlNKSIBlLVZia7pZX0lGlqkcyXWMvV34qIYy-2JK-u4cFx9a3PgNSVv7dMYe6vI3B7T4Y-1CMj-zyftQRkSdgAqPf_M",
    note: "الاشتراك منتهي منذ 12 يوماً.",
  },
  "300777": {
    name: "فيصل محمد الدوسري",
    id: "300777",
    package: "باقة 3 أشهر",
    expiry: "10 فبراير 2024",
    status: "expiring",
    avatar:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuCzSUkz3hkCyvlUMilIn6olnQd2wqlFhFzBAssrp7oT604kAKxdEL1-vcwYFDeecy5t6l1QizSEEMDLBnAlepTd5wNjcgF3KqMn4xI38bbg_3KT6xhy5kQphwur6bNcCZBNt6U6w5CVIc_TWqQq_LnNxFAwf-j-uITsiEGenYPEfbqJLfZUWlNKSIBlLVZia7pZX0lGlqkcyXWMvV34qIYy-2JK-u4cFx9a3PgNSVv7dMYe6vI3B7T4Y-1CMj-zyftQRkSdgAqPf_M",
    note: "الاشتراك يوشك على الانتهاء خلال 3 أيام.",
  },
};

type MemberData = (typeof mockMembers)[string];
type SearchState = "idle" | "loading" | "found" | "notfound";

export default function VerifyPage() {
  const [query, setQuery] = useState("");
  const [searchState, setSearchState] = useState<SearchState>("idle");
  const [member, setMember] = useState<MemberData | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleSearch = () => {
    const trimmed = query.trim();
    if (!trimmed) return;

    setSearchState("loading");
    setMember(null);

    setTimeout(() => {
      const found = mockMembers[trimmed];
      if (found) {
        setMember(found);
        setSearchState("found");
      } else {
        setSearchState("notfound");
      }
    }, 800);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") handleSearch();
  };

  const statusConfig = {
    valid: {
      label: "صالح",
      chipClass: "bg-[#006d30]/10 text-[#006d30]",
      icon: CheckCircle2,
      ringClass: "bg-[#006d30]/20",
      borderClass: "border-[#006d30]",
    },
    expired: {
      label: "منتهي",
      chipClass: "bg-[#ba1a1a]/10 text-[#ba1a1a]",
      icon: XCircle,
      ringClass: "bg-[#ba1a1a]/20",
      borderClass: "border-[#ba1a1a]",
    },
    expiring: {
      label: "يوشك على الانتهاء",
      chipClass: "bg-[#6b4200]/10 text-[#6b4200]",
      icon: AlertCircle,
      ringClass: "bg-[#6b4200]/20",
      borderClass: "border-[#6b4200]",
    },
  };

  return (
    <div className="space-y-6 animate-fade-in" dir="rtl">
      {/* Page Header */}
      <div>
        <h1 className="text-3xl font-bold text-foreground">الفحص السريع</h1>
        <p className="text-muted-foreground mt-1 text-sm">
          التحقق من حالة اشتراك الأعضاء عند البوابة.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left column: Input & QR */}
        <div className="lg:col-span-5 flex flex-col gap-5">
          {/* Manual Entry Card */}
          <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-6 shadow-lg shadow-primary/5">
            <h3 className="text-lg font-bold text-foreground mb-5 flex items-center gap-2">
              <Keyboard className="w-5 h-5 text-primary" />
              إدخال يدوي
            </h3>
            <div className="relative mb-5">
              <label
                htmlFor="member-id"
                className="absolute -top-3 right-4 bg-white px-2 text-xs font-semibold text-primary z-10"
              >
                رقم العضوية
              </label>
              <input
                ref={inputRef}
                id="member-id"
                type="text"
                dir="ltr"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="مثال: 100459"
                className="w-full h-16 bg-[#F1F5F9] border-2 border-transparent focus:border-primary rounded-xl px-6 text-2xl font-bold text-center tracking-widest text-foreground transition-all outline-none"
              />
            </div>
            <button
              onClick={handleSearch}
              disabled={searchState === "loading"}
              className="w-full h-14 bg-primary text-white rounded-xl text-sm font-bold shadow-md shadow-primary/20 hover:bg-primary/90 transition-all flex items-center justify-center gap-2 disabled:opacity-70"
            >
              {searchState === "loading" ? (
                <>
                  <span className="inline-block w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                  جارٍ التحقق...
                </>
              ) : (
                <>
                  <Search className="w-5 h-5" />
                  تحقق من العضوية
                </>
              )}
            </button>

            {/* Helper hint */}
            <p className="text-xs text-muted-foreground mt-3 text-center">
              جرب: 100459 (صالح) · 200312 (منتهي) · 300777 (يوشك)
            </p>
          </div>

          {/* QR Scanner Card */}
          <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-6 shadow-lg shadow-primary/5 flex-1 flex flex-col">
            <h3 className="text-lg font-bold text-foreground mb-4 flex items-center gap-2">
              <QrCode className="w-5 h-5 text-[#006d30]" />
              مسح الرمز
            </h3>
            <div className="flex-1 bg-surface-container-low rounded-xl border-2 border-dashed border-border/40 flex flex-col items-center justify-center p-8 min-h-[220px] relative overflow-hidden group hover:border-[#006d30] transition-colors cursor-pointer">
              <div className="absolute inset-0 bg-[#006d30]/5 opacity-0 group-hover:opacity-100 transition-opacity" />
              <QrCode className="w-16 h-16 text-border group-hover:text-[#006d30] mb-4 transition-colors" />
              <p className="text-muted-foreground text-sm text-center max-w-[200px]">
                انقر لتفعيل الكاميرا ومسح رمز الاستجابة السريعة
              </p>
            </div>
          </div>
        </div>

        {/* Right column: Result Area */}
        <div className="lg:col-span-7">
          <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-8 shadow-lg shadow-primary/5 h-full flex flex-col">
            <h3 className="text-lg font-bold text-foreground mb-6 flex items-center gap-2">
              <span className="material-symbols-outlined text-muted-foreground" />
              نتيجة الفحص
            </h3>

            {/* Idle state */}
            {searchState === "idle" && (
              <div className="flex-1 flex flex-col items-center justify-center text-center p-8 border-2 border-dashed border-border/30 rounded-xl bg-surface-container-low/50">
                <Search className="w-16 h-16 text-border/50 mb-4" />
                <p className="text-muted-foreground text-sm">
                  الرجاء إدخال رقم العضوية أو مسح الرمز لعرض النتيجة.
                </p>
              </div>
            )}

            {/* Loading state */}
            {searchState === "loading" && (
              <div className="flex-1 flex flex-col items-center justify-center text-center p-8">
                <div className="w-16 h-16 border-4 border-primary/20 border-t-primary rounded-full animate-spin mb-4" />
                <p className="text-muted-foreground text-sm">جارٍ التحقق...</p>
              </div>
            )}

            {/* Not found state */}
            {searchState === "notfound" && (
              <div className="flex-1 flex flex-col items-center justify-center text-center p-8 border-2 border-dashed border-[#ba1a1a]/30 rounded-xl bg-[#ffdad6]/20">
                <XCircle className="w-16 h-16 text-[#ba1a1a]/60 mb-4" />
                <h2 className="text-xl font-bold text-foreground mb-2">
                  رقم غير موجود
                </h2>
                <p className="text-muted-foreground text-sm">
                  لم يتم العثور على عضو برقم «{query}». تأكد من الرقم وحاول
                  مجدداً.
                </p>
              </div>
            )}

            {/* Found state */}
            {searchState === "found" && member && (() => {
              const cfg = statusConfig[member.status];
              const Icon = cfg.icon;
              return (
                <div className="flex-1 flex flex-col items-center justify-center animate-fade-in">
                  {/* Status chip */}
                  <div
                    className={`${cfg.chipClass} px-8 py-3 rounded-full text-2xl font-extrabold flex items-center gap-3 mb-8`}
                  >
                    <Icon className="w-8 h-8" />
                    {cfg.label}
                  </div>

                  {/* Avatar ring */}
                  <div
                    className={`relative w-40 h-40 rounded-full p-2 ${cfg.ringClass} mb-6`}
                  >
                    <div
                      className={`w-full h-full rounded-full overflow-hidden border-4 border-white shadow-lg ${
                        member.status === "expired" ? "grayscale opacity-80" : ""
                      }`}
                    >
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={member.avatar}
                        alt={member.name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    {/* Floating verified badge */}
                    {member.status === "valid" && (
                      <div className="absolute bottom-1 left-1 bg-white text-[#006d30] w-9 h-9 rounded-full flex items-center justify-center shadow-md">
                        <CheckCircle2 className="w-5 h-5" />
                      </div>
                    )}
                  </div>

                  {/* Name & ID */}
                  <h2 className="text-3xl font-bold text-foreground mb-2 text-center">
                    {member.name}
                  </h2>
                  <p className="text-muted-foreground mb-8 text-center flex items-center gap-2">
                    <Tag className="w-4 h-4" />
                    {member.id}
                  </p>

                  {/* Details grid */}
                  <div className="w-full grid grid-cols-2 gap-4 bg-surface-container-low p-6 rounded-2xl border border-border/20">
                    <div>
                      <p className="text-xs text-muted-foreground mb-1">
                        نوع الاشتراك
                      </p>
                      <p className="text-sm font-bold text-foreground">
                        {member.package}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground mb-1">
                        تاريخ الانتهاء
                      </p>
                      <p className="text-sm font-bold text-foreground">
                        {member.expiry}
                      </p>
                    </div>
                    <div className="col-span-2 mt-2 pt-4 border-t border-border/20">
                      <p className="text-xs text-muted-foreground mb-1">
                        ملاحظات النظام
                      </p>
                      <p
                        className={`text-sm font-bold flex items-center gap-1 ${
                          member.status === "valid"
                            ? "text-[#006d30]"
                            : member.status === "expired"
                            ? "text-[#ba1a1a]"
                            : "text-[#6b4200]"
                        }`}
                      >
                        <Info className="w-4 h-4 shrink-0" />
                        {member.note}
                      </p>
                    </div>
                  </div>

                  {/* Action buttons */}
                  {member.status !== "valid" && (
                    <div className="w-full mt-4 flex gap-3">
                      <button className="flex-1 bg-primary text-white py-3 rounded-xl text-sm font-bold hover:bg-primary/90 transition-all shadow-md">
                        تجديد الاشتراك
                      </button>
                      <button className="flex-1 border border-border/40 text-foreground py-3 rounded-xl text-sm font-semibold hover:bg-surface-container transition-all">
                        توجيه للاستقبال
                      </button>
                    </div>
                  )}
                </div>
              );
            })()}
          </div>
        </div>
      </div>
    </div>
  );
}
