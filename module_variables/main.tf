variable "input" {
  type = list(string)
}
variable "delimiter" {
  default = ","
}

variable "file_name" {
  default = "input"
}

resource "local_file" "input" {
  filename = "${path.module}/${var.file_name}"
  content = join(var.delimiter, var.input)
}

data "local_file" "output" {
  depends_on = [local_file.input]
  filename = "${path.module}/${var.file_name}"
}

output "output" {
  value = split(var.delimiter, data.local_file.output.content)
}
