import { useRef, useState, useCallback, type ChangeEvent } from "react"
import { Button } from "./button"
import { Camera, ImagePlus } from "lucide-react"

interface CameraCaptureProps {
  onCapture: (base64: string) => void
  buttonText?: string
  preview?: string
}

export default function CameraCapture({ onCapture, buttonText = "خذ صورة شخصية", preview }: CameraCaptureProps) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const fallbackInputRef = useRef<HTMLInputElement>(null)
  const galleryInputRef = useRef<HTMLInputElement>(null)
  const [overlay, setOverlay] = useState(false)
  const [videoReady, setVideoReady] = useState(false)
  const [error, setError] = useState("")

  const stopCamera = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((t) => t.stop())
      streamRef.current = null
    }
    setOverlay(false)
    setVideoReady(false)
  }, [])

  const captureFrame = useCallback(() => {
    const video = videoRef.current
    const canvas = canvasRef.current
    if (!video || !canvas) return
    canvas.width = 512
    canvas.height = 512
    const ctx = canvas.getContext("2d")
    if (!ctx) return
    ctx.drawImage(video, 0, 0, 512, 512)
    const data = canvas.toDataURL("image/jpeg", 0.8)
    onCapture(data)
    setError("")
    stopCamera()
  }, [onCapture, stopCamera])

  const tryCamera = useCallback(async () => {
    if (!navigator.mediaDevices?.getUserMedia) {
      fallbackInputRef.current?.click()
      return
    }
    try {
      setError("")
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "user", width: 512, height: 512 },
      })
      streamRef.current = stream
      if (videoRef.current) {
        videoRef.current.srcObject = stream
      }
      setOverlay(true)
    } catch {
      fallbackInputRef.current?.click()
    }
  }, [])

  const onFileSelected = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = () => {
      const result = reader.result
      if (typeof result === "string") {
        onCapture(result)
        setError("")
      }
    }
    reader.onerror = () => {
      setError("تعذر قراءة الصورة. يرجى المحاولة بصورة أخرى.")
    }
    reader.readAsDataURL(file)
    event.target.value = ""
  }, [onCapture])

  return (
    <div className="flex flex-col items-center gap-2">
      {preview ? (
        <div className="relative w-24 h-24 rounded-full overflow-hidden border-2 border-primary">
          <img src={preview} alt="Preview" className="w-full h-full object-cover" />
        </div>
      ) : (
        <div className="w-24 h-24 rounded-full bg-surface-container-high flex items-center justify-center border-2 border-dashed border-border">
          <Camera className="w-8 h-8 text-muted-foreground" />
        </div>
      )}
      <div className="flex gap-2">
        <Button type="button" variant="outline" size="sm" onClick={tryCamera}>
          <Camera className="w-4 h-4 ml-1" />
          {buttonText}
        </Button>
        <Button type="button" variant="secondary" size="sm" onClick={() => galleryInputRef.current?.click()}>
          <ImagePlus className="w-4 h-4 ml-1" />
          اختيار من الجهاز
        </Button>
      </div>

      <input
        ref={fallbackInputRef}
        type="file"
        accept="image/*"
        capture="user"
        className="hidden"
        onChange={onFileSelected}
      />
      <input
        ref={galleryInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={onFileSelected}
      />

      {error && <p className="text-xs text-error text-center">{error}</p>}

      {overlay && (
        <div className="fixed inset-0 z-50 bg-black/90 flex flex-col items-center justify-center p-4">
          <div className="relative w-full max-w-sm">
            <video
              ref={videoRef}
              autoPlay
              playsInline
              className="w-full rounded-2xl"
              onPlaying={() => setVideoReady(true)}
            />
            <canvas ref={canvasRef} className="hidden" />
          </div>
          <div className="flex gap-4 mt-6">
            <Button onClick={captureFrame} size="lg" className="w-16 h-16 rounded-full" disabled={!videoReady}>
              <Camera className="w-6 h-6" />
            </Button>
          </div>
          <Button variant="ghost" className="mt-4 text-white" onClick={stopCamera}>
            إلغاء
          </Button>
        </div>
      )}
    </div>
  )
}
