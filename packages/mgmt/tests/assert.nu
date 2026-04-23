export def truthy [condition: bool, message: string] {
  if (not $condition) {
    error make {
      msg: $message
    }
  }
}

export def equal [left, right, message: string = "values are not equal"] {
  if $left != $right {
    error make {
      msg: $"($message): left=($left | to nuon), right=($right | to nuon)"
    }
  }
}
