
# Azure Hub-Spoke: Terraform-Only (v3, **Full Create**)

이 버전은 **리소스 그룹, VNet, 서브넷, NSG, NSG 연결, 허브↔스포크 피어링**까지
전부 Terraform으로 **생성**합니다. (기존에 없어서 `... was not found` 에러가 날 때 사용)

> 기본 네이밍 규칙
> - RG: `rg-<name>-<product>`
> - VNet: `vnet-<name>-<product>`
> - NSG: `nsg-<name>-<product>`
> - name = `hub | prod | staging | dev`

> 기본 주소 체계 (필요하면 `locals.tf`와 `variables.tf`에서 수정)
> - hub: 10.0.0.0/20,    서브넷: Management(10.0.1.0/24), Shared(10.0.4.0/22), Gateway(10.0.15.224/27), AzureFirewall(10.0.15.0/26)
> - prod: 10.1.0.0/16,   default 10.1.1.0/24
> - staging: 10.2.0.0/16, default 10.2.1.0/24
> - dev: 10.3.0.0/16,     default 10.3.1.0/24

---

## 실행 순서

1) **Azure 로그인 & 구독 선택**
```bash
az login
az account set --subscription "<SUBSCRIPTION_ID_OR_NAME>"
```

2) **변수 파일 작성**
```bash
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 열어서 product_name 수정 (예: test, lab 등)
```

3) **적용**
```bash
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

### 결과
- RG, VNet, Subnet, NSG가 생성되고
- 허브의 Management/Shared 서브넷 ↔ nsg-hub-<product> 연동 (Gateway/AzureFirewall은 제외)
- 각 스포크(prod/staging/dev)의 default 서브넷 ↔ 해당 NSG 연동
- 허브 ↔ 스포크 **양방향 VNet 피어링** 생성

---

## 주의/트러블슈팅
- **주소 중첩/오타**로 VNet/서브넷 생성 실패 가능 → 주소 대역 재확인
- **이미 같은 이름의 리소스**가 있는 경우: 삭제하거나 `terraform import` 사용
- Azure 예약 서브넷 이름은 반드시 정확히:
  - `GatewaySubnet` (하이픈 없음)
  - `AzureFirewallSubnet` (하이픈 없음)
