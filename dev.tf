variable "image_id"{
    type = string
    default = "ami-0fd783e4fb7a2c6fd"
}
variable "instance_type"{
    type = string
     default = "t2.micro"
}
variable "min_size" {
    type = number
    default = 1
}
variable "max_size" {
    type = number
    default = 3
}
 