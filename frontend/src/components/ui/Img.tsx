import React from "react"

interface ImgProps extends React.ImgHTMLAttributes<HTMLImageElement> {
  alt: string
}

export function Img({ alt, className, ...props }: ImgProps) {
  return (
    <img
      alt={alt}
      loading="lazy"
      className={className}
      {...props}
    />
  )
}
