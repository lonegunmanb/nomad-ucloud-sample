variable "input" {
  type = list(string)
}
variable "delimiter" {
  default = ","
}

resource "local_file" "input" {
  filename = "${path.module}/input"
  content = join(var.delimiter, var.input)
}

data "local_file" "output" {
  depends_on = [local_file.input]
  filename = "${path.module}/input"
}

output "output" {
  value = split(var.delimiter, data.local_file.output.content)
}