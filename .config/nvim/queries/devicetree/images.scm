((comment) @image.src
  (#match? @image.src "^// image: .+")
  (#gsub! @image.src "^// image: " "")
) @image
