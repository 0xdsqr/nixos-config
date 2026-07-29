$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.config.buffer_editor = "nvim"

# Create a directory and enter it.
def --env mkcd [directory: path] {
  mkdir $directory
  cd $directory
}

# Resolve only external commands, excluding aliases and built-ins.
def realwhich [application: string] {
  which --all $application
  | where type == external
  | get 0?.path
  | if $in != null { path expand }
}
