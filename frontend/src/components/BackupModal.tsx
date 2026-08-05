import React, { useState } from "react"
import { motion } from "framer-motion"
import { Download, Upload, Database, RefreshCw, X, CheckCircle, AlertCircle, ShieldCheck } from "lucide-react"
import { getApiBase } from "@/lib/api"
import { useAuth } from "@/lib/auth"

interface BackupModalProps {
  isOpen: boolean
  onClose: () => void
}

export function BackupModal({ isOpen, onClose }: BackupModalProps) {
  const token = localStorage.getItem("access_token") || localStorage.getItem("token")
  const [mode, setMode] = useState<"smart_merge" | "overwrite">("smart_merge")
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [isExporting, setIsExporting] = useState(false)
  const [isImporting, setIsImporting] = useState(false)
  const [statusMessage, setStatusMessage] = useState<{ type: "success" | "error"; text: string } | null>(null)

  if (!isOpen) return null

  const handleExport = async () => {
    try {
      setIsExporting(true)
      setStatusMessage(null)
      const headers = { Authorization: token ? `Bearer ${token}` : "" }
      let res = await fetch(`${getApiBase()}/auth/backup/export/`, { headers })
      if (res.status === 404) {
        res = await fetch(`${getApiBase()}/backup/export/`, { headers })
      }
      if (!res.ok) {
        const errData = await res.json().catch(() => ({}))
        throw new Error(errData.detail || `فشل في تحميل النسخة الاحتياطية (${res.status})`)
      }
      
      const blob = await res.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `alahli_backup_${new Date().toISOString().slice(0, 10)}.json`
      document.body.appendChild(a)
      a.click()
      window.URL.revokeObjectURL(url)
      a.remove()
      setStatusMessage({ type: "success", text: "تم تصدير وتحميل النسخة الاحتياطية بنجاح" })
    } catch (err: any) {
      setStatusMessage({ type: "error", text: err.message || "حدث خطأ أثناء تصدير البيانات" })
    } finally {
      setIsExporting(false)
    }
  }

  const handleImport = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedFile) {
      setStatusMessage({ type: "error", text: "يرجى اختيار ملف النسخة الاحتياطية أولاً" })
      return
    }

    try {
      setIsImporting(true)
      setStatusMessage(null)

      const formData = new FormData()
      formData.append("file", selectedFile)
      formData.append("mode", mode)

      const headers = { Authorization: token ? `Bearer ${token}` : "" }
      let res = await fetch(`${getApiBase()}/auth/backup/import/`, {
        method: "POST",
        headers,
        body: formData,
      })
      if (res.status === 404) {
        res = await fetch(`${getApiBase()}/backup/import/`, {
          method: "POST",
          headers,
          body: formData,
        })
      }

      const data = await res.json().catch(() => ({}))
      if (!res.ok) throw new Error(data.detail || `حدث خطأ أثناء استعادة البيانات (${res.status})`)

      setStatusMessage({
        type: "success",
        text: `${data.message} — تم إنشاء ${data.stats?.created || 0} سجل جديد ودمج ${data.stats?.merged || 0} سجل حالي.`,
      })
      setSelectedFile(null)
    } catch (err: any) {
      setStatusMessage({ type: "error", text: err.message || "فشلت عملية استعادة النسخة الاحتياطية" })
    } finally {
      setIsImporting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-xs p-4">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        className="bg-white rounded-3xl p-6 sm:p-8 max-w-xl w-full shadow-2xl space-y-6 text-right relative overflow-hidden"
        dir="rtl"
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-gray-100 pb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-primary/10 text-primary flex items-center justify-center">
              <Database className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-xl font-black text-[#0f2942]">إدارة النسخ الاحتياطي واستعادة البيانات</h2>
              <p className="text-xs text-muted-foreground">تصدير وتأمين أو دمج واستعادة قاعدة البيانات بسهولة</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-xl text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Status Message */}
        {statusMessage && (
          <div
            className={`p-4 rounded-2xl flex items-center gap-3 text-sm font-bold ${
              statusMessage.type === "success"
                ? "bg-emerald-50 text-emerald-800 border border-emerald-200"
                : "bg-rose-50 text-rose-800 border border-rose-200"
            }`}
          >
            {statusMessage.type === "success" ? (
              <CheckCircle className="w-5 h-5 text-emerald-600 shrink-0" />
            ) : (
              <AlertCircle className="w-5 h-5 text-rose-600 shrink-0" />
            )}
            <span>{statusMessage.text}</span>
          </div>
        )}

        {/* Export Section */}
        <div className="p-5 rounded-2xl bg-gray-50 border border-gray-200/80 space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-base font-extrabold text-[#0f2942]">تصدير نسخة احتياطية</h3>
              <p className="text-xs text-muted-foreground">تحميل ملف شامل لقاعدة البيانات الحالية بصيغة JSON</p>
            </div>
            <button
              onClick={handleExport}
              disabled={isExporting}
              className="px-4 py-2.5 rounded-xl bg-primary hover:bg-primary/90 text-white text-xs font-bold transition-all disabled:opacity-50 flex items-center gap-2 shadow-sm"
            >
              {isExporting ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Download className="w-4 h-4" />}
              تحميل النسخة الآن
            </button>
          </div>
        </div>

        {/* Import Section */}
        <form onSubmit={handleImport} className="p-5 rounded-2xl bg-gray-50 border border-gray-200/80 space-y-4">
          <h3 className="text-base font-extrabold text-[#0f2942]">استعادة وتنسيق النسخة الاحتياطية</h3>

          {/* Mode selector */}
          <div className="space-y-2">
            <label className="text-xs font-bold text-gray-700 block">طريقة الاستعادة:</label>
            <div className="grid grid-cols-2 gap-3">
              <label
                className={`p-3 rounded-xl border text-xs font-bold cursor-pointer transition-all flex items-center gap-2 ${
                  mode === "smart_merge"
                    ? "border-primary bg-primary/10 text-primary"
                    : "border-gray-200 bg-white text-gray-700 hover:bg-gray-100"
                }`}
              >
                <input
                  type="radio"
                  name="import_mode"
                  value="smart_merge"
                  checked={mode === "smart_merge"}
                  onChange={() => setMode("smart_merge")}
                  className="hidden"
                />
                <ShieldCheck className="w-4 h-4" />
                <span>دمج ذكي (مستحسن)</span>
              </label>

              <label
                className={`p-3 rounded-xl border text-xs font-bold cursor-pointer transition-all flex items-center gap-2 ${
                  mode === "overwrite"
                    ? "border-rose-500 bg-rose-50 text-rose-700"
                    : "border-gray-200 bg-white text-gray-700 hover:bg-gray-100"
                }`}
              >
                <input
                  type="radio"
                  name="import_mode"
                  value="overwrite"
                  checked={mode === "overwrite"}
                  onChange={() => setMode("overwrite")}
                  className="hidden"
                />
                <Database className="w-4 h-4" />
                <span>استبدال كامل</span>
              </label>
            </div>
            <p className="text-[11px] text-muted-foreground">
              {mode === "smart_merge"
                ? "الدمج الذكي يدمج البيانات القديمة من النسخة الاحتياطية دون مسح أو التأثير على الاشتراكات والرياضيين الجدد الحالية."
                : "الاستبدال الكامل يمسح البيانات المعاملية الحالية ويستبدلها بالكامل بمحتوى النسخة الاحتياطية."}
            </p>
          </div>

          {/* File input */}
          <div className="space-y-2">
            <label className="text-xs font-bold text-gray-700 block">اختر ملف JSON:</label>
            <input
              type="file"
              accept=".json"
              onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
              className="block w-full text-xs text-gray-500 file:ml-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-primary/10 file:text-primary hover:file:bg-primary/20 cursor-pointer"
            />
          </div>

          {/* Submit */}
          <div className="pt-2 flex justify-end">
            <button
              type="submit"
              disabled={isImporting || !selectedFile}
              className="px-5 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition-all disabled:opacity-50 flex items-center gap-2 shadow-sm"
            >
              {isImporting ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Upload className="w-4 h-4" />}
              بدء الاستعادة
            </button>
          </div>
        </form>

        <div className="flex justify-end pt-2 border-t border-gray-100">
          <button
            onClick={onClose}
            className="px-5 py-2 rounded-xl border border-gray-200 text-xs font-bold text-gray-700 hover:bg-gray-100 transition-colors"
          >
            إغلاق
          </button>
        </div>
      </motion.div>
    </div>
  )
}
