import { useState } from "react"
import { useNavigate, Navigate } from "react-router-dom"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { useAuth, isRejectedUser } from "@/lib/auth"
import { api } from "@/lib/api"
import { XCircle, Trash2, Loader2, AlertCircle, UserPlus } from "lucide-react"

export default function RejectedAccount() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [deleting, setDeleting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  if (!user || !isRejectedUser(user)) {
    return <Navigate to="/" replace />
  }

  const handleDelete = async () => {
    setDeleting(true)
    setError(null)
    try {
      await api.post("/auth/delete-rejected-account/")
      await logout()
      navigate("/", { replace: true })
    } catch (err: any) {
      setError(err?.message || "حدث خطأ أثناء حذف الحساب. يرجى المحاولة مرة أخرى.")
    } finally {
      setDeleting(false)
    }
  }

  const handleCreateNew = async () => {
    await logout()
    navigate("/", { replace: true })
  }

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-md w-full text-center"
      >
        <div className="w-16 h-16 rounded-full bg-destructive/10 flex items-center justify-center mx-auto mb-6">
          <XCircle className="w-8 h-8 text-destructive" />
        </div>

        <h1 className="text-2xl font-bold mb-2">تم رفض طلب التسجيل</h1>
        <p className="text-muted-foreground mb-8">
          لم يتم قبول طلب التسجيل الخاص بك. يمكنك حذف الحساب والمحاولة مرة أخرى.
        </p>

        <div className="bg-muted/50 rounded-xl p-4 mb-8 text-right">
          <p className="text-sm font-semibold text-muted-foreground mb-2">سبب الرفض</p>
          <p className="text-base">{user.registration_rejection_reason || "غير محدد"}</p>
        </div>

        {error && (
          <div className="flex items-center gap-2 rounded-xl border border-destructive/25 bg-destructive/8 px-3 py-2.5 text-xs text-destructive font-bold mb-4">
            <AlertCircle className="h-4 w-4 flex-shrink-0" /> {error}
          </div>
        )}

        <div className="space-y-3">
          <Button
            variant="destructive"
            size="lg"
            className="w-full gap-2"
            onClick={handleDelete}
            disabled={deleting}
          >
            {deleting ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              <Trash2 className="w-5 h-5" />
            )}
            حذف الحساب والتسجيل من جديد
          </Button>

          <Button
            variant="outline"
            size="lg"
            className="w-full gap-2"
            onClick={handleCreateNew}
          >
            <UserPlus className="w-5 h-5" />
            إنشاء حساب جديد
          </Button>
        </div>
      </motion.div>
    </div>
  )
}
