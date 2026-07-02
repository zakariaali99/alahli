import { useNetworkStatus } from "@/lib/network"
import { WifiOff } from "lucide-react"

export default function OfflineBar() {
  const isOnline = useNetworkStatus()

  if (isOnline) return null

  return (
    <div className="fixed top-0 left-0 right-0 z-[100] bg-destructive text-destructive-foreground text-sm text-center py-2 px-4 flex items-center justify-center gap-2">
      <WifiOff className="w-4 h-4" />
      أنت غير متصل بالإنترنت. بعض الوظائف قد لا تعمل.
    </div>
  )
}
