print("Audit R packages")

library("oysteR")
audit = audit_installed_r_pkgs()

get_vulnerabilities(audit)