def color [name: string] {
  ansi $name
}

export def info [message: string] {
  print $"(color light_gray)($message)(color reset)"
}

export def success [message: string] {
  print $"(color green_bold)($message)(color reset)"
}

export def warn [message: string] {
  print $"(color yellow_bold)($message)(color reset)"
}

export def error [message: string] {
  print $"(color red_bold)($message)(color reset)"
}

export def section [title: string] {
  print $"(color cyan_bold)($title)(color reset)"
}

export def command-line [name: string, description: string] {
  print $"  (color green_bold)($name)(color reset) (color light_gray)- ($description)(color reset)"
}
