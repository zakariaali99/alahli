import { Link } from "react-router-dom"
import { Button } from "@/components/ui/button"
import { Home, AlertTriangle } from "lucide-react"

export default function NotFound() {
  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <div className="text-center max-w-sm">
        <AlertTriangle className="w-16 h-16 text-muted-foreground mx-auto mb-4" />
        <h1 className="text-2xl font-bold mb-2">الصفحة غير موجودة</h1>
        <p className="text-muted-foreground mb-6">عذراً، الصفحة التي تبحث عنها غير موجودة أو قد تم نقلها.</p>
        <div className="flex gap-3 justify-center">
          <Button onClick={() => window.history.back()} variant="outline">العودة للصفحة السابقة</Button>
          <Link to="/login">
            <Button>
              <Home className="w-4 h-4 ml-1" />
              الصفحة الرئيسية
            </Button>
          </Link>
        </div>
      </div>
    </div>
  )
}
