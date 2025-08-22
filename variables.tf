
variable "location" {
  type        = string
  description = "azure resources location"
  default     = "Korea Central"
}

variable "product_name" {
  type        = string
  nullable    = false
  description = "(필수) 프로젝트/애플리케이션 이름. 예: WebApp — 모든 리소스의 이름 테그로 사용됨"
}

variable "vnets" {
  description = "생성할 vnet 정보(이름 및 주소 공간) - Map of vnets to create (names and address spaces)"
  type = map(object({
    name          = string
    address_space = string
  }))
  default = {
    spoke1 = { name = "hub",     address_space = "10.0.0.0/20" }
    spoke2 = { name = "prod",    address_space = "10.1.0.0/16" }
    spoke3 = { name = "staging", address_space = "10.2.0.0/16" }
    spoke4 = { name = "dev",     address_space = "10.3.0.0/16" }
  }
}

# 여러 구독일 때 특정 구독으로 고정하고 싶으면 사용
variable "subscription_id" {
  type    = string
  default = null
}
