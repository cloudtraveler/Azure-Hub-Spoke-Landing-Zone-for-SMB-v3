
locals {
  # name 키(hub/prod/staging/dev) 기준으로 조회하기 쉽게 변환
  vnet_specs = {
    for k, v in var.vnets : v.name => {
      address_space = v.address_space
    }
  }

  # 네이밍 맵
  rg_names   = { for name, spec in local.vnet_specs : name => "rg-${name}-${var.product_name}" }
  vnet_names = { for name, spec in local.vnet_specs : name => "vnet-${name}-${var.product_name}" }
  nsg_names  = { for name, spec in local.vnet_specs : name => "nsg-${name}-${var.product_name}" }

  # 허브 서브넷 정의 (예약 이름 정확히 사용)
  subnets_hub = tomap({
    "Management-Subnet"   = { address_prefixes = ["10.0.1.0/24"] }
    "Shared-Subnet"       = { address_prefixes = ["10.0.4.0/22"] }
    "GatewaySubnet"       = { address_prefixes = ["10.0.15.224/27"] }
    "AzureFirewallSubnet" = { address_prefixes = ["10.0.15.0/26"] }
  })

  # 스포크 default 서브넷 프리픽스
  spoke_default_prefixes = {
    "prod"    = ["10.1.1.0/24"]
    "staging" = ["10.2.1.0/24"]
    "dev"     = ["10.3.1.0/24"]
  }

  # 허브 NSG 연결에서 제외할 예약 서브넷
  excluded_subnets = ["GatewaySubnet", "AzureFirewallSubnet"]

  # 스포크 env 집합
  spoke_envs = toset(["prod","staging","dev"])
}
