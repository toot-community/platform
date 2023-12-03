data "digitalocean_droplet" "db_server" {
  name = "dbs-toot-community-1"
}

module "domain" {
  source = "../../../modules/domain"

  name        = "toot.community"
  default_ttl = 3600

  records = [
    # Fastly CDN records
    { name = "@", type = "A", value = "151.101.193.91" },
    { name = "@", type = "A", value = "151.101.129.91" },
    { name = "@", type = "A", value = "151.101.65.91" },
    { name = "@", type = "A", value = "151.101.1.91" },
    { name = "@", type = "AAAA", value = "2a04:4e42:e00::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:c00::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:a00::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:800::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:600::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:400::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:200::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42::347" },
    { name = "www", type = "CNAME", value = "dualstack.n.sni.global.fastly.net." },
    { name = "static", type = "CNAME", value = "dualstack.n.sni.global.fastly.net." },
    { name = "_acme-challenge.static", type = "CNAME", value = "qa6en72u2g90xtrrm2.fastly-validations.com." },
    { name = "_acme-challenge", type = "CNAME", value = "j0zavl8txaeduucvua.fastly-validations.com." },
    { name = "_acme-challenge.www", type = "CNAME", value = "qlenbedoslxxzkgx3rf.fastly-validations.com." },

    # Google
    { name = "@", type = "TXT", value = "google-site-verification=vKFUBJLyiP68EJv81ewOeD6hdd_qcBGvpe6RsIIu6a0" },

    # toot.community Services
    { name = "streaming", type = "A", value = "188.166.132.64" },
    { name = "argocd", type = "A", value = "188.166.132.64" },
    { name = "monitoring", type = "A", value = "188.166.132.64" },
    { name = "relay", type = "A", value = "188.166.132.64" },
    { name = "tls", type = "A", value = "206.189.241.51" },
    { name = "automation", type = "A", value = "188.166.132.64" },
    { name = "fluent-bit", type = "A", value = "188.166.132.64" },
    { name = "status", type = "CNAME", value = "statuspage.betteruptime.com." },

    # toot.community VPC
    # update me when `egress-toot-community-1` is adopted into TF
    { name = "dbs-toot-community-1.private", type = "A", value = data.digitalocean_droplet.db_server.ipv4_address_private, ttl = 60 },
    { name = "egress-toot-community-1.private", type = "A", value = "10.110.0.4", ttl = 60 },

    # GitHub Pages (Blog)
    { name = "blog", type = "CNAME", value = "toot-community.github.io." },
    { name = "_github-challenge-toot-community-org", type = "TXT", value = "f3bab071b9" },

    # Amazon SES (Outgoing Email)
    {
      name  = "2l2pnxso5mjulqkrrn3pq47pirpppeus._domainkey", type = "CNAME",
      value = "2l2pnxso5mjulqkrrn3pq47pirpppeus.dkim.amazonses.com."
    },
    {
      name  = "potvnn4g6cujc4wx5f3lo5rplctlm6sh._domainkey", type = "CNAME",
      value = "potvnn4g6cujc4wx5f3lo5rplctlm6sh.dkim.amazonses.com."
    },
    {
      name  = "opoxxgcqfzd7oot6oi3mtggu5nh6nqy3._domainkey", type = "CNAME",
      value = "opoxxgcqfzd7oot6oi3mtggu5nh6nqy3.dkim.amazonses.com."
    },
    { name = "ses", type = "MX", value = "feedback-smtp.eu-west-1.amazonses.com.", priority = 10 },
    { name = "ses", type = "TXT", value = "v=spf1 include:amazonses.com ~all" },

    # Email
    { name = "@", type = "MX", value = "mx1.improvmx.com.", priority = 10 },
    { name = "@", type = "MX", value = "mx2.improvmx.com.", priority = 20 },
    { name = "@", type = "TXT", value = "v=spf1 include:spf.improvmx.com -all" },
    {
      name  = "_dmarc", type = "TXT",
      value = "v=DMARC1; p=none; pct=100; rua=mailto:re+uojmv5z8mwt@dmarc.postmarkapp.com; sp=none; aspf=r;"
    },
  ]
}
