import { useRef, useState, useCallback, type ChangeEvent } from "react"
import { Button } from "./button"
import { Camera, ImagePlus } from "lucide-react"

interface CameraCaptureProps {
  onCapture: (base64: string) => void
  buttonText?: string
  preview?: string
}

export default function CameraCapture({ onCapture, buttonText = "خذ صورة شخصية", preview }: CameraCaptureProps) {
  const cameraInputRef = useRef<HTMLInputElement>(null)
  const galleryInputRef = useRef<HTMLInputElement>(null)
  const [error, setError] = useState("")

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
        <Button type="button" variant="outline" size="sm" onClick={() => cameraInputRef.current?.click()}>
          <Camera className="w-4 h-4 ml-1" />
          {buttonText}
        </Button>
        <Button type="button" variant="secondary" size="sm" onClick={() => galleryInputRef.current?.click()}>
          <ImagePlus className="w-4 h-4 ml-1" />
          اختيار من الجهاز
        </Button>
      </div>
      <input
        ref={cameraInputRef}
        type="file"
        accept="image/*"
        capture="environment"
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
    </div>
  )
}
