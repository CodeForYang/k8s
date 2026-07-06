terraform {
  backend "s3" {
    bucket = "edward-tfstate-64016822435"
    key    = "prod/terraform.tfstate"    # ← 不同的路径！
    region = "ap-northeast-1"
    use_lockfile = true
  }
}