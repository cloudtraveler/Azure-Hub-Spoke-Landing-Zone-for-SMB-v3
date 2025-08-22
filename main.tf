
#########################
# Resource Groups (RG)  #
#########################
resource "azurerm_resource_group" "rg" {
  for_each = local.rg_names
  name     = each.value
  location = var.location
}

#################
# Virtual Nets  #
#################
resource "azurerm_virtual_network" "vnet" {
  for_each            = local.vnet_specs
  name                = local.vnet_names[each.key]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  address_space       = [each.value.address_space]
}

############
# Subnets  #
############

# 허브 서브넷들
resource "azurerm_subnet" "hub" {
  for_each             = local.subnets_hub
  name                 = each.key
  resource_group_name  = azurerm_resource_group.rg["hub"].name
  virtual_network_name = azurerm_virtual_network.vnet["hub"].name
  address_prefixes     = each.value.address_prefixes
}

# 스포크 default 서브넷
resource "azurerm_subnet" "spokes_default" {
  for_each             = local.spoke_default_prefixes
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg[each.key].name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = each.value
}

########
# NSGs #
########

resource "azurerm_network_security_group" "nsgs" {
  for_each            = local.nsg_names
  name                = each.value
  location            = var.location
  resource_group_name = azurerm_resource_group.rg[each.key].name
}

#############################################
# Associations: Subnet <-> NSG (Hub/Spokes) #
#############################################

# 허브: GatewaySubnet / AzureFirewallSubnet 제외
resource "azurerm_subnet_network_security_group_association" "hub" {
  for_each = {
    for k, s in azurerm_subnet.hub :
    k => s if !contains(local.excluded_subnets, k)
  }
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.nsgs["hub"].id
}

# 스포크: 각 env의 default 서브넷을 해당 env NSG와 연결
resource "azurerm_subnet_network_security_group_association" "spokes_default" {
  for_each = azurerm_subnet.spokes_default
  subnet_id = each.value.id
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
}

###############################
# VNet Peerings (bi-direction) #
###############################

# 허브 -> 스포크
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                  = local.spoke_envs
  name                      = "peer-${local.vnet_names["hub"]}-to-${local.vnet_names[each.key]}"
  resource_group_name       = azurerm_resource_group.rg["hub"].name
  virtual_network_name      = azurerm_virtual_network.vnet["hub"].name
  remote_virtual_network_id = azurerm_virtual_network.vnet[each.key].id

  allow_virtual_network_access = true
}

# 스포크 -> 허브
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                  = local.spoke_envs
  name                      = "peer-${local.vnet_names[each.key]}-to-${local.vnet_names["hub"]}"
  resource_group_name       = azurerm_resource_group.rg[each.key].name
  virtual_network_name      = azurerm_virtual_network.vnet[each.key].name
  remote_virtual_network_id = azurerm_virtual_network.vnet["hub"].id

  allow_virtual_network_access = true
}
